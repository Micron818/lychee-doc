# 05 — Excel 模板填充基础能力 + 进耗存汇总表示例

> 编写日期：2026-08-05  
> 状态：**已实现（2026-08-05）**  
> 前置：02 导出框架、03 清单 Excel、04 单据 PDF 均已落地

## 1. 目标与范围

在现有导出作业管线不变的前提下，补齐 **Excel 自定义版式（模板填充）** 基础能力，并以 **进耗存汇总表（InventoryBalances）** 作为首个落地示例，打通端到端闭环。

| 纳入 | 不纳入（本期） |
|------|----------------|
| common：`ExcelTemplateWriteSupport`（Fesod `withTemplate` + fill） | 租户自定义模板上传（OSS 存版式） |
| 模板资源约定：`classpath:templates/excel/*.xlsx` | 跨多期间/多工厂的大批量模板套打 |
| wm：`WM_INVENTORY_BALANCE` Handler + 模板；**强制单一期间+工厂**；标题展示期间/工厂 | PDF / 打印预览（本表以 Excel 交付为主） |
| 前端：导出前范围校验 + `ExportButton` | 统计分析图表、交叉透视 |

与既有路径的分工（延续前期讨论结论）：

| 场景 | 写入路径 |
|------|----------|
| 清单 header+data（供应商） | `ExcelWriteSupport.writePaged` |
| 单据打印/归档（订购单） | `PdfRenderSupport` + Thymeleaf |
| **固定版式 xlsx（进耗存汇总）** | **`ExcelTemplateWriteSupport` + `.xlsx` 模板** |

作业层（创建 / 同步·异步分流 / OSS / 导出中心 / 权限）**零改动**；仅新增 Handler + 写入工具 + 前端按钮。

---

## 2. 总体流程

```
进耗存列表 [导出]  ExportButton jobType=WM_INVENTORY_BALANCE
   │  前端：校验已选「单一工厂 + 单一期间」→ 否则 message 拦截、不发请求
   │  POST /api/v1/report/export-jobs  { jobType, params, sort }
   ▼
ExportJobService（既有）
   ├─ 权限：/wm/inventory-balances:export
   ├─ Handler.count(params)  ← 后端再次强制校验期间+工厂（防绕过前端）
   ├─ ≤ sync-threshold：同步执行；否则异步
   └─ InventoryBalanceExportHandler.export(ctx, out)
          ├─ requirePeriodAndFactory(params) → 解析 periodLabel / factoryName
          ├─ DynamicSpecifications 同源查询 + fetch（period/material/unit）
          ├─ 组装 header（title 含期间/工厂、exportedAt、列头、合计）+ items
          └─ ExcelTemplateWriteSupport.fill(out, "excel/inventory-balance", …)
                 → OSS → 下载 URL（.xlsx）
```

---

## 3. 基础能力设计：`ExcelTemplateWriteSupport`

### 3.1 职责

与 `ExcelWriteSupport`（流式清单）、`PdfRenderSupport`（HTML→PDF）并列，封装 Fesod 模板填充：

```java
// com.lychee.erp.common.export.ExcelTemplateWriteSupport
public final class ExcelTemplateWriteSupport {

    /**
     * 从 classpath templates/{templateClasspath}.xlsx 加载模板，
     * 写入 header 变量 + 可选命名列表，结果写到 out。
     *
     * @param templateClasspath 相对 templates/，不含 .xlsx，如 "excel/inventory-balance"
     * @param header            标量占位符，如 title / exportedAt / periodLabel
     * @param lists             列表名 → 行集合；空则只填 header
     */
    public static void fill(
            OutputStream out,
            String templateClasspath,
            Map<String, Object> header,
            Map<String, ? extends Collection<?>> lists) { ... }
}
```

实现要点（对齐 [Fesod Fill](https://fesod.apache.org/docs/sheet/fill/)）：

1. 用 `ClassLoader.getResourceAsStream("templates/" + templateClasspath + ".xlsx")` 取模板；缺失抛业务异常（明确 i18n key）。
2. `FesodSheet.write(out).withTemplate(templateIn).build()`。
3. 有列表时：`FillConfig.builder().forceNewRow(true).build()` + `FillWrapper(listName, rows)`；再 `fill(header)`。
4. 仅 header 时：`sheet().doFill(header)` 即可。
5. **不**在 Support 内做分页查库——数据组装属 Handler；Support 只负责「模板 + model → 字节流」。

### 3.2 模板资源约定

```
lychee-erp-{domain}/src/main/resources/templates/excel/
  inventory-balance.xlsx          # 进耗存（示例）
  # 后续：其他套打表同目录
```

占位符约定（与 Fesod 一致）：

| 类型 | 模板写法 | 填充来源 |
|------|----------|----------|
| 标量 | `{title}` `{exportedAt}` `{periodLabel}` … | `header` Map |
| 列表行 | `{.materialCode}` `{.openingQuantity}` …（列表区域） | `lists.get("items")` → `FillWrapper("items", …)` |
| 多列表 | `{data1.xxx}` / `{data2.xxx}` | 多个 `FillWrapper`（本期进耗存仅一张明细表） |

模板制作规范（文档约束，实施时遵守）：

- 用 Excel 手工做好标题区、列头样式、数字格式、合计行位置；占位符只换「会变的字」。
- 明细列表区域预留一行样例行；合计若用模板固定行，放在列表下方，并配合 `forceNewRow` 保证列表插入后合计下移（验收时验证）。
- **三语**：本期模板内列头写「中性结构」或默认中文列头，**运行时用 header Map 覆盖列头文案**（`colMaterial`、`colOpeningQty`… 由 `MessageService` 按 `ctx.locale()` 解析后填入）。避免维护三套 `.xlsx`。若单元格样式依赖固定中文列头，再退化为「模板只含样式与 `{.field}`，列头全由 fill 写入」。

### 3.3 边界与行数策略

| 项 | 策略 |
|----|------|
| 内存 | 模板填充会加载整本 workbook；**不适合** 跨多期间/多工厂的大结果集 |
| **进耗存强制范围** | **系统硬限制：导出必须且仅能指定一个库存期间 + 一个工厂**（见 §4.1.1）。以此把结果集收束到「单期间 × 单工厂」，从源头规避模板 fill OOM |
| 上限 | **`lychee.export.template-max-rows`（默认 50,000）**：`DataExportHandler.usesExcelTemplate()=true` 时由作业层注入为 `ExportContext.maxRows`；清单类仍用 `max-rows`（200,000） |
| 与清单导出关系 | 超大纯数据导出仍用 `ExcelWriteSupport`；模板路径专供「汇总表 / 套打」 |

选型文档（01）补充一句结论即可（实施时改 01）：复杂 Excel 套打优先 Fesod Fill；POI 手写仅作 Fesod 无法覆盖时的兜底。

---

## 4. 示例：进耗存汇总表导出

### 4.1 需求

- 页面：`/wm/inventory-balances`（进耗存汇总表）工具栏增加「导出」。
- **强制范围**：导出前必须已选定**一个库存期间 + 一个工厂**；未满足时前后端均拒绝（见 §4.1.1）。
- 在满足范围的前提下，再叠加列表其余筛选与排序，导出全部匹配行。
- 文件为带标题区的 xlsx：**标题含期间与工厂**、导出时间、明细表、数量/金额合计。
- 列头与必要文案随用户语言（zh-CN / en-US / vi-VN）。

### 4.1.1 导出前置条件（期间 + 工厂）

| 维度 | 必填 | params 约定（与列表 `field_op` 一致） | 说明 |
|------|------|--------------------------------------|------|
| 工厂 | 是 | `factoryId`（或 `factoryId_eq`）且为**单一**值 | 多选/缺失均拒绝 |
| 期间 | 是 | 优先 `inventoryPeriodId`（单一值）；或同时具备 `inventoryPeriod.fiscalYear` + `inventoryPeriod.periodNo`（各单一值）且能解析出**唯一**库存期间 | 仅填年份或仅填期间号 → 拒绝 |

校验时机与文案：

1. **前端**（点击导出）：读 `lastQueryRef`，不满足则 `message.warning`（i18n：`pages.wm.inventoryBalance.export.requirePeriodAndFactory`），**不调用** `createExportJob`。
2. **后端**（`count` / `export` 入口）：`requirePeriodAndFactory(params)`，不满足抛 `ValidationException`（`validation.export.inventory_balance.period_and_factory.required`）；期间无法唯一解析时另抛（`validation.export.inventory_balance.period.ambiguous`）。
3. 以后端校验为准（防 API 直调绕过）；前端为体验优化。

解析成功后写入报表标题用字段（不再作为明细列重复）：

- `periodLabel`：`formatInventoryPeriodLabel` 同源语义（如 `2026-03`）
- `factoryName`：工厂 `code - name`（与列表工厂列一致）

### 4.2 版式草案（模板内容）

```
┌─────────────────────────────────────────────────────────────┐
│  {title}                                                     │
│  {periodLabel}  /  {factoryName}     导出日期：{exportedAt}   │
├──────┬────────┬────┬────┬──────┬──────┬──────┬──────┬ ... ──┤
│{colMaterial}│{colWarehouse}│... │  （列头均来自 header 占位） │
├──────┼────────┼────┼────┼──────┼──────┼──────┼──────┼ ... ──┤
│{.materialCode}│{.warehouseName}│{.batchNo}│...              │  ← items
│ ...                                                          │
├──────┴────────┴────┴────┴──────┴──────┴──────┴──────┴ ... ──┤
│ 合计                              {totalOpeningQty} ...      │
└─────────────────────────────────────────────────────────────┘
```

标题区约定：

- `{title}`：报表名（i18n，如「进耗存汇总表」）。
- **`{periodLabel}` / `{factoryName}` 固定展示在标题区**（可同一行或副标题行），体现「本表 = 该期间 × 该工厂」。
- 明细中**不再重复**期间列、工厂列（范围已在标题声明）。

明细列（与列表页对齐，略去期间/工厂/审计列）：

| 字段 | 说明 |
|------|------|
| materialCode / materialName | 物料 |
| warehouseName | 仓库 |
| batchNo | 批次 |
| baseUnitName | 单位 |
| openingQuantity / totalInQuantity / totalOutQuantity / closingQuantity | 数量 |
| openingAmount / totalInAmount / totalOutAmount / closingAmount | 金额 |

合计行：对各数量、金额列求和（Handler 在组装 items 时累加写入 header）。

### 4.3 后端：`InventoryBalanceExportHandler`（`lychee-erp-wm`）

#### 4.3.1 登记类型

```java
// ExportJobType
WM_INVENTORY_BALANCE  // 进耗存汇总表 Excel（模板填充）
```

前端 `ExportJobType` 联合类型同步追加。

#### 4.3.2 Handler 骨架

```java
@Component
@RequiredArgsConstructor
public class InventoryBalanceExportHandler implements DataExportHandler {

    private final InventoryBalanceRepository repository;
    private final SpecificationSliceQuery specificationSliceQuery;
    private final DictionaryCacheService dictionaryCacheService;
    private final MessageService messageService;
    // BasisCache / Warehouse 等：按列表页同源方式解析工厂、仓库名称

    @Override public ExportJobType type() { return ExportJobType.WM_INVENTORY_BALANCE; }
    @Override public ExportFileFormat fileFormat() { return ExportFileFormat.XLSX; }
    @Override public String requiredAuthority() { return "/wm/inventory-balances:export"; }

    @Override
    @Transactional(readOnly = true)
    public long count(ExportContext ctx) {
        requirePeriodAndFactory(ctx.params()); // 先校验范围，再 count
        return repository.count(DynamicSpecifications.build(InventoryBalance.class, ctx.params()));
    }

    @Override
    public ExportResult export(ExportContext ctx, OutputStream out) {
        // 1) requirePeriodAndFactory → Scope(periodLabel, factoryName, …)
        // 2) 同源 spec + fetch（inventoryPeriod, material, baseUnit）
        // 3) slice 收集 List<ItemRow>（maxRows 兜底）；解析仓库名；累加合计
        // 4) header：title、periodLabel、factoryName、exportedAt、col*、total*
        // 5) ExcelTemplateWriteSupport.fill(..., SheetFill(0, locale sheetName, Map.of("items", rows)))
        //    填充按 sheetNo；fill 后 POI 按 export.inventory_balance.sheetName 改页签
        // 6) ExportResult(rows.size(), suggestedFileName)
    }
}
```

要点：

- **范围校验**：`count` 与 `export` 均调用 `requirePeriodAndFactory`；作业创建阶段会走 `count`，非法条件在同步路径立即失败。
- **查询规格**与 `InventoryBalanceServiceImpl.getInventoryBalancePage` 同源：`DynamicSpecifications.build` + 相同 fetch，保证导出 = 列表在「该期间×工厂」下所见（可再叠加物料/仓库等筛选）。
- **标题**：`periodLabel`、`factoryName` 只进 header 标题区，不进明细行。
- **名称解析**：工厂名在范围解析时一次取定；仓库走 `RemoteWarehouseService` / 既有缓存，格式与列表一致。
- **金额/数量格式**：单元格数字格式由模板设定；Java 侧优先传 `BigDecimal`。
- **文件名**：建议带范围，如  
  `进耗存汇总_{periodLabel}_{factoryCode}_{yyyy-MM-dd}.xlsx`  
  （i18n 前缀 + 期间 + 工厂码 + 日期，避免仅日期重名）。

#### 4.3.3 行 DTO（fill 用）

```java
// 明细不含期间/工厂（已在标题区）
public class InventoryBalanceExportItem {
    private String materialCode;
    private String materialName;
    private String warehouseName;
    private String batchNo;
    private String baseUnitName;
    private BigDecimal openingQuantity;
    private BigDecimal totalInQuantity;
    private BigDecimal totalOutQuantity;
    private BigDecimal closingQuantity;
    private BigDecimal openingAmount;
    private BigDecimal totalInAmount;
    private BigDecimal totalOutAmount;
    private BigDecimal closingAmount;
}
```

字段名与模板 `{.xxx}` 一一对应。

#### 4.3.4 权限与 i18n

- 运行时菜单：为 `/wm/inventory-balances` 追加 `export` action，授予相应角色（与供应商相同惯例，无 Liquibase 种子）。
- 后端 messages 补充：
  - `export.inventory_balance.fileName` / `sheetName` / `title` / 各 `col*`
  - `validation.export.inventory_balance.period_and_factory.required`
  - `validation.export.inventory_balance.period.ambiguous`
  - `validation.export.template.not_found`
- 前端 messages：`pages.wm.inventoryBalance.export.requirePeriodAndFactory`（提示先选期间与工厂）。
- `EnumController` 已注册 `ExportJobType`，新增枚举值后导出中心 `valueEnum` 可用（补三语枚举文案）。

### 4.4 前端接入

`src/pages/wm/inventory-balances/index.tsx`：

1. `lastQueryRef` 记录最近一次 `toPageRequest` 的 `params`/`sort`。
2. 导出点击前校验 params 是否含单一 `factoryId` + 可唯一确定期间的条件（与 §4.1.1 对齐）；不满足则 warning 并 return。
3. `toolBarRender` 增加：

```tsx
<ExportButton
  key="export"
  jobType="WM_INVENTORY_BALANCE"
  getQuery={() => lastQueryRef.current}
  // 若 ExportButton 暂无 onBeforeExport，可在页面用包装 onClick / 或扩展可选 beforeRun
/>
```

实现方式二选一（实施时择简）：

- **A（推荐）**：页面自定义 toolbar 按钮逻辑——校验通过后再调 `useExportJob().runExport`；或给 `ExportButton` 增加可选 `beforeExport?: () => boolean`。
- **B**：仅依赖后端校验（体验较差：会创建 FAILED 作业）。本期要求前端拦截，采用 A。

4. `ExportJobType` 联合类型增加 `'WM_INVENTORY_BALANCE'`。
5. 列表搜索区：期间（年+期号或期间选择）与工厂保持可筛；**不强制**一进页就填满，仅在点导出时校验。

### 4.5 验收标准

1. 无 `export` 权限时按钮不渲染。
2. **未选工厂或未选齐期间**：前端提示，不发导出请求；API 直调同样返回校验错误。
3. **已选单一期间+工厂**：导出成功；xlsx 标题区可见期间与工厂名称；明细无期间/工厂列。
4. 同范围下再筛物料/仓库：明细与列表一致；合计正确。
5. 切换语言：标题、列头、提示文案随语言变化；标题区期间/工厂展示值正确。
6. 行数超 `max-rows`（兜底）或模板缺失：失败信息可理解。

---

## 5. 实施任务拆解（执行顺序）

### Phase A — 基础能力（common + 文档）

| # | 任务 | 产出 |
|---|------|------|
| A1 | 新增 `ExcelTemplateWriteSupport` + 单元测试（内存模板或 test resources 下最小 xlsx，断言单元格值） | common 可复用 API |
| A2 | 约定 `templates/excel/` 目录与占位符规范（本文 §3.2） | 开发约定 |
| A3 | （可选）01 选型文档补一句 Fill 结论；02 §4 增加「模板填充」旁路说明一行 | 文档对齐 |

### Phase B — 进耗存示例（wm + 模板）

| # | 任务 | 产出 |
|---|------|------|
| B1 | `ExportJobType.WM_INVENTORY_BALANCE` + 枚举三语文案 | 类型登记 |
| B2 | 制作 `templates/excel/inventory-balance.xlsx`（标题含 `{periodLabel}`/`{factoryName}` + items + 合计） | 版式资产 |
| B3 | `InventoryBalanceExportHandler`：`requirePeriodAndFactory` + 组装 + fill | 导出实现 |
| B4 | messages：`export.inventory_balance.*`、期间/工厂校验、模板缺失 | i18n |

### Phase C — 前端与权限

| # | 任务 | 产出 |
|---|------|------|
| C1 | `ExportJobType` 联合类型扩展 | 类型同步 |
| C2 | 进耗存列表：`lastQueryRef` + 导出前期间/工厂校验 + `ExportButton`（或 `beforeExport`） | 用户入口 |
| C3 | 三语提示：`pages.wm.inventoryBalance.export.requirePeriodAndFactory` | i18n |
| C4 | 运行时：菜单追加 `export` 并授权（上线检查项） | 权限可用 |

### Phase D — 验收

| # | 任务 |
|---|------|
| D1 | 按 §4.5：缺范围拦截、标题含期间/工厂、明细一致、合计、多语言 |
| D2 | 导出中心可见作业类型与下载 |
| D3 | 更新本文状态为「已实现」+ index.md 勾选 P3 |

预估工作量（供排期）：A ≈ 0.5–1d，B ≈ 1–1.5d（含调模板），C ≈ 0.5d，D ≈ 0.5d。

---

## 6. 代码布局（落地后）

```
lychee-erp-common
└─ com.lychee.erp.common.export
   ├─ ExcelWriteSupport.java              // 既有：清单流式
   ├─ ExcelTemplateWriteSupport.java      // 新增：模板填充
   └─ PdfRenderSupport.java               // 既有：PDF

lychee-erp-wm
└─ com.lychee.erp.wm.export
   ├─ InventoryBalanceExportHandler.java
   └─ dto/InventoryBalanceExportItem.java   // 若抽出
└─ resources/templates/excel/
   └─ inventory-balance.xlsx

lychee-frontend
├─ src/services/report/export-job/model.ts  // ExportJobType 扩展
└─ src/pages/wm/inventory-balances/index.tsx
```

依赖方向不变：`report → common ← wm`。

---

## 7. 风险与对策

| 风险 | 对策 |
|------|------|
| 模板 fill + 大结果集 OOM | **系统强制单一「期间 + 工厂」**（前后端双校验）收束数据量；`max-rows` 仅作兜底；模板路径仍不适用于跨范围大清单 |
| 用户未选范围仍点导出 | 前端 warning 拦截；后端 `ValidationException`，不生成空/错误范围文件 |
| 期间条件不完整（仅年或仅期号） | 视为未满足前置条件，与「未选期间」同一类错误 |
| `forceNewRow` 与合计行错位 | 按 Fesod 复杂填充示例做模板；验收必测「有/无明细、1 行、多行」 |
| 列头三语与模板样式冲突 | 列头用 header 占位符覆盖，不维护三套 xlsx |
| 标题期间/工厂与数据不一致 | 标题字段来自已校验并通过解析的 Scope，查询 params 使用同一期间 id / 工厂 id |
| 仓库名称与列表不一致 | 复用列表同源缓存/远程 fill，禁止 Handler 自拼另一套格式 |
| 与清单 `ExcelWriteSupport` 误用混淆 | Support 命名与 JavaDoc 明确；进耗存 Handler 注释写明「模板路径，勿改 writePaged」 |

---

## 8. 后续演进（本期不做）

- ~~`lychee.export.template-max-rows` 独立配置。~~ ✅ 已实现（默认 50,000；Handler 声明 `usesExcelTemplate()`）。
- 租户级模板：OSS 存储 + 配置表选择 template key，`ExcelTemplateWriteSupport` 增加 `InputStream` 重载即可。
- 其他套打表（对账单等）只加模板 + Handler。**盘点表已改走单据 PDF**（见 [14](./14-示例-库存盘点报表.md)），不再用 Excel 模板。
- 若业务要求进耗存同时提供「纯数据清单」与「正式汇总表」：可登记两个 `ExportJobType`，或前端下拉选格式（仍共用作业管线）。

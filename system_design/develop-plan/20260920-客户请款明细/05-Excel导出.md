# 05. Excel 导出

> 编写日期：2026-10-25  
> 状态：**已实现**（2026-10-25）  
> 前置：本目录 PDF 已实现（[04-实施清单.md](./04-实施清单.md)）；模板填充能力已落地（[Excel 模板填充](../20260818-report/05-Excel模板填充与进耗存汇总导出.md)）

PDF 继续作为打印件。本文件只增加同一查询口径的 Excel 下载。查询、净出货、`LineTaxCalculator`、混公司 / 混币别、5000 行上限、部分出货不进表，都沿用 [04-实施清单.md](./04-实施清单.md)，不另开口径。

## 1. 需求

出货单列表在现有「请款明细」PDF 旁边增加「转出 Excel」。筛选与勾选规则与 PDF 相同：单一客户 + `actualDeliveryDate` 闭区间，或勾选覆盖筛选。

Excel 与 PDF 的差异只有两处：

1. **栏位拆开**。PDF 明细把多个业务值放进同一格（换行或 `/`）。Excel 每个业务值一列。
2. **尺码分行**。PDF 用动态列横排尺码（S / M / …）。Excel 一个尺码一行，不再做尺码阵列。

合计数量、未税、税额、含税必须与同一条件下的 PDF 一致。客户拿 Excel 筛选、透视、入应付；打印仍走 PDF。

| 纳入 | 不纳入 |
|------|--------|
| 与 PDF 同一 `params` 的 xlsx 下载 | 改 PDF 模板、rowspan、尺码横排 |
| 标题区（公司 / 客户 / 账期 / 银行）+ 扁平行 + 合计 + 金额大写 + 签核 | 公司 logo、样图、料号列（有型号时） |
| 同步 `POST` 直出文件，权限 `/sd/deliveries:read` | `ExportJobType`、导出中心、OSS |
| 列头随请求 locale | 邮件、账龄、对账单、部分出货 |

## 2. PDF 组合栏位

模板 `delivery-billing-statement-pdf.html` 的明细表现状：

| PDF 格 | 格内内容 | Excel |
|--------|----------|-------|
| 出货日 / 单号 / 开票 | 出货日、出货单号、开票状态、出货单备注 | 四列 |
| 型号 | `ProductModelLabels.displayLabel`：`款号-色号` 换行再加名称；无型号时为 `物料代码 + 物料名称` | 款号、色号、名称三列。无型号时款号 = 物料代码、名称 = 物料名称、色号空 |
| 客户 PO / 销售订单 | 客户 PO、销售订单号 | 两列 |
| 颜色 | 颜色名称 | 一列，保持 |
| 内部参号 | 内部参号 | 一列，保持 |
| 客户订单号 | 客户订单号，下方行备注 | 两列 |
| S / M / … | 该矩阵行各尺码净出货，横排 | 取消动态列。尺码名称单独一列，一行一个尺码 |
| 数量 | `{行数量} {单位}`，行数量是该矩阵行全部尺码之和 | 数量、单位两列。数量是**本尺码**净出货 |
| 单价 / 未税 / 税率 / 税额 / 含税 | 该矩阵行全部尺码的合计金额 | 各列保留，金额是**本尺码**的金额 |

表头里用空格或 `/` 接在一起的值也拆开，放在标题区各自的单元格：客户代码与客户名称、出货日起与出货日止、付款条件与到期日、开户行与账号与户名。标签仍写在值旁边，不把「客户：」再拆成数据列。

PDF 为省宽度做的处理，Excel 全部不做：`rowspan`、单元格合并、超长省略号、尺码过多时缩字号、数量后面贴单位。

## 3. 实现方式评估

### 3.1 行从哪来

事实行（`Fact`）已经是一条纳入的交货行：一个物料、一个尺码、一份 `LineTaxCalculator(净量, 单价, 税率)`。PDF 再按分组键收成矩阵行，尺码收进 `sizeQuantities`，金额是组内事实行相加。

| 方案 | 做法 | 结论 |
|------|------|------|
| 拆矩阵行 | 读现有 `MatrixRow.sizeQuantities`，每个尺码复制一行，未税 / 税额 / 含税照抄矩阵行 | 不采用。同一笔金额会出现在每个尺码上，Excel 求和大于 PDF |
| 按尺码数量重算 | 对尺码数量再调一次 `LineTaxCalculator` | 不采用。计算器按行四舍五入到 2 位。两个尺码各 `1 × 1.005` 的未税是 `1.01 + 1.01 = 2.02`；对合计数量重算 `LineTaxCalculator(2, 1.005) = 2.01`。PDF 合计认事实行之和 |
| 一条交货行一行 | 不按尺码再聚合，直接导出 `Fact` | 不采用。PDF 已把同组同尺码合成一格。Excel 要的是把这个格转成行，不是把交货行再拆开 |
| **分组键 + 尺码** | 在 PDF 分组键上再加 `productSizeId`。数量与金额 = 桶内事实行相加，不重算 | **采用**。一行对应 PDF 矩阵里的一个尺码格。各尺码金额之和 = 该矩阵行金额 = 全部事实行金额之和 |

`productSizeId == null`（无尺码辅料）单独一桶，尺码单元格留空。有型号时分组键仍不含 `materialId`，与 PDF 相同，避免一色一尺码被拆散。

### 3.2 文件怎么写

尺码不再是动态列，列集合固定。请款明细仍要标题、合计、金额大写和签核，适合 [Excel 模板填充](../20260818-report/05-Excel模板填充与进耗存汇总导出.md) 的 `ExcelTemplateWriteSupport`。

| 写法 | 适用 | 对本表 |
|------|------|--------|
| `ExcelWriteSupport` 清单流式 | 纯表头 + 数据，列可多、行可大 | 标题区、金额大写、签核要另起一套手写版式。本表事实行上限 5000，用不到流式 |
| **`ExcelTemplateWriteSupport`** | 固定版式 xlsx | **采用**。classpath 模板 + 标量标题 + `items` 列表。`forceNewRow` 把合计和签核顶到明细下面 |
| 由 PDF HTML 转 xlsx | — | 不采用。HTML 的合并格和横排尺码正是要去掉的形状 |
| 导出作业 `DataExportHandler` | 列表级大文件、导出中心留档 | 不采用。见 §3.3 |

数字和日期写入原始值（`BigDecimal`、`LocalDate`），格式做在模板单元格上。沿用 PDF Renderer 那种已格式化字符串会把金额变成文本，Excel 无法求和。

### 3.3 下载路径

事实行硬上限 5000，低于导出框架同步阈值。本表又不是出货单列表的全量清单导出。

采用与 PDF 并列的同步接口：`POST /api/v1/sd/deliveries/billing-statement/excel`，`Content-Disposition: attachment`，权限 `/sd/deliveries:read`。不建 `export_jobs`、不上传 OSS、不加 `export` 动作权限。PDF 仍是 `inline` 预览，两端互不替换。

## 4. 锁定决策

| # | 决策点 | 结论 |
|---|--------|------|
| 1 | 查询 | 与 PDF 同一个组装入口。客户、出货日、勾选 `id_in`、状态、交货类型、行来源、净出货、混公司、混币别、5000 行、无明细，校验 key 不新增 |
| 2 | 行粒度 | `GroupKey + productSizeId`。同桶多条事实行：数量相加，未税 / 税额 / 含税相加 |
| 3 | 金额 | 使用事实行上已经算好的金额。禁止对桶内合计数量再调 `LineTaxCalculator` |
| 4 | 明细重复 | 出货、型号、订单等父级字段在每个尺码行重复写出。明细区不合并单元格 |
| 5 | 行备注 | 只拼接**本尺码桶**内的备注（去空白、去重，沿用现有 `appendDistinctRemark`）。PDF 是整条矩阵行的备注拼在客户订单号下；Excel 按尺码分开 |
| 6 | 出货单备注 | 交货单头备注，本单每一行重复，单独一列。不加「备注:」前缀 |
| 7 | 排序 | 先按 PDF 矩阵行序，再按该结果的尺码列序（`SizeColumnOrder`，与 PDF 从左到右一致）。无尺码行排在该组有尺码行之后 |
| 8 | 型号身份 | 有型号：款号、色号（本款色字母）、名称。无型号：款号 = 物料代码，名称 = 物料名称，色号与颜色、尺码为空。不另加料号列 |
| 9 | 尺码显示 | 一列。有名称用名称，否则用代码。与 PDF 尺码列表头相同 |
| 10 | 数量 | 本尺码净出货，数值。不写矩阵行的跨尺码合计，也不在数量后拼接单位 |
| 11 | 税率 | 写入交货行上的百分数（`10` 表示 10%）。`LineTaxCalculator` 按 `税额 = 未税 × 税率 / 100`。单元格用数字格式，不写成带 `%` 的文本 |
| 12 | 单价 / 金额 | 单价保留交货行原值，模板最多 4 位小数（对齐 `MoneyFormatSupport.unitPriceFormat`）。未税、税额、含税为事实行 2 位金额之和 |
| 13 | 合计 | 标题区下方的合计数量 / 未税 / 税额 / 含税 = 全部事实行之和，与 PDF 的 `totalQuantity` / `subtotalAmount` / `taxAmount` / `totalAmount` 相同。用填充值，不用随行数伸缩的 `SUM` 公式。单价列、税率列不做合计 |
| 14 | 标题区 | 公司名称、地址、电话、税号；客户代码、客户名称、账单地址；币别、出货单张数；出货日起、出货日止；付款条件、到期日；开户行、账号、户名；打印时间。可空则留空。不放 logo |
| 15 | 签核 | 表尾三栏：制表（当前用户姓名）、审核（空）、客户确认（空）。金额大写一行，规则同 PDF |
| 16 | 版式文件 | 单 Sheet。模板 `lychee-erp-sd/.../templates/excel/delivery-billing-statement.xlsx` |
| 17 | 文件名 | `{print.customer_billing_statement.fileName}_{客户代码}_{from}_{to}.xlsx`。客户代码的文件名清洗与 PDF 相同 |
| 18 | 权限与交付 | `/sd/deliveries:read`。同步附件下载。无导出作业 |
| 19 | PDF | 模板、预览 Modal、`POST .../billing-statement/pdf` 保持不动 |

## 5. 行粒度与金额

PDF 分组键（已实现）：

```text
deliveryId + salesOrderId + customerPoNo + customerInternalRefNo
+ customerOrderNo + productModelId + colorId + fallbackMaterialId
+ unitId + unitPriceKey + taxRateKey + invoiceStatus
```

Excel 桶键 = 上面这一组 + `productSizeId`。

```text
桶内 quantity     = Σ netQty
桶内 subtotal     = Σ fact.subtotalAmount
桶内 tax          = Σ fact.taxAmount
桶内 total        = Σ fact.totalAmount
```

同组三个尺码时，Excel 三行，三行金额之和等于 PDF 那一行。无尺码的事实行自成一行，尺码为空，数量和金额仍计入合计。

开票状态沿用分组键：同一出货单、同一款色、状态不同，继续分成不同的行，状态列各写各的译文（`enum.SourceDocInvoiceStatus.*`），与 PDF 复合格里的标签相同。

## 6. 版式

单 Sheet。列头由 `MessageService` 按请求 locale 填入 `{col...}`，模板只留样式和占位符，不维护三份 xlsx。

```text
{docTitle}
公司    {companyName}    {companyAddress}    {companyPhone}    {companyTaxId}
客户代码 {customerCode}  客户名称 {customerName}  账单地址 {customerBillingAddress}
币别 {currencyCode}  出货单数 {deliveryCount}
出货日起 {deliveryDateFrom}  出货日止 {deliveryDateTo}
付款条件 {paymentTermName}  到期日 {dueDate}
开户行 {bankName}  账号 {bankAccountNo}  户名 {bankAccountName}
打印时间 {printedAt}

出货日 | 出货单号 | 开票状态 | 出货单备注 | 款号 | 色号 | 名称 | 客户PO | 销售订单
| 颜色 | 内部参号 | 客户订单号 | 行备注 | 尺码 | 数量 | 单位 | 单价 | 未税 | 税率 | 税额 | 含税
{.actualDeliveryDate} | {.deliveryNo} | ... | {.sizeName} | {.quantity} | {.unitName} | ...

合计数量 {totalQuantity}   未税 {subtotalAmount}   税额 {taxAmount}   含税 {totalAmount}
金额大写 {totalAmountInWords}
制表 {preparedByName}    审核          客户确认
```

明细列顺序即上表，从出货日到含税，共 21 列。模板预置：

| 列 | 单元格格式 |
|----|------------|
| 出货日、出货日起、出货日止、到期日 | `yyyy-mm-dd` |
| 打印时间 | `yyyy-mm-dd hh:mm` |
| 数量 | `#,##0.######` |
| 单价 | 最多 4 位小数；零小数币别 0 位 |
| 未税、税额、含税、合计 | 2 位小数 |
| 税率 | `0.####`（值为 10 这种百分数） |

明细列头冻结。填充使用 `forceNewRow(true)`，合计、金额大写、签核留在列表样例行之下。列头文案占位符放在 header Map，例如 `colDeliveryDate`、`colSize`。

新增 i18n（`messages` / `messages_zh_CN` / `messages_vi`，插在现有 `print.customer_billing_statement.*` 段内，三语顺序一致）：

| key | zh-CN |
|-----|-------|
| `print.customer_billing_statement.deliveryNo` | 出货单号 |
| `print.customer_billing_statement.invoiceStatus` | 开票状态 |
| `print.customer_billing_statement.deliveryRemarks` | 出货单备注 |
| `print.customer_billing_statement.modelCode` | 款号 |
| `print.customer_billing_statement.colorSku` | 色号 |
| `print.customer_billing_statement.modelName` | 名称 |
| `print.customer_billing_statement.customerPoNo` | 客户PO |
| `print.customer_billing_statement.salesOrderNo` | 销售订单 |
| `print.customer_billing_statement.itemRemarks` | 行备注 |
| `print.customer_billing_statement.size` | 尺码 |
| `print.customer_billing_statement.unit` | 单位 |
| `print.customer_billing_statement.deliveryDateFrom` | 出货日起 |
| `print.customer_billing_statement.deliveryDateTo` | 出货日止 |
| `print.customer_billing_statement.customerCode` | 客户代码 |
| `print.customer_billing_statement.customerName` | 客户名称 |
| `print.customer_billing_statement.bankName` | 开户行 |
| `print.customer_billing_statement.bankAccountNo` | 账号 |
| `print.customer_billing_statement.bankAccountName` | 户名 |

已有原子文案继续复用：`docTitle`、`fileName`、`color`、`customerInternalRefNo`、`customerOrderNo`、`quantity`、`unitPrice`、`subtotal`、`taxRate`、`taxAmount`、`totalAmount`、`totalQuantity`、`amountInWords`、`paymentTerm`、`dueDate`、`currency`、`deliveryCount`、`billingAddress`、`phone`、`taxId`、`preparedBy`、`reviewedBy`、`customerConfirm`、`printedAt`。`deliveryDateRange`（出货日）用作明细「出货日」列头。

前端按钮文案新增 `pages.sd.deliveries.billingStatement.exportExcel`：zh-CN「转出 Excel」，en-US「Export Excel」，vi-VN「Xuất Excel」。启用条件的提示复用现有 `billingStatement.*`，不另写一套。

## 7. 流程与接口

```text
出货单列表 [转出 Excel]
   │  与「请款明细」相同的勾选 / 筛选校验
   │  通过后 POST 同一份 params（勾选为 id_in，否则为搜索条件）
   ▼
POST /api/v1/sd/deliveries/billing-statement/excel
   权限 /sd/deliveries:read
   Accept 响应：application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
   Content-Disposition: attachment; filename="<UTF-8 文件名>"
   ▼
DeliveryBillingStatementExcelRenderer
   ├─ DeliveryBillingStatementService.getExcelData(params)
   │     └─ 与 getReportData 共用装载；校验失败抛原有 ValidationException
   └─ ExcelTemplateWriteSupport.fill(..., "excel/delivery-billing-statement", header, items)
   ▼
前端保存文件。不打开预览 Modal
```

校验失败时响应仍是 JSON `ApiResponse`。前端按 blob 请求解析 JSON 错误（对齐 `requestPdfBlob` 的 `skipErrorHandler`），把 `message` 提示出来。不能复用 `requestPdfBlob`（它会断言 PDF）。`downloadApiFile` 只支持 GET，且按 URL 去重，不携带本次 body，也不使用。

`endpoints.ts` 增加 `deliveries.billingStatementExcel`。

## 8. 组装

`getReportData` 今天在一次方法里完成：校验 → `Fact` → 矩阵分组 → rowspan → 尺码列 → 抬头。Excel 不需要 rowspan 和尺码列。

把「校验 + 事实行 + 主数据解析 + 抬头」收成两侧共用的装载。对外仍是两个方法：

| 方法 | 消费者 | 行 |
|------|--------|----|
| `getReportData` | 现有 `DeliveryBillingStatementPdfRenderer` | `MatrixRow` + `sizeColumns` + rowspan。行为不变 |
| `getExcelData` | 新的 `DeliveryBillingStatementExcelRenderer` | 扁平行。无 `sizeColumns`、无 rowspan、无 logo |

扁平行字段与 §6 列一一对应，外加抬头字段（公司、客户、区间、币别、账期、银行、合计、金额大写、制表人、打印时间）。DTO 放在 `lychee-erp-sd` 的 response 包，不暴露 `tenantId`。

`Fact` 继续作为服务内部记录。Excel 渲染器只消费已经聚合好的行，不自己拆 `sizeQuantities`。

## 9. 实施清单

### 后端 `lychee-erp-sd`

- [x] 抽出 PDF / Excel 共用装载；`getReportData` 对外结果不变
- [x] `getExcelData`：按 §5 聚合成扁平行并排序
- [x] `DeliveryBillingStatementExcelRenderer` + `templates/excel/delivery-billing-statement.xlsx`
- [x] `DeliveryController`：`POST /billing-statement/excel`，`attachment`
- [x] `messages` / `messages_zh_CN` / `messages_vi` 补 §6 的 key

### 前端 `lychee-frontend`

- [x] `endpoints.ts`、`postDeliveryBillingStatementExcelBlob`（blob + 错误 JSON）
- [x] 出货单列表工具栏，PDF 按钮旁增加「转出 Excel」；禁用规则与 PDF 按钮相同
- [x] `pages.sd.deliveries.billingStatement.exportExcel` 三语

### 明确不改

- [ ] PDF 模板、`DeliveryBillingStatementPdfRenderer`、预览 Modal
- [ ] Liquibase、菜单、`export` 权限、`ExportJobType`
- [ ] 交货 / 开票 / 库存数据

## 10. 测试

服务测试与现有 `DeliveryBillingStatementServiceImplTest` 共用装载后，PDF 用例必须保持通过。Excel 另补：

- 缺客户、缺日期、混币别、混公司、无明细、超过 5000：与 PDF 相同的校验 key
- 同组 S / M 两尺码 → 两行；两行数量之和、未税之和等于该矩阵行；表尾合计等于 PDF 合计
- 同组同尺码两条交货行：Excel 仍是一行；未税 = 两笔事实行未税相加，等于 `1.01 + 1.01`，而不是 `LineTaxCalculator(合计数量, 单价, 税率)` 的 `2.01`
- 无尺码行：尺码空，数量和金额进合计
- 无型号：款号、名称为物料代码和名称；色号、颜色、尺码为空
- 同单不同 `invoiceStatus`：分成多行，状态列各写译文
- 行备注按尺码桶拼接；出货单备注在该单每一行重复
- 勾选 `id_in` 覆盖筛选
- 渲染冒烟：标题区字段分列、明细 21 列、金额单元格为数值、文件名以 `.xlsx` 结尾

## 11. 与 PDF 波次的关系

[02-目标流程.md](./02-目标流程.md) 锁定的「只做 PDF、不建导出作业」仍然约束**打印件和归档**。本波在这条约束下加同步 Excel，不把请款明细改成导出中心作业，也不改矩阵 PDF。

# 系统报表与资料导入导出功能 — 规划文档

> 编写日期：2026-07-31（P3：2026-08-05；导入框架设计：2026-08-07；生产日报表：2026-08-14；收货单打印：2026-08-18）
> 状态：**导出 P0–P3 已实现**；**导入 I0/I1 已实现**（框架 + 物料标准成本导入，2026-08-07）；**生产日报表已实现**（见 [11](./11-示例-生产日报表.md)）；**收货单打印已实现**（见 [12](./12-示例-收货单打印表单.md)）

## 文档索引

| 文档 | 内容 |
|------|------|
| [01-技术选型评估.md](./01-技术选型评估.md) | 需求分类、Excel / PDF / 打印 / 交付方式的方案对比与结论 |
| [02-导出框架总体设计.md](./02-导出框架总体设计.md) | 异步导出框架：模块划分、作业表、SPI、API、前端组件、OSS 交付 |
| [03-示例-供应商Excel导出.md](./03-示例-供应商Excel导出.md) | 第一个落地示例：供应商清单导出 Excel 的端到端实现方案 |
| [04-示例-订购单打印表单.md](./04-示例-订购单打印表单.md) | 第二个落地示例：订购单服务端 PDF + 原页 Modal iframe 预览 |
| [05-Excel模板填充与进耗存汇总导出.md](./05-Excel模板填充与进耗存汇总导出.md) | **P3 执行计划**：Fesod 模板填充基础能力 + 进耗存汇总表示例 |
| [06-导入框架总体设计.md](./06-导入框架总体设计.md) | **导入框架**：作业表、SPI、`ExcelReadSupport`、错误报告、前端 `ExcelImportButton` |
| [07-示例-物料标准成本导入.md](./07-示例-物料标准成本导入.md) | **I1 首例**：物料标准成本（MaterialCost）Excel 导入端到端方案 |
| [08-示例-工厂订单报表.md](./08-示例-工厂订单报表.md) | **已实现**：工厂订单报表（尺码矩阵、型号/PO/颜色合并、仅数量合计、样图、A4 横向 PDF） |
| [09-示例-销售订单报表.md](./09-示例-销售订单报表.md) | **已实现**：销售订单报表（筛选条件驱动跨单矩阵、币别/单价/金额、仅预览打印、A4 横向 PDF） |
| [10-示例-工单进度报表.md](./10-示例-工单进度报表.md) | **清单与模板修订已实现**：清单扁平行含组件领料；模板 1 工单 1 行 + 备料汇总 + 第二 Sheet 明细；二者均强制单厂 + 计划日期闭区间 |
| [11-示例-生产日报表.md](./11-示例-生产日报表.md) | **已实现**：报工单（MOR）列表模板 Excel；强制单厂 + 单日 + 状态；标题与明细标识状态；单 Sheet、无倒扣料 |
| [12-示例-收货单打印表单.md](./12-示例-收货单打印表单.md) | **已实现**：收货单服务端 PDF + 原页 Modal iframe 预览（仅打印、无归档） |

## 核心决策摘要

| 决策点 | 结论 | 理由 |
|--------|------|------|
| Excel 生成库 | **Apache Fesod**（`org.apache.fesod:fesod-sheet:2.0.2-incubating`） | EasyExcel → FastExcel 的官方后继，Apache 2.0 许可，注解驱动 + 流式写入低内存，社区活跃（已入 Apache 孵化器） |
| 导出执行模型 | **统一导出作业框架**（小数据量同步快速返回 + 大数据量异步作业） | 复用 MRP 已验证的 `@Async` + `@TransactionalEventListener` + 手动租户/安全上下文传递范式；一套框架服务所有后续报表 |
| 文件交付方式 | **上传 OSS + CDN 签名 URL 下载** | 复用现有 `StorageService`；避免长 HTTP 流式响应；天然支持多实例部署与下载中心重复下载 |
| 订购单打印 / 归档 | **服务端 PDF 单一来源**（Thymeleaf + openhtmltopdf）；原页 Modal + iframe 预览，下载走导出作业 | 打印件与归档件像素级一致；版式、水印、三语标签单点维护；预览成本转移到服务端渲染 |
| 单据 PDF 前端基座 | 共享 `PdfBlobViewer` / `PdfPreviewModal` + `utils/blob`；领域仅薄适配 | 禁止再开 `/print` 深链、前端 HTML 版式或 `autoPrint`；新单据复用同一壳 |
| 固定版式 Excel | **Fesod `withTemplate` + fill**（`ExcelTemplateWriteSupport`） | 与清单流式写入分流；版式在 `.xlsx` 模板维护；作业管线零改动（见 05） |
| 后端代码位置 | 新增 Gradle 模块 **`lychee-erp-report`**（作业编排）+ SPI 接口与 Excel 工具置于 `lychee-erp-common`，各领域模块实现自己的导出 Handler | 与现有按领域分模块的结构一致；report 模块不依赖任何领域模块，避免循环依赖 |
| 前端交互 | 共享 `ExportButton` 组件（`canAction(pathname, 'export')` 权限门控，权限系统已内建 `export` action）+ `useExportJob` 轮询 Hook + 「导出中心」页面 | 复用 MRP 前端的 ProTable `polling` 范式与工具栏按钮范式 |
| Excel 导入库 | **同一 Apache Fesod**（`FesodSheet.read` + `ReadListener`） | 与导出共用依赖；流式读低内存；注解 DTO + 批处理 |
| 导入执行模型 | **统一导入作业框架**（镜像导出：小文件同步 + 大文件异步） | 复用租户/安全上下文传递；OSS 存源文件与错误报告；部分成功 |
| 导入前端 | 新建 `ExcelImportButton` + `useImportJob` + 「导入中心」；**不复用**现有 `ImportButton` | 现有 `ImportButton` 专用于「从他单/资料导入行」；权限用已内建 `import` action |

## 报表需求分类（决定架构分层）

1. **清单类导出**（已实现）：列表页当前筛选条件下的全量数据导出 Excel。示例：供应商资料导出（`ExcelWriteSupport`）。
2. **单据类打印**（已实现）：单张业务单据的固定版式表单。示例：订购单 PDF（`PdfRenderSupport`）。
3. **固定版式 Excel / 模板填充**（P3）：标题区 + 明细列表 + 合计等套打 xlsx。示例：进耗存汇总表（`ExcelTemplateWriteSupport`）。
4. **统计分析类报表**（后续）：聚合查询 + 前端图表展示。框架 Handler SPI 已预留；届时前端按需引入图表库。
5. **Excel 资料导入**（设计完成，待实现）：系统模板 + 上传作业 + 行级校验落库 + 错误报告。示例：物料标准成本（见 [06](./06-导入框架总体设计.md) / [07](./07-示例-物料标准成本导入.md)）。

## 实施阶段

### P0 — 导出框架 + 供应商 Excel 导出（✅ 已实现，2026-07-31）

1. ✅ Gradle：`lychee-erp-common` 引入 `fesod-sheet`（`fesodVersion=2.0.2-incubating`）；新建 `lychee-erp-report` 模块并挂入 `lychee-erp`。
2. ✅ Liquibase：`v1/2026/0731-001-report-export-jobs.sql` 建 `export_jobs` 表。
3. ✅ 后端 common：`ExportJobType`/`ExportJobStatus` 枚举、`DataExportHandler` SPI（`ExportContext`/`ExportResult`）、`ExcelWriteSupport`（分页读取 + Fesod 流式写入）；`StorageService` 新增带 Content-Disposition 的上传重载。
4. ✅ 后端 report：`ExportJob` 实体/Repository/Mapper、`ExportJobServiceImpl`（同步快路径 ≤5000 行 + 异步事件监听，复刻 MRP 的租户/安全上下文传递）、`exportTaskExecutor` 线程池（CallerRunsPolicy 兜底）、`ExportJobController`（创建/状态/签名下载 URL/分页/批量删除）、`lychee.export.*` 配置项。
5. ✅ 后端 scm：`SupplierExportHandler`（`/scm/suppliers:export` 权限，`DynamicSpecifications` 同源筛选，字典/用户名批量解析，三语列头与枚举翻译）；`EnumController` 注册新枚举；`messages/entities/enums` 三语资源补齐。
6. ✅ 前端：`services/report/export-job`、`downloadByUrl` 工具、`useExportJob` Hook（同步直下 / 异步轮询自动下载）、共享 `ExportButton`（`export` action 门控）、供应商列表接入、「导出中心」页面（`/report/export-jobs`，含轮询与下载）、三语文案。
7. ⬜ 基础设施（上线前手动操作）：
   - OSS 为 `*/exports/` 前缀配置生命周期规则（30 天自动删除，与 `lychee.export.retention-days` 对齐）。
   - 后台菜单/权限为运行时数据（本专案惯例，无 Liquibase 种子）：在系统管理中新增菜单 `/report/export-jobs`（locale `menu.report.exportJobs`，父级 `menu.report`）并配置 `read`/`delete` 权限；为 `/scm/suppliers` 菜单追加 `export` 动作权限，再授予相应角色。

### P1 — 订购单打印表单（✅ 已实现，2026-07-31；版式已收敛，见下）

1. ✅ 后端数据组装：`PurchaseOrderPrintService` 一次性聚合公司抬头、供应商、字典、明细等（内部复用，不再对外暴露 `print-data` REST）。
2. ✅ 入口：列表操作列「打印」与详情抽屉「打印」按钮（原页 Modal 预览）。

### P2 — 订购单服务端 PDF（✅ 已实现，2026-07-31）

1. ✅ 依赖：`io.github.openhtmltopdf:openhtmltopdf-pdfbox:1.1.40` + `org.thymeleaf:thymeleaf-spring6`（置于 `lychee-erp-common`）。
2. ✅ 框架扩展：`ExportFileFormat` + `DataExportHandler.fileFormat()`；`PdfRenderSupport` + 内嵌 Noto 字体。
3. ✅ scm：`SCM_PURCHASE_ORDER_PDF` Handler + Thymeleaf 模板；「下载 PDF」走导出作业留历史。
4. ⬜ 上线前：为 `/scm/purchase-orders` 追加 `export` 动作权限。

### 版式收敛 — 打印页改为服务端 PDF 预览（✅ 已实现，2026-08-03）

背景：P1 前端 `PrintablePO` 与 P2 Thymeleaf 模板双轨维护会漂移；要求打印件与归档件像素级一致。

1. ✅ 抽出 `PurchaseOrderPdfRenderer`：组模型 + 渲染共用；导出 Handler 与预览接口均委派它。
2. ✅ `GET /api/v1/scm/purchase-orders/{id}/pdf`：同步直出 `application/pdf`（`Content-Disposition: inline`），不建作业、不落 OSS；权限 `/scm/purchase-orders:read`。删除原 `print-data` REST 端点（service 保留）。
3. ✅ 打印预览：取 PDF blob → objectURL → iframe；**唯一入口为原页近全屏 Modal**（列表 / 详情抽屉），已移除 `/print` 深链路由（Modal 已近全屏，无需再二次引导独立页）。工具条「打印」/「下载 PDF」（导出作业）/关闭；**不提供 autoPrint**。
4. ✅ 版式、草稿水印、页码、三语标签仅维护模板一处；预览成本转移到服务端渲染（单张亚秒级）。

### 预览基座抽取（✅ 已实现，2026-08-03）

1. ✅ 前端共享：`components/PdfPreview`（`PdfBlobViewer` + `PdfPreviewModal`）+ `utils/blob`；订购单 `print/PurchaseOrderPdfPreviewModal.tsx` 为单文件领域适配范本。
2. ✅ 文档与实现对齐：废弃一期 `/print`、`PrintablePO`、`autoPrint`、`print-data` 现行表述；新单据按 04 §6 清单扩展。

### 安全加固 — 导出中心访问控制（✅ 已实现，2026-08-03）

背景：`GET /{id}` 与 `GET /{id}/download-url` 原仅要求登录，`@TenantId` 只隔离租户——租户内任何用户持作业 ID 即可下载他人导出的文件，且文件内容的业务权限只在创建时校验。调整（均在 `ExportJobServiceImpl` 服务层）：

1. ✅ **默认仅本人可见**：状态查询、签发下载 URL、删除、分页列表均限定 `createdBy = 当前用户`（`ROLE_ADMIN` 例外可见全租户）；越权访问以 404（而非 403）响应，避免泄露作业存在性。
2. ✅ **下载时二次鉴权**：签发下载 URL 前按 `jobType` 反查 Handler 的 `requiredAuthority()` 重验当前用户业务导出权限，覆盖「作业创建后权限被回收」场景。
3. ✅ **下载审计日志**：每次签发下载 URL 记录 jobId/jobType/fileName/userId。
4. ✅ Liquibase：`0803-001-export-jobs-owner-index.sql` 增加 `(tenant_id, created_by)` 索引。
5. 前端零改动：非管理员在导出中心自然只看到自己的作业。

另评估结论：打印页 URL 带单据 ID 风险可接受（`read` 权限 + 租户判别列拦截，与列表页可见范围一致）。

### P3 — Excel 模板填充 + 进耗存汇总导出（✅ 已实现，2026-08-05，见 [05](./05-Excel模板填充与进耗存汇总导出.md)）

1. ✅ common：`ExcelTemplateWriteSupport`（classpath 模板 + Fesod fill + 单元测试）。
2. ✅ wm：`WM_INVENTORY_BALANCE` Handler + `templates/excel/inventory-balance.xlsx`；**系统强制单一「期间 + 工厂」**；标题区展示期间/工厂。
3. ✅ 前端：`ExportButton.beforeExport` + 进耗存列表接入 + `ExportJobType` 扩展；三语提示文案。
4. ⬜ 上线前：运行时为 `/wm/inventory-balances` 追加 `export` 动作权限并授予角色。

### I0 — Excel 导入框架（✅ 已实现 2026-08-07，见 [06](./06-导入框架总体设计.md)）

1. ✅ Liquibase：`0807-001-report-import-jobs.sql` 建 `import_jobs` 表。
2. ✅ 后端 common：`ImportJobType`/`ImportJobStatus`、`DataImportHandler` SPI、`ExcelReadSupport` / `ExcelErrorReportSupport` / `ExcelImportTemplateSupport`；`StorageService.open`。
3. ✅ 后端 report：`ImportJobService`（同步阈值默认 500 行 + 异步 `importTaskExecutor`）、`ImportJobController`（模板下载 / multipart 创建 / 轮询 / 签名 URL / 分页 / 批量删除）、访问控制对齐导出中心。
4. ✅ 前端：`services/report/import-job`、`useImportJob`、`ExcelImportButton`、「导入中心」`/report/import-jobs`、三语文案。
5. ⬜ 上线前：OSS `*/imports/` 生命周期 30 天；菜单 `/report/import-jobs` 配置 `read`/`delete`。

### I1 — 物料标准成本 Excel 导入（✅ 已实现 2026-08-07，见 [07](./07-示例-物料标准成本导入.md)）

1. ✅ fi：`MaterialStandardCostImportHandler` + `MaterialStandardCostImportRow`；仅 `STANDARD_COST`；UPSERT/CREATE_ONLY；拒绝成本计算只读行。
2. ✅ mm/common：`RemoteMaterialService.findByCodes` + `MaterialRepository.findByCodeIn`。
3. ✅ 前端：物料成本列表挂 `ExcelImportButton`；模板下载 + 上传 Modal；成功后 reload。
4. ⬜ 上线前：为 `/fi/material-costs` 追加 `import` 动作权限并授予角色。

### 后续按需演进

- 批量 PDF 列表入口（订购单列表勾选多单导出）：后端 Handler 已支持 `ids` 批量，前端待解决列表复选框当前仅允许勾选 DRAFT 单（服务于批量删除/审核）的语义冲突后即可开放。
- 邮件发送供应商：PDF 已落 OSS，追加邮件通道即可。
- 过期作业清理定时任务（`@Scheduled`，与 OSS 生命周期规则双保险；导出/导入作业均可覆盖）。
- 更多清单导出：只需新增一个 Handler + 前端一个按钮，框架零改动。
- **更多模板 Excel**：复用 `ExcelTemplateWriteSupport` + 领域模板 + Handler（见 05）；大清单仍走 `ExcelWriteSupport`。
- **新单据类 PDF**：复用后端 `*PdfRenderer`/模板 + 前端 `PdfPreview*` 基座（见 04 §6）；禁止再开前端打印页双轨。
- **请购单打印（仅 Print）**：比照订购单实现 `GET /purchase-requisitions/{id}/pdf` + `PurchaseRequisitionPdfRenderer` + 原页 Modal；无 `ExportHandler` / 无「下载 PDF」（无归档需求时省略导出层）。
- **工厂订单报表（✅）**：`FactoryOrder` 接单确认 PDF（尺码矩阵 + 型号/PO/颜色 rowspan 合并 + 仅数量合计 + 样图 + A4 landscape）；设计见 [08](./08-示例-工厂订单报表.md)。
- **销售订单报表（✅）**：列表工具栏预览/打印；强制单一客户 + 订单日期区间；跨多 SO 一张尺码矩阵（含币别/单价/金额）；无归档 Export；设计见 [09](./09-示例-销售订单报表.md)。
- **工单进度报表（✅）**：`ProductionOrder` 列表多单 Excel；清单（流式扁平行）与模板**并存**。模板为 1 工单 1 行 + 齐套汇总 + 第二 Sheet 备料明细；**清单与模板均强制单一工厂 + 计划日期闭区间**；清单文件名与扁平行不改。设计见 [10](./10-示例-工单进度报表.md)。
- **生产日报表（✅）**：`ProductionReport`（MOR）列表模板 Excel；**强制单一工厂 + 单一报工日 + 单一状态**；标题区与明细均标识状态；单 Sheet、无倒扣料。设计见 [11](./11-示例-生产日报表.md)。
- **收货单打印（✅，仅 Print）**：比照订购单实现 `GET /goods-receipts/{id}/pdf` + `GoodsReceiptPdfRenderer` + 原页 Modal；含仓库 / 批次 / FOC / 来源单；**不印单价金额／币别汇率**；**报工入库不提供打印**；无归档 Export。设计见 [12](./12-示例-收货单打印表单.md)。
- **更多 Excel 导入**：复用 `DataImportHandler` + 模板 + `ExcelImportButton`（见 06）；单据类导入二期评估。
- ~~标准成本「导出为再导入模板」~~：✅ `FI_MATERIAL_COST` 清单导出（前 8 列对齐导入模板；见 07 §12）。

## 关键风险与对策

| 风险 | 对策 |
|------|------|
| 大数据量导出内存溢出 | Fesod 流式写入 + 分页读取（每批 1000 行）+ 单作业行数上限（默认 20 万行，超限报错提示细化筛选） |
| 异步线程租户上下文丢失导致数据串租户 | 严格复制 MRP 范式：事件携带 `tenantId` + `Authentication`，监听器 `finally` 中清理；Handler 内所有查询走 JPA（`@TenantId` 自动过滤） |
| 签名 URL 泄露 | 下载 URL 每次通过 API 实时签发，有效期 5 分钟；不落库、不返回长效 URL |
| 租户内越权下载导出文件 | 作业默认仅发起人本人可见（管理员例外）；下载时重验 Handler 业务导出权限；下载留审计日志 |
| 打印/归档版式漂移 | 版式收敛为 Thymeleaf 模板单一来源；原页 Modal + iframe 预览同一 PDF |
| 导入大文件/大批量写库 | Fesod 流式读 + `max-rows`/`max-file-size` + 独立 `importTaskExecutor` + 小 batchSize |
| 导入模板列头被改 / 跨语言错配 | 强制系统模板；按作业 locale 校验列头；按 index 绑定字段 |
| 与单据「导入」按钮语义混淆 | 新建 `ExcelImportButton`；保留现有 `ImportButton` 给从他单导入 |

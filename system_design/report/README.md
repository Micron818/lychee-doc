# 系统报表与资料导出功能 — 规划文档

> 编写日期：2026-07-31
> 状态：**P0、P1、P2 已实现**（P0：导出框架 + 供应商 Excel 导出；P1：订购单打印表单；P2：订购单服务端 PDF。前后端编译/类型检查均通过）

## 文档索引

| 文档 | 内容 |
|------|------|
| [01-技术选型评估.md](./01-技术选型评估.md) | 需求分类、Excel / PDF / 打印 / 交付方式的方案对比与结论 |
| [02-导出框架总体设计.md](./02-导出框架总体设计.md) | 异步导出框架：模块划分、作业表、SPI、API、前端组件、OSS 交付 |
| [03-示例-供应商Excel导出.md](./03-示例-供应商Excel导出.md) | 第一个落地示例：供应商清单导出 Excel 的端到端实现方案 |
| [04-示例-订购单打印表单.md](./04-示例-订购单打印表单.md) | 第二个落地示例：订购单可打印格式表单（浏览器打印，预留服务端 PDF） |

## 核心决策摘要

| 决策点 | 结论 | 理由 |
|--------|------|------|
| Excel 生成库 | **Apache Fesod**（`org.apache.fesod:fesod-sheet:2.0.2-incubating`） | EasyExcel → FastExcel 的官方后继，Apache 2.0 许可，注解驱动 + 流式写入低内存，社区活跃（已入 Apache 孵化器） |
| 导出执行模型 | **统一导出作业框架**（小数据量同步快速返回 + 大数据量异步作业） | 复用 MRP 已验证的 `@Async` + `@TransactionalEventListener` + 手动租户/安全上下文传递范式；一套框架服务所有后续报表 |
| 文件交付方式 | **上传 OSS + CDN 签名 URL 下载** | 复用现有 `StorageService`；避免长 HTTP 流式响应；天然支持多实例部署与下载中心重复下载 |
| 订购单打印（一期） | **前端专用打印视图 + `window.print()`** | 零后端依赖、开发最快、antd 生态内解决；ERP 单据打印的主流轻量做法 |
| 服务端 PDF（二期，可选） | **openhtmltopdf**（`io.github.openhtmltopdf:openhtmltopdf-pdfbox:1.1.40`）+ Thymeleaf 模板 + 内嵌 Noto Sans CJK 字体 | 需要归档 PDF / 邮件发送 / 批量打印时再引入；HTML+CSS 模板维护成本远低于 JasperReports |
| 后端代码位置 | 新增 Gradle 模块 **`lychee-erp-report`**（作业编排）+ SPI 接口与 Excel 工具置于 `lychee-erp-common`，各领域模块实现自己的导出 Handler | 与现有按领域分模块的结构一致；report 模块不依赖任何领域模块，避免循环依赖 |
| 前端交互 | 共享 `ExportButton` 组件（`canAction(pathname, 'export')` 权限门控，权限系统已内建 `export` action）+ `useExportJob` 轮询 Hook + 「导出中心」页面 | 复用 MRP 前端的 ProTable `polling` 范式与工具栏按钮范式 |

## 报表需求分类（决定架构分层）

1. **清单类导出**（本期）：列表页当前筛选条件下的全量数据导出 Excel。示例：供应商资料导出。
2. **单据类打印**（本期）：单张业务单据的固定版式表单。示例：订购单打印。
3. **统计分析类报表**（后续）：聚合查询 + 前端图表展示。本期不做，但导出框架的 Handler SPI 已为其预留（聚合结果同样可导出 Excel）；届时前端按需引入图表库（如 Ant Design Charts）。

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

### P1 — 订购单打印表单（✅ 已实现，2026-07-31）

1. ✅ 后端：`GET /api/v1/scm/purchase-orders/{id}/print-data`（沿用 `/scm/purchase-orders:read` 权限）。`PurchaseOrderPrintServiceImpl` 一次性聚合：公司抬头（factory → company 主数据，跨模块直接注入 basis Repository，与 WM 模块惯例一致）、供应商完整信息、币别/付款条件字典解析、状态枚举三语翻译、明细按 `itemNo` 排序且 `fetch(material, unit)` 防 N+1、打印人/打印时间；`DRAFT` 单返回 `draft: true` 供前端加水印，接口不做状态硬限制。
2. ✅ 前端：`/scm/purchase-orders/print?id={id}` 打印视图页（约定式路由，不加菜单）。`PrintablePO` 纯语义化 `<table>` 版式 + `print.less`（`@page` A4、`thead` 跨页重复、行与签核栏 `break-inside: avoid`）；挂载时给 `body` 加 class 隐藏应用框架（限定作用域，不影响其他页面打印）；草稿对角线水印；`autoPrint=1` 支持打开即弹打印对话框；金额按币别 locale 千分位格式化；document.title 设为单号便于打印存档命名。
3. ✅ 入口：列表操作列「打印」（`extraActions`）与详情抽屉底部「打印」按钮，均新标签打开；`component.button.print/close` 与 `pages.scm.purchaseOrders.print.*` 三语文案补齐。

### P2 — 订购单服务端 PDF（✅ 已实现，2026-07-31）

1. ✅ 依赖：`io.github.openhtmltopdf:openhtmltopdf-pdfbox:1.1.40`（新社区分支，包名仍为 `com.openhtmltopdf`）+ `org.thymeleaf:thymeleaf-spring6`（Spring Boot BOM 管理）。**与 04 文档的偏差**：依赖放在 `lychee-erp-common` 而非 `lychee-erp-report`——Handler 在领域模块、领域模块只依赖 common，与 P0 放置 Fesod 的理由一致。
2. ✅ 框架扩展（唯一改动点）：`ExportFileFormat` 枚举（副档名 + Content-Type）+ `DataExportHandler.fileFormat()`（默认 XLSX），`ExportJobExecutor` 按格式生成临时文件与 OSS 对象路径。
3. ✅ 渲染工具：common 新增 `PdfRenderSupport`（独立 `SpringTemplateEngine` + `ClassLoaderTemplateResolver`，`#{key}` 直连既有 i18n 资源；内嵌 Noto Sans（拉丁/越南语）与 Noto Sans SC（简中子集）Regular/Bold 共 4 个字体常驻内存约 18MB，Docker 镜像无需系统字体）。
4. ✅ scm：`ExportJobType.SCM_PURCHASE_ORDER_PDF` + `PurchaseOrderPdfExportHandler`（权限 `/scm/purchase-orders:export`；`params.ids` 支持单张与批量，批量合并为一份 PDF 每张独立分页；数据组装复用 P1 的 `PurchaseOrderPrintService`；`count()` 以明细行数估算工作量驱动同步/异步分流）+ 模板 `templates/print/purchase-order-pdf.html`（版式移植 P1 打印视图，`-fs-table-paginate` 跨页重复表头、页脚页码 `page/pages` 计数器、草稿水印）。
5. ✅ 前端：`ExportButton` 支持自定义 `label`；打印视图页工具条与详情抽屉底部新增「下载 PDF」（走导出作业框架，同步小单直接下载、大批量异步 + 导出中心可重复下载）；三语文案。
6. ⬜ 上线前手动操作：为 `/scm/purchase-orders` 菜单追加 `export` 动作权限并授予角色（同 P0 供应商导出的配置方式）。

### 后续按需演进

- 批量 PDF 列表入口（订购单列表勾选多单导出）：后端 Handler 已支持 `ids` 批量，前端待解决列表复选框当前仅允许勾选 DRAFT 单（服务于批量删除/审核）的语义冲突后即可开放。
- 邮件发送供应商：PDF 已落 OSS，追加邮件通道即可。
- 过期作业清理定时任务（`@Scheduled`，与 OSS 生命周期规则双保险）。
- 更多清单导出：只需新增一个 Handler + 前端一个按钮，框架零改动。

## 关键风险与对策

| 风险 | 对策 |
|------|------|
| 大数据量导出内存溢出 | Fesod 流式写入 + 分页读取（每批 1000 行）+ 单作业行数上限（默认 20 万行，超限报错提示细化筛选） |
| 异步线程租户上下文丢失导致数据串租户 | 严格复制 MRP 范式：事件携带 `tenantId` + `Authentication`，监听器 `finally` 中清理；Handler 内所有查询走 JPA（`@TenantId` 自动过滤） |
| 签名 URL 泄露 | 下载 URL 每次通过 API 实时签发，有效期 5 分钟；不落库、不返回长效 URL |
| 浏览器打印版式差异 | 打印视图使用表格布局 + 标准打印 CSS（`@page`、`break-inside`），验收覆盖 Chrome/Edge；如客户要求像素级一致再启动 P2 服务端 PDF |

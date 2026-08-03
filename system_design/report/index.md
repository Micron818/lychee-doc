# 系统报表与资料导出功能 — 规划文档

> 编写日期：2026-07-31
> 状态：**P0、P1、P2 已实现；订购单打印版式已收敛为服务端 PDF 单一来源**（前后端编译/类型检查均通过）

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
| 订购单打印 / 归档 | **服务端 PDF 单一来源**（Thymeleaf + openhtmltopdf）；打印页 iframe 预览，下载走导出作业 | 打印件与归档件像素级一致；版式、水印、三语标签单点维护；预览成本转移到服务端渲染 |
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

### P1 — 订购单打印表单（✅ 已实现，2026-07-31；版式已收敛，见下）

1. ✅ 后端数据组装：`PurchaseOrderPrintService` 一次性聚合公司抬头、供应商、字典、明细等（内部复用，不再对外暴露 `print-data` REST）。
2. ✅ 入口：列表操作列「打印」与详情抽屉「打印」按钮，新标签打开 `/scm/purchase-orders/print?id={id}`。

### P2 — 订购单服务端 PDF（✅ 已实现，2026-07-31）

1. ✅ 依赖：`io.github.openhtmltopdf:openhtmltopdf-pdfbox:1.1.40` + `org.thymeleaf:thymeleaf-spring6`（置于 `lychee-erp-common`）。
2. ✅ 框架扩展：`ExportFileFormat` + `DataExportHandler.fileFormat()`；`PdfRenderSupport` + 内嵌 Noto 字体。
3. ✅ scm：`SCM_PURCHASE_ORDER_PDF` Handler + Thymeleaf 模板；「下载 PDF」走导出作业留历史。
4. ⬜ 上线前：为 `/scm/purchase-orders` 追加 `export` 动作权限。

### 版式收敛 — 打印页改为服务端 PDF 预览（✅ 已实现，2026-08-03）

背景：P1 前端 `PrintablePO` 与 P2 Thymeleaf 模板双轨维护会漂移；要求打印件与归档件像素级一致。

1. ✅ 抽出 `PurchaseOrderPdfRenderer`：组模型 + 渲染共用；导出 Handler 与预览接口均委派它。
2. ✅ `GET /api/v1/scm/purchase-orders/{id}/pdf`：同步直出 `application/pdf`（`Content-Disposition: inline`），不建作业、不落 OSS；权限 `/scm/purchase-orders:read`。删除原 `print-data` REST 端点（service 保留）。
3. ✅ 打印预览：取 PDF blob → objectURL → iframe；**日常入口为原页 Modal**（列表操作列 / 详情抽屉），避免新标签二次 SPA 引导；`/print?id=` 深链路由保留（fullscreen）。工具条「打印」/`下载 PDF`（导出作业）/关闭；`autoPrint=1` 在 iframe load 后触发。
4. ✅ 版式、草稿水印、页码、三语标签仅维护模板一处；预览成本转移到服务端渲染（单张亚秒级）。

### 安全加固 — 导出中心访问控制（✅ 已实现，2026-08-03）

背景：`GET /{id}` 与 `GET /{id}/download-url` 原仅要求登录，`@TenantId` 只隔离租户——租户内任何用户持作业 ID 即可下载他人导出的文件，且文件内容的业务权限只在创建时校验。调整（均在 `ExportJobServiceImpl` 服务层）：

1. ✅ **默认仅本人可见**：状态查询、签发下载 URL、删除、分页列表均限定 `createdBy = 当前用户`（`ROLE_ADMIN` 例外可见全租户）；越权访问以 404（而非 403）响应，避免泄露作业存在性。
2. ✅ **下载时二次鉴权**：签发下载 URL 前按 `jobType` 反查 Handler 的 `requiredAuthority()` 重验当前用户业务导出权限，覆盖「作业创建后权限被回收」场景。
3. ✅ **下载审计日志**：每次签发下载 URL 记录 jobId/jobType/fileName/userId。
4. ✅ Liquibase：`0803-001-export-jobs-owner-index.sql` 增加 `(tenant_id, created_by)` 索引。
5. 前端零改动：非管理员在导出中心自然只看到自己的作业。

另评估结论：打印页 URL 带单据 ID 风险可接受（`read` 权限 + 租户判别列拦截，与列表页可见范围一致）。

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
| 租户内越权下载导出文件 | 作业默认仅发起人本人可见（管理员例外）；下载时重验 Handler 业务导出权限；下载留审计日志 |
| 打印/归档版式漂移 | 版式收敛为 Thymeleaf 模板单一来源；打印页 iframe 预览同一 PDF |

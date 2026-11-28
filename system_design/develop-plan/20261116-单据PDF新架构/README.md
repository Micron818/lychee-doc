# 单据 PDF（HTML5 + Chromium）

单据 PDF 由独立服务 `lychee-pdf` 生成。版式用 HTML5 + CSS，由 TypeScript 渲染成静态 HTML，再由 Playwright 驱动 Chromium 打成 PDF。

**不替换导出作业框架，不替换 Excel，不改前端预览壳。** 查询、租户、权限、币别校验仍在 Java。浏览器拿到的仍是服务端 PDF。

进程内的 Thymeleaf + openhtmltopdf 已删除。单据 PDF 只走这一套引擎。

独立进程的仓库是 `lychee-pdf`，compose 服务名是 `pdf`。用户侧的单据打印，以及 Java 的 `*PrintService`，仍叫打印。

```text
列表 / 详情 [预览/打印] 或导出作业
    │  权限、租户、查询、校验仍在业务模块
    ▼
Java *PdfRenderer
    └─ 视图模型 JSON → lychee-pdf
            TypeScript 渲染 HTML5
            Playwright + Chromium → PDF 字节
    ▼
预览：现有 GET|POST /pdf，inline，不建作业、不落 OSS
归档：现有 DataExportHandler，临时文件 → OSS → GET /file
前端：现有 PdfPreview*（blob → iframe → print）
```

前置：

- 选型与「服务端 PDF 单一来源」：[../20260818-report/01-技术选型评估.md](../20260818-report/01-技术选型评估.md) §3、§6。该文 §3 是迁移前的选型记录，现行渲染方式以本目录为准
- 导出作业、归档下载：[../20260818-report/02-导出框架总体设计.md](../20260818-report/02-导出框架总体设计.md)
- 作业文件同源下载：[../20260918-export-file-delivery/README.md](../20260918-export-file-delivery/README.md)
- 预览壳（iframe，引擎已换）：[../20260818-report/04-示例-订购单打印表单.md](../20260818-report/04-示例-订购单打印表单.md)

**状态：11 张存量单据与销售订单月汇总表均已切换。** `PdfRenderSupport`、classpath 字体和 `templates/print` 已删除。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | 迁移前的引擎为何不适合继续加新版式，哪些契约不动 |
| [02-目标架构.md](./02-目标架构.md) | 现行架构：进程边界、模块、版式规则、模板清单 |
| [03-契约.md](./03-契约.md) | PDF 服务 API、视图模型、配置、资源限额 |
| [04-实施清单.md](./04-实施清单.md) | P0 链路、P1 月汇总、P2 存量迁移与引擎删除 |
| [../20261116-销售订单月汇总表/设计.md](../20261116-销售订单月汇总表/设计.md) | P1 单据：销售订单月汇总表。销售明细表已在 P2 一并换引擎 |

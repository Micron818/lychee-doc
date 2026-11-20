# 单据 PDF 新架构（HTML5 + Chromium）

本目录描述 **新单据 / 新报表 PDF** 的渲染架构。版式用 HTML5 + CSS，由 TypeScript 渲染成静态 HTML，再由 Playwright 驱动 Chromium 打成 PDF。

**不替换导出作业框架，不替换 Excel，不改前端预览壳。** 查询、租户、权限、币别校验仍在 Java。浏览器拿到的仍是服务端 PDF。

存量 Thymeleaf + openhtmltopdf 模板继续打出现网单据，以后按张迁移。同一张报表只走一个引擎。

独立进程的仓库是 `lychee-pdf`，compose 服务名是 `pdf`。用户侧的单据打印，以及 Java 的 `*PrintService`，仍叫打印。

```text
列表 / 详情 [预览/打印] 或导出作业
    │  权限、租户、查询、校验仍在业务模块
    ▼
Java *PdfRenderer
    ├─ 存量：PdfRenderSupport（Thymeleaf + openhtmltopdf）
    └─ 新报表：视图模型 JSON → lychee-pdf
                    TypeScript 渲染 HTML5
                    Playwright + Chromium → PDF 字节
    ▼
预览：现有 GET|POST /pdf，inline，不建作业、不落 OSS
归档：现有 DataExportHandler，临时文件 → OSS → GET /file
前端：现有 PdfPreview*（blob → iframe → print）
```

前置：

- 选型与「服务端 PDF 单一来源」：[../20260818-report/01-技术选型评估.md](../20260818-report/01-技术选型评估.md) §3、§6
- 导出作业、归档下载：[../20260818-report/02-导出框架总体设计.md](../20260818-report/02-导出框架总体设计.md)
- 作业文件同源下载：[../20260918-export-file-delivery/README.md](../20260918-export-file-delivery/README.md)
- 现行预览基座：[../20260818-report/04-示例-订购单打印表单.md](../20260818-report/04-示例-订购单打印表单.md)

**状态：P0 代码已落地，尚未部署。** 正式机升到约 8GB、并且各机 `.env` 写上同一把 `LYCHEE_PDF_TOKEN` 之前，不要在正式机接入 PDF 容器。测试机维持约 4GB、停掉本机 Keycloak 后再接入，见 [07-测试栈共用正式Keycloak](../20261022-多租户运行栈/07-测试栈共用正式Keycloak.md)。演示机本次不接入。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | 现行引擎为何不适合继续加新版式，哪些契约不动 |
| [02-目标架构.md](./02-目标架构.md) | 进程边界、模块、版式规则、迁移顺序 |
| [03-契约.md](./03-契约.md) | PDF 服务 API、视图模型、配置、资源限额 |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：P0 链路、第一张新报表、存量迁移条件 |
| [../20261116-销售订单月汇总表/设计.md](../20261116-销售订单月汇总表/设计.md) | **P1 单据**：销售订单月汇总表。现有矩阵改称销售明细表，引擎不动 |

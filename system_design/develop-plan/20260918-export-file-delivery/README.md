# 导出/导入文件同源代理下载

本目录描述 **ERP 作业文件的交付路径纠偏**：生成结果仍落阿里云 OSS，浏览器下载改走已通畅的 ERP API，**不再经 CDN 签名 URL**。

现网故障形态：`POST /export-jobs` 与 `GET /{id}/download-url` 都成功，返回合法 `cdn.lycheetech.com` URL，但用户到 CDN 的链路 pending，页面已提示「文件已开始下载」。

**不改变作业模型。** Handler SPI、同步/异步分流、OSS 路径、30 天保留、本人可见、下载二次鉴权全部维持。  
改的是最后一跳：**谁把字节送到浏览器**。

```text
生成（不变）
  Handler → 临时文件 → StorageService.upload → OSS {tenantCode}/exports|imports/...

下载 As-Is
  GET /download-url → CDN auth_key URL → 浏览器直连 cdn.lycheetech.com（隐藏 iframe）

下载 To-Be
  GET /{id}/file → ERP（Bearer）→ StorageService.open → OSS → 流式回写 → blob 触发保存
```

图片 / logo 继续 CDN，本专题不动。  
前置框架：[`../20260818-report`](../20260818-report)（01 §5 当时把 OSS 存储与 CDN 交付绑成一个方案；本专题拆开）。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：CDN 交付、假成功、控制面/数据面分裂 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：同源代理、前端 blob、导入对称改造 |
| [03-schema设计.md](./03-schema设计.md) | 无表结构变更；文件流 API 契约与错误 |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、流式约定、提交顺序、验收 |

相关实现（改造前）：

- 签发 URL：`ExportJobServiceImpl.getDownloadUrl` / `ImportJobServiceImpl.getSourceUrl` / `getErrorReportUrl`
- CDN 签名：`AliyunStorageService.generateSignedUrl`（图片仍用）；`open` 在 `getObject` 失败时现网泄漏 client
- 前端点火：`useExportJob` / `useImportJob` / 导出中心 / 导入中心 → `downloadByUrl`（隐藏 iframe）
- 全局 `errorHandler` 弹窗后不 throw：`src/requestConfig.tsx`（PDF 已用 `requestPdfBlob` + `skipErrorHandler` 避开）
- 已有同源字节流先例：导入空模板 `GET /import-jobs/templates/{jobType}`、单据 `GET /{id}/pdf`

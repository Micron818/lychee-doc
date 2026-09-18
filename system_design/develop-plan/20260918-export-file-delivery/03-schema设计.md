# 03. 契约：无表变更，文件流 API

> 本专题 **不改表、不改枚举、不加 Liquibase**。  
> `export_jobs` / `import_jobs` 的 `file_path`、`file_name`、`file_size`、`expires_at` 现网已够用。这里只写下载 HTTP 形状。

---

## 1. 仍使用的现网结构

| 对象 | 用途 |
|------|------|
| `export_jobs.file_path` / `file_name` / `file_size` / `expires_at` | 代理时定位 OSS、写头、判过期 |
| `import_jobs.source_file_*` / `error_report_file_*` / `expires_at` | 同上 |
| OSS `{tenantCode}/exports/...`、`{tenantCode}/imports/...` | 唯一存储；CDN 不再作为读路径 |
| `StorageService.open(path)` | 应用读对象；wrapper `close()` 须关掉 OSS client。`getObject` 失败时现网会泄漏，本波必须在 `open` 内 shutdown 再抛 |
| `StorageService.generateSignedUrl` | **仅图片**；作业下载不再调用 |

不要为下载建新表或把文件改存本地盘。

---

## 2. 导出 `GET /api/v1/report/export-jobs/{id}/file`

权限：登录即可进 Controller；服务层与现网 `getDownloadUrl` 相同（本人 + Handler `requiredAuthority`；ADMIN 全租户）。

成功：`ResponseEntity<StreamingResponseBody>`，**不是** `ApiResponse<String>`，**不是** `InputStreamResource`。

`InputStreamResource.isOpen()` 恒 true，`contentLength()` 会抛 `IllegalStateException`，`Content-Length` 经常发不出去。锁定写法：

```java
return ResponseEntity.ok()
        .contentType(MediaType.parseMediaType(download.contentType()))
        .header(HttpHeaders.CONTENT_DISPOSITION, disposition.toString())
        .contentLength(download.contentLength()) // 仅 fileSize 非空时调用
        .body((StreamingResponseBody) outputStream -> {
            try (InputStream in = download.content()) {
                in.transferTo(outputStream);
            }
        });
```

| Header | 值 |
|--------|-----|
| `Content-Type` | `handler.fileFormat().getContentType()`（xlsx 或 pdf） |
| `Content-Disposition` | `attachment; filename*=UTF-8''` + RFC 5987。`fileName` 空白则 `{jobType}{fileFormat.extension}` |
| `Content-Length` | `job.fileSize` 非空才 `.contentLength(...)`（long 不能传 null） |

Body：`storageService.open(job.filePath)` 的原始字节。

服务层建议形状（不必进 common，放 report 即可）：

```text
record StoredFileDownload(
    InputStream content,
    String fileName,
    String contentType,
    Long contentLength
)
```

`ExportJobService.getDownloadUrl(Long)` **删除**，改为例如 `openExportFile(Long id)`，内部顺序：

1. load + `requireOwnedByCurrentUser`（越权 → `NotFoundException` `entity.export_job`）
2. 非 ADMIN 则 `requiredAuthority`
3. 非 COMPLETED 或 `filePath` 空 → `validation.export.job.not.completed`
4. `expiresAt` 已过 → `validation.export.job.expired`
5. 解析下载文件名：`StringUtils.hasText(job.getFileName())` 用表字段，否则 `{jobType}{handler.fileFormat().getExtension()}`。**禁止**把 null/空串传给 `ContentDisposition.filename`
6. `open(filePath)`；OSS 无对象 → 业务错误（见 §4），**不要**把 SDK 堆栈回给前端
7. 审计日志
8. 返回 `StoredFileDownload`

Controller 只组头 + `StreamingResponseBody`，不二次 `open`。

---

## 3. 导入源文件 / 错误报告

```text
GET /api/v1/report/import-jobs/{id}/source
GET /api/v1/report/import-jobs/{id}/error-report
```

权限与现网 url 接口相同。Content-Type 固定导出 xlsx MIME。文件名用表字段，空白时 fallback `{jobType}.xlsx` / `{jobType}_errors.xlsx`。

| 接口 | 现网条件（保持） |
|------|------------------|
| `/source` | `sourceFilePath` 非空、未过期 |
| `/error-report` | `COMPLETED`、`errorReportFilePath` 非空、未过期 |

`getSourceUrl` / `getErrorReportUrl` **删除**。

---

## 4. 错误（JSON，流开始前）

异常处理器现网已把 `ValidationException` / `NotFoundException` / `AccessDeniedException` 编成 `ApiResponse` JSON。下载接口复用，不新造错误信封。

| 条件 | message key | 行为 |
|------|-------------|------|
| 作业不存在 / 非本人非 ADMIN | `entity.export_job` / `entity.import_job` | 404 |
| 未完成 / 无路径 | 现网 `validation.export.job.not.completed`、`validation.import.job.not.completed` | 400 |
| 过期 | 现网 `validation.export.job.expired`（导入对等 key） | 400 |
| 无错误报告 | `validation.import.error_report.missing` | 400 |
| 业务权限已回收 | 现网 `AccessDeniedException`（Missing authority: ...） | 与现网签发一致 |
| OSS 对象缺失 | **新增** `validation.storage.object.missing`（中文参考：文件在存储中不存在或已被清理） | 400；打 warn 日志 |

`AliyunStorageService.open`：**先**保证 `getObject` 失败时 `ossClient.shutdown()`，**再**把 `NoSuchKey` 收口为上述 ValidationException（其它 OSS 异常 shutdown 后原样抛）。收口只放 `open` 这一处，report 不要再 catch 一层。

前端 `downloadApiFile`：见 §5。HTTP 非 2xx 必须 **throw**，禁止 `downloadBlob`。

流已经开始后的中断（客户端取消、Nginx 超时、OSS 断流）：无法再改成 JSON。验收只要求「校验失败必须是 JSON」；半截文件由浏览器下载项失败体现。

---

## 5. 前端 API

`endpoints.ts`：

```text
exportJobs.file:        (id) => `${API_PREFIX}/report/export-jobs/${id}/file`
importJobs.source:      (id) => `${API_PREFIX}/report/import-jobs/${id}/source`
importJobs.errorReport: (id) => `${API_PREFIX}/report/import-jobs/${id}/error-report`
```

删除 `downloadUrl` / `sourceUrl` / `errorReportUrl`。

`src/services/report/export-job/api.ts`：

```text
downloadExportJobFile(id: Key): Promise<void>
```

内部只调 `downloadApiFile(endpoints.exportJobs.file(id), 'export.xlsx')`。  
导入源文件 / 错误报告同理；模板改为走 `downloadApiFile`。

`downloadApiFile` 放 `src/utils/`（与 `download.ts` / `blob.ts` 一起），**不要**在每个 page 复制一份 blob 逻辑。对照 `requestPdfBlob`，**不要**对照导入模板里未 skip 的 `request`。

请求选项 **锁定**（缺一不可）：

```text
method: 'GET'
responseType: 'blob'
getResponse: true
timeout: 300_000
skipErrorHandler: true
```

`src/requestConfig.tsx`：`errorHandler` 在非 skip 时弹窗后 `return`，promise **resolve**。作业下载若不开 skip：

```text
await downloadExportJobFile(job.id);   // 400 时这里当成功返回
message.success(component.export.success);  // 与错误弹窗并存 = 假成功
```

因此 `downloadApiFile` 必须：

1. `skipErrorHandler: true` → 4xx/5xx 走 reject
2. 按 URL 维护 in-flight `Map<string, Promise<void>>`：连点 **join 同一 Promise**。禁止空 `return`（否则列表页会假成功）
3. catch：**仅当** `error.response?.data instanceof Blob` 才 `.text()` / `JSON.parse`。无 response（`ECONNABORTED`、断网）用 `error.message` 或 `component.export.downloadFailed`，禁止对 undefined 取值
4. **自己** `message.error`，**再 throw**
5. 成功路径才 `downloadBlob`
6. 全程 `message.loading({ key: 'job-file-download', duration: 0 })`，`finally` destroy

不要把错误 JSON 存成 `.xlsx`。

---

## 6. 配置项

| 项 | 本波 |
|----|------|
| `lychee.export.download-url-expiration-seconds` | 删除用法；配置项可删 |
| `lychee.import.download-url-expiration-seconds` | 同上 |
| `aliyun.cdn.*` | **保留**（图片） |
| `spring.mvc.async.request-timeout` | **必须** `300000`（ms）。`StreamingResponseBody` 走 Servlet 异步；未配则 Tomcat 默认约 30s，会先于 Nginx/Axios 掐断 |
| 前端 `timeout` / Nginx `proxy_*_timeout` | 同样 300s，三层对齐 |

不要加「文件最大代理字节」配置。行数上限已经限制生成体积。

---

## 7. 权限与菜单

不改 `adm` 菜单树。导出中心 `read`/`delete`、业务 `{path}:export` / `{path}:import` 不变。  
`GET /file` 不挂 `/report/export-jobs:read`，否则没有导出中心菜单的人会在列表页导出成功后下载 403。

---

## 8. 与既有字节流的关系

| 端点 | 包一层 | 用途 |
|------|--------|------|
| `GET /import-jobs/templates/{jobType}` | `byte[]`（模板小） | 保持；前端改走共用下载函数 |
| `GET /{resource}/{id}/pdf` | `byte[]` PDF | **不改**（预览，非作业 OSS） |
| `GET /export-jobs/{id}/file` 等 | **`StreamingResponseBody`**，禁止 `InputStreamResource` / `byte[]` | 本专题 |

禁止把作业文件做成模板那种整包 `byte[]`。

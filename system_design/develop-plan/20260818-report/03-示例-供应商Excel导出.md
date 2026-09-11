# 03 — 示例：供应商资料导出 Excel

作为导出框架的首个落地案例，验证框架的完整闭环。前置：02 文档的框架已就绪。

## 1. 需求

供应商列表页（`/scm/suppliers`）工具栏增加「导出」按钮，按当前筛选条件导出全部供应商资料为 xlsx，列头与枚举值按用户当前语言渲染。

## 2. 后端：`SupplierExportHandler`（`lychee-erp-scm`）

### 2.1 登记作业类型

`ExportJobType` 枚举（common）新增 `SCM_SUPPLIER`。

### 2.2 导出行 DTO

```java
// com.lychee.erp.scm.export.dto.SupplierExportRow
public class SupplierExportRow {
    @ExcelProperty("pages.scm.suppliers.code")        private String code;
    @ExcelProperty("pages.scm.suppliers.name")        private String name;
    @ExcelProperty("pages.scm.suppliers.supplierType")private String supplierType;  // 枚举翻译后文本
    @ExcelProperty("pages.scm.suppliers.taxId")       private String taxId;
    @ExcelProperty("pages.scm.suppliers.phone")       private String phone;
    @ExcelProperty("pages.scm.suppliers.email")       private String email;
    @ExcelProperty("pages.scm.suppliers.contactPerson") private String contactPerson;
    @ExcelProperty("pages.scm.suppliers.contactPhone")  private String contactPhone;
    @ExcelProperty("pages.scm.suppliers.contactEmail")  private String contactEmail;
    @ExcelProperty("pages.scm.suppliers.addressLocal")  private String addressLocal;
    @ExcelProperty("pages.scm.suppliers.addressEn")     private String addressEn;
    @ExcelProperty("pages.scm.suppliers.currency")      private String currencyName; // 字典解析
    @ExcelProperty("pages.scm.suppliers.activeStatus")  private String activeStatus;
    @ExcelProperty("pages.scm.suppliers.description")   private String description;
    @ExcelProperty("common.createdBy")                  private String createdByName;
    @ExcelProperty("common.createdAt")  @DateTimeFormat("yyyy-MM-dd HH:mm")
                                                        private LocalDateTime createdAt;
}
```

> `@ExcelProperty` 中存 i18n key，由 `ExcelWriteSupport` 写入前经 `MessageService` 按作业 `locale` 解析成实际列头（与前端 `pages.ts` 复用同一套 key 语义，缺失的 key 补进后端 messages 资源）。

### 2.3 Handler 实现

```java
@Component
@RequiredArgsConstructor
public class SupplierExportHandler implements DataExportHandler {

    private final SupplierRepository supplierRepository;
    private final DictionaryCacheService dictionaryCacheService;
    private final MessageService messageService;

    @Override public ExportJobType type() { return ExportJobType.SCM_SUPPLIER; }
    @Override public String requiredAuthority() { return "/scm/suppliers:export"; }

    @Override
    public long count(ExportContext ctx) {
        return supplierRepository.count(
            DynamicSpecifications.build(Supplier.class, ctx.params()));
    }

    @Override
    public ExportResult export(ExportContext ctx, OutputStream out) {
        Specification<Supplier> spec =
            DynamicSpecifications.build(Supplier.class, ctx.params());
        // ExcelWriteSupport 骨架：按 sort（默认 id DESC）分页 1000 行/批，
        // 每批 map 为 SupplierExportRow（枚举/字典/审计人名在此翻译），流式写入 out
        int total = ExcelWriteSupport.write(out, SupplierExportRow.class, ctx,
            pageable -> supplierRepository.findAll(spec, pageable)
                            .map(s -> toRow(s, ctx.locale())));
        String fileName = messageService.get("pages.scm.suppliers.title", ctx.locale())
            + "_" + LocalDate.now() + ".xlsx";
        return new ExportResult(total, fileName);
    }
}
```

要点：

- 查询规格与 `SupplierServiceImpl.getSupplierPage` 完全同源（`DynamicSpecifications.build(Supplier.class, params)`），保证导出=列表所见。
- 枚举 `SupplierType`、`activeStatus`、币别字典、创建人姓名（`dictionaryCacheService.fillAuditNames` 同逻辑）在 map 阶段翻译为文本，Excel 中不出现裸代码值。
- 无需 `@Transactional` 大事务：每批分页查询独立执行即可（导出是只读快照，接受批间微小不一致；如需严格一致可加只读事务，注意长事务与连接占用的取舍，一期不做）。

### 2.4 权限数据

权限种子数据（菜单/权限表）为 `/scm/suppliers` 增加 `export` action 记录，赋予相应角色。

## 3. 前端：供应商列表接入

### 3.1 页面改动（`src/pages/scm/suppliers/index.tsx`）

```tsx
const lastPageRequestRef = useRef<PageRequest>(toPageRequest({ current: 1, pageSize: 10 }, {}));

<ProTable<Supplier>
  request={async (params, sort) => {
    lastPageRequestRef.current = toPageRequest(params, sort);   // 记录当前筛选
    return getSupplierPage(params, sort);
  }}
  toolBarRender={(action, { selectedRowKeys }) => [
    <AddButton key="add" onClick={handleAdd} />,
    <ExportButton key="export" jobType="SCM_SUPPLIER"
                  getPageRequest={() => lastPageRequestRef.current} />,
    <BatchDeleteButton key="del" ... />,
  ]}
/>
```

导出的 `PageRequest` 只取 `params` 与 `sort`（`pageNumber/pageSize` 由后端忽略——导出永远全量）。

### 3.2 交互验收标准

1. 无 `export` 权限时按钮不渲染。
2. 小数据量（≤5,000 行）：点击后 1 个请求内完成，浏览器直接弹出下载，文件名如 `供应商_2026-07-31.xlsx`。
3. 大数据量：点击后出现"导出处理中"通知，页面可继续操作；完成后自动触发下载；也可到「导出中心」手动下载。
4. 列表输入筛选（如 `code_like=ABC`、类型下拉）后导出，Excel 行集与列表分页翻完的总集一致，总行数等于列表 `total`。
5. 切换语言（zh-CN/en-US/vi-VN）后导出，列头与枚举文本随语言变化。
6. 导出失败（如超 20 万行上限）时，通知展示后端错误消息，作业在导出中心显示 FAILED 与原因。

## 4. 测试要点

- 单元：`SupplierExportHandler.export` 用内存 `ByteArrayOutputStream` + Fesod 读回断言行数/列头/翻译。
- 集成：多租户用例——租户 A 创建作业，租户 B 查询 `/page` 与下载 URL 均不可见（`@TenantId` 过滤生效）；异步路径断言监听器执行后 `TenantContextHolder` 已清理。
- 性能基线：本地 5 万行导出 < 30s、堆增量 < 256MB（验证流式写入与分页读取生效）。

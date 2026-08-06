# AI 後端開發 Prompt

## 1. 角色與任務 (Role & Goal)

**你的角色**: 你是一位精通本項目架構的 Java 後端開發專家。
**你的任務**: 根據用戶提供的模組名稱，嚴格遵循以下所有規範和模式，生成一個完整的、可立即運行的後端模組，包括 Model, DTO, Mapper, Repository, Service, 和 Controller 層的全部代碼。

---

## 2. 核心變數 (Core Variables)

在生成代碼時，你必須使用以下變數來替換對應的名稱：

- `{ModuleName}`: 模組名稱 (首字母大寫駝峰, e.g., `ProductCategory`)
- `{moduleName}`: 模組名稱 (首字母小寫駝峰, e.g., `productCategory`)
- `{TABLE_NAME}`: 數據庫表名 (小寫蛇形, e.g., `product_category`)
- `{API_PATH}`: API 路徑 (小寫連字符, e.g., `product-category`)

---

## 3. 開發工作流 (Development Workflow)

請嚴格按照以下順序和規範，生成每一層的文件。

### 步驟 1: Model (Entity)

**位置**: `com/lychee/erp/model/`
**任務**: 創建名為 `{ModuleName}.java` 的 JPA 實體文件。

**規則**:
- **必須** 繼承 `AuditableEntity`。
- **必須** 使用 `@EqualsAndHashCode(callSuper = false)`。
- **必須** 包含以下 Lombok 註解: `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`。
- **必須** 包含 `@Entity` 和 `@Table(name = "{TABLE_NAME}")`。
- 主鍵字段**必須**使用 `@Id` 和 `@GeneratedValue(strategy = GenerationType.IDENTITY)`。
- 所有數據庫字段**必須**使用 `@Column` 明確指定列名。
- **必須** 對 DTO 傳入的字段（如 `name`, `code`）使用 Jakarta Validation 註解 (`@NotNull`, `@NotBlank`, `@Size` 等)，並使用國際化鍵值 `{validation.{moduleName}.fieldName.required}` 作為 `message`。

### 步驟 2: DTO (Data Transfer Object)

#### RequestDTO
**位置**: `com/lychee/erp/dto/request/`
**任務**: 創建名為 `{ModuleName}RequestDTO.java` 的文件。
**規則**:
- **必須** 包含 Lombok 註解: `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`。
- **禁止** 包含 `id` 和任何審計字段 (`createdAt`, `updatedAt`, `createdBy`, `updatedBy`)。
- **必須** 對所有需要驗證的字段添加 Jakarta Validation 註解。

#### ResponseDTO
**位置**: `com/lychee/erp/dto/response/`
**任務**: 創建名為 `{ModuleName}ResponseDTO.java` 的文件。
**規則**:
- **必須** 包含 Lombok 註解: `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`。
- **必須** 包含 `id` 和所有業務及審計字段。
- **必須** 實現 `HasAuditUserFields` 接口，並包含 `createdByName` 和 `updatedByName` 字段。
- **如果** Model 中有 `statusOptionId` 字段, **必須** 實現 `HasStatusOption` 接口，並包含 `statusOptionName` 字段。

### 步驟 3: Mapper (MapStruct)

**位置**: `com/lychee/erp/mapper/`
**任務**: 創建名為 `{ModuleName}Mapper.java` 的 MapStruct 接口。
**規則**:
- **必須** 使用以下註解配置:
  ```java
  @Mapper(
      componentModel = ComponentModel.SPRING,
      unmappedTargetPolicy = ReportingPolicy.IGNORE
  )
  ```
- **必須** 包含以下三個核心方法:
  - `{ModuleName} toEntity({ModuleName}RequestDTO dto);`
  - `{ModuleName}ResponseDTO toResponseDTO({ModuleName} entity);`
  - `void updateEntity({ModuleName}RequestDTO dto, @MappingTarget {ModuleName} entity);`

### 步驟 4: Repository (JPA)

**位置**: `com/lychee/erp/repository/`
**任務**: 創建名為 `{ModuleName}Repository.java` 的 JPA 接口。
**規則**:
- **必須** 繼承 `JpaRepository<{ModuleName}, Long>` 和 `JpaSpecificationExecutor<{ModuleName}>`。
- **所有**自定義查詢方法**必須**將 `Long tenantId` 作為第一個參數，以確保租戶數據隔離並符合索引順序。
- 返回單個對象的查詢方法**必須**返回 `Optional<{ModuleName}>`。
- 檢查存在性的方法**必須**返回 `boolean` (e.g., `existsByTenantIdAndCode(Long tenantId, String code)`).

### 步驟 5: Service (業務邏輯)

#### Service Interface
**位置**: `com/lychee/erp/service/`
**任務**: 創建名為 `{ModuleName}Service.java` 的接口，定義所有公開的業務方法。

#### Service Implementation
**位置**: `com/lychee/erp/service/impl/`
**任務**: 創建名為 `{ModuleName}ServiceImpl.java` 的實現類。
**規則**:
- **必須** 使用 `@Service`, `@RequiredArgsConstructor`, `@Slf4j` 註解。
- **必須** 在類級別使用 `@Transactional`。
- **必須** 通過構造函數注入 `{ModuleName}Repository`, `{ModuleName}Mapper`, 和 `DictionaryNameFiller`。
- **所有**分頁查詢方法**必須**調用 `DictionaryNameFiller` 來填充關聯名稱字段 (審計用戶名、狀態名等)。
- 創建和更新操作**必須**包含對唯一性字段的驗證邏輯。
- 刪除操作**必須**使用 `deleteAllInBatch` 以提高性能。

### 步驟 6: Controller (REST API)

**位置**: `com/lychee/erp/controller/`
**任務**: 創建名為 `{ModuleName}Controller.java` 的 REST 控制器。
**規則**:
- **必須** 使用 `@RestController`, `@RequiredArgsConstructor` 註解。
- **必須** 使用 `@RequestMapping("/api/v1/{API_PATH}")` 統一 API 路徑。
- **所有**方法**必須**返回 `ApiResponse<T>`。
- **所有**需要驗證請求體的端點**必須**在 DTO 參數前使用 `@Valid`。
- **必須**為所有端點添加 `@PreAuthorize` 權限控制，權限格式為 `hasAuthority('{moduleName}:{action}')`，其中 action 包括 `create`, `read`, `update`, `delete`。
- **必須** 實現標準的 RESTful 端點：
  - `POST /page`: 分頁查詢
  - `POST /`: 創建
  - `PUT /{id}`: 更新
  - `DELETE /bulk-delete`: 批量刪除

---

## 4. 通用模式與規則 (Common Patterns & Rules)

在實現業務邏輯時，你必須遵循以下模式。

### 分頁查詢模式 (Pagination Pattern)

分頁查詢方法必須遵循此結構，確保動態查詢和名稱填充被正確執行。

```java
@Override
@Transactional(readOnly = true)
public Page<{ModuleName}ResponseDTO> get{ModuleName}Page(PageRequestDTO requestDTO) {
    Long tenantId = CurrentTenant.tenantId();
    var pageable = requestDTO.toPageable();
    
    // 1. 動態規格查詢
    Specification<{ModuleName}> spec = DynamicSpecifications.build({ModuleName}.class, requestDTO.getParams());
    Page<{ModuleName}> entityPage = repository.findAll(spec, pageable);

    // 2. 轉換為 DTO
    List<{ModuleName}ResponseDTO> items = entityPage.getContent().stream()
            .map(mapper::toResponseDTO)
            .collect(Collectors.toList());
 
    // 3. 填充名稱字段
    dictionaryCacheService.fillAuditNames(tenantId, items);
    // [可選] 如果 DTO 實現了 HasStatusOption
    dictionaryCacheService.fillStatusOptionNames(tenantId, items);

    return new PageImpl<>(items, pageable, entityPage.getTotalElements());
}
```

### 唯一性驗證 (Uniqueness Validation)

在創建和更新時，必須檢查唯一約束字段（如 `code`）是否重複。

```java
// Create
if (repository.existsByTenantIdAndCode(tenantId, requestDTO.getCode())) {
    throw new ValidationException("validation.{moduleName}.code.duplicate");
}

// Update
repository.findByTenantIdAndId(tenantId, id).ifPresent(entity -> {
    if (!entity.getCode().equals(requestDTO.getCode()) && 
        repository.existsByTenantIdAndCode(tenantId, requestDTO.getCode())) {
        throw new ValidationException("validation.{moduleName}.code.duplicate");
    }
});
```

### 異常處理 (Exception Handling)
- 資源未找到時，**必須**拋出 `NotFoundException`。
- 業務驗證失敗時，**必須**拋出 `ValidationException`。
- 異常消息**必須**使用國際化鍵值。

### 緩存清理 (Cache Eviction)
- 如果模組的變更影響到用戶權限相關的緩存 (如 `User`, `Role`, `Permission` 等), **必須**在對應的 Service 方法上使用 `@CacheEvict(value = CaffeineConfig.USER_AUTHORITIES_CACHE, allEntries = true)`。


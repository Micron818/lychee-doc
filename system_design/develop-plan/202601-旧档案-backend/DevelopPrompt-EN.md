# AI Backend Development Prompt

## 1. Role & Goal

**Your Role**: You are an expert Java backend developer with deep knowledge of this project's architecture.
**Your Goal**: Based on the module name provided by the user, you will generate a complete, runnable backend module. This includes all code for the Model, DTO, Mapper, Repository, Service, and Controller layers, strictly adhering to all specifications and patterns outlined below.

---

## 2. Project Module Structure

This is a **Gradle multi-module project** with the following structure:

- **`lychee-erp-common`**: Common module containing shared utilities, base entities, DTOs, exceptions, security, and specifications. All business modules depend on this module.
- **`lychee-erp-adm`**: System management module (RBAC, menu, role, permission, option, etc.). This is also the **application entry point** where the main Spring Boot application runs.
- **`lychee-erp-basis`**: Business module for company, factory, department management.
- **`lychee-erp-mm`**: Business module for material management.
- **`lychee-erp-sd`**: Business module for sales and distribution management.
- **Future business modules**: Additional business modules can be added following the same pattern.

**Important Notes**:
- All business modules (basis, mm, etc.) are **library modules** (using `java-library` plugin), not standalone applications.
- Controllers are placed in their respective business modules, but the application entry point is in the `adm` module.
- Shared classes (e.g., `AuditableEntity`, `ApiResponse`, `ProPageRequest`, `HasAuditUser`, `HasStatusOption`, `DictionaryCacheService`, `DynamicSpecifications`, `CurrentTenant`, `ValidationException`, `NotFoundException`) are located in the `lychee-erp-common` module and should be imported from `com.lychee.erp.*` package.

---

## 3. Core Variables

When generating code, you **must** use the following variables for their corresponding names:

- `{BusinessModule}`: The target business module name (e.g., `basis`, `mm`, `sd`). This determines where files will be created (e.g., `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/...`).
- `{ModuleName}`: The entity/class name in UpperCamelCase (e.g., `ProductCategory`, `Material`, `SalesOrder`).
- `{moduleName}`: The entity/class name in lowerCamelCase (e.g., `productCategory`, `material`, `salesOrder`).
- `{TABLE_NAME}`: The database table name in snake_case plural (e.g., `product_categories`, `materials`).
- `{API_PATH}`: The API path in kebab-case plural (e.g., `product-categories`, `materials`).

---

## 4. Development Workflow

Strictly follow this sequence and its specifications to generate the files for each layer.

**Must**: Don't delete the existing code.
**Must**: Only update message id with English in property file `lychee-erp-adm/src/main/resources/i18n/messages.properties`
**Must**: All file paths mentioned below are relative to the target business module (e.g., `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/...`).

### Step 1: Model (Entity)

**Location**: `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/{BusinessModule}/model/`
**Task**: Confirm the existing JPA entity file named `{ModuleName}.java`.

**Rules**:
- **Must** extend `AuditableEntity` (from `com.lychee.erp.common.model.base.AuditableEntity` in `lychee-erp-common` module).
- **Must** use `@EqualsAndHashCode(callSuper = false)`.
- **Must** include the following Lombok annotations: `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`.
- **Must** include `@Entity` and `@Table(name = "{TABLE_NAME}")`.
- The primary key field **must** use `@Id` and `@GeneratedValue(strategy = GenerationType.IDENTITY)`.
- **Must** include `tenantId` field explicitly: `@Column(name = "tenant_id", nullable = false) @TenantId
    private Long tenantId;`.
- All database columns **must** be explicitly named using `@Column`.
- Fields provided by the DTO (e.g., `name`, `code`) **must** use Jakarta Validation annotations (`@NotNull`, `@NotBlank`, `@Size`, etc.) with an internationalization key like `validation.{moduleName}.fieldName.required` as the `message`.

### Step 2: DTO (Data Transfer Object)

#### Request
**Location**: `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/{BusinessModule}/dto/request/`
**Task**: Create if not exist the file named `{ModuleName}Request.java`.
**Rules**:
- **Must** include Lombok annotations: `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`.
- **Must not** include `id` or any audit fields (`createdAt`, `updatedAt`, `createdBy`, `updatedBy`).
- **Must not** include child items list (e.g., `items`) for master-detail structures; items are handled via separate endpoints.
- **Must** add Jakarta Validation annotations to all fields requiring validation.

#### Response
**Location**: `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/{BusinessModule}/dto/response/`
**Task**: Create if not exist file named `{ModuleName}Response.java`.
**Rules**:
- **Must** include Lombok annotations: `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`.
- **Must** include `id` and all business fields, exclude field `tenantId`.
- **Must** include auditing fields: `createdAt`, `updatedAt`, `createdBy`, `updatedBy`.
- **Must not** include child items list (e.g., `items`) for master-detail structures; items are handled via separate endpoints.
- **Must** implement the `HasAuditUser` interface (from `com.lychee.erp.common.dto.response.HasAuditUser` in `lychee-erp-common` module) and include the `createdByName` and `updatedByName` fields.
- **If** the Model has a `statusOptionId` field, it **must** implement the `HasStatusOption` interface (from `com.lychee.erp.common.dto.response.HasStatusOption` in `lychee-erp-common` module) and include the `statusOptionName` field.

### Step 3: Mapper (MapStruct)

**Location**: `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/{BusinessModule}/mapper/`
**Task**: Create if not exist MapStruct interface named `{ModuleName}Mapper.java`.
**Rules**:
- **Must** be configured with the following annotations:
  ```java
  import org.mapstruct.Mapper;
  import org.mapstruct.MappingTarget;
  import com.lychee.erp.common.mapper.JsonNullableMapper;
  import org.mapstruct.NullValuePropertyMappingStrategy;
  import org.mapstruct.ReportingPolicy;
  import org.mapstruct.MappingConstants.ComponentModel;

  @Mapper(componentModel = ComponentModel.SPRING, 
  uses = JsonNullableMapper.class, 
  nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE, 
  unmappedTargetPolicy = ReportingPolicy.IGNORE)
  ```
- **Must** include these three core methods:
  - `{ModuleName} toEntity({ModuleName}Request request);`
  - `{ModuleName}Response toResponse({ModuleName} entity);`
  - `void updateEntity({ModuleName}Request request, @MappingTarget {ModuleName} entity);`

### Step 4: Repository (JPA)

**Location**: `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/{BusinessModule}/repository/`
**Task**: Create if not exist  JPA interface named `{ModuleName}Repository.java`.
**Rules**:
- **Must** retain the existing methods.
- **Must** extend `JpaRepository<{ModuleName}, Long>` and `JpaSpecificationExecutor<{ModuleName}>`.
- **All** custom query methods **must** take `Long tenantId` as the first parameter to ensure tenant data isolation and proper index usage.
- Methods checking for existence **must** return a `boolean` (e.g., `boolean existsByTenantIdAndCode(Long tenantId, String code)`).
- **Must** include `boolean existsByTenantIdAndId(Long tenantId, Long id);`.
 - **Must** include `List<{ModuleName}> findAllByTenantIdAndIdIn(Long tenantId, Set<Long> ids);` for bulk operations.

### Step 5: Service (Business Logic)

#### Service Interface
**Location**: `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/{BusinessModule}/service/`
**Task**: Create an interface named `{ModuleName}Service.java`.
**Rules**:
- For **Main Entity**:
  - `create{ModuleName}` and `update{ModuleName}` methods **must** return a `{ModuleName}Response`.
  - **Must not** include single `get{ModuleName}` or full list `get{ModuleName}List` methods; use pagination only.
  - **Must** include pagination method `get{ModuleName}Page`.
  - **Must** include `delete{ModuleName}Bulk` for batch deletion.
- For **Master-Detail Structures**:
  - **Must** separate Item operations into their own methods within the main Service interface.
  - `create{ModuleName}Item(Long {moduleName}Id, {ModuleName}ItemRequest request)`
  - `update{ModuleName}Item(Long {moduleName}Id, Long itemId, {ModuleName}ItemRequest request)`
  - `delete{ModuleName}ItemBulk(Long tenantId, Long {moduleName}Id, Set<Long> ids)`
  - `get{ModuleName}ItemPage(Long {moduleName}Id, ProPageRequest request)`

#### Service Implementation
**Location**: `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/{BusinessModule}/service/impl/`
**Task**: Create an implementation class named `{ModuleName}ServiceImpl.java`.
**Rules**:
- **Must** retain the existing methods.
- **Must** use the `@Service`, `@RequiredArgsConstructor`, and `@Slf4j` annotations.
- **Must** use `@Transactional` at the class level.
- **Must** use constructor injection for repositories, mappers, and `DictionaryCacheService`.
- **Must** use `DictionaryCacheService` to populate associated name fields via `.fillAuditNames()` or `.fillStatusOption()`.
- **Master-Detail Logic**:
  - `create` and `update` of Master entity **must not** handle Items creation/update.
  - `delete{ModuleName}Bulk` **must** explicitly delete items first (using `deleteAllInBatch`) before deleting master entities.
  - Item operations must validate parent ID existence using `existsByTenantIdAndId` (lighter query).
  - Bulk delete for items must use `findAllByTenantIdAndIdIn` filtered by parent ID in memory, then `deleteAllInBatch`.
- **Validation**:
  - Create and update operations **must** include validation logic for unique fields.
  - Create and update operations **must** validate foreign key references using a private `validateHeaderForeignKeys` or `validateItemForeignKeys` method.

### Step 6: Controller (REST API)

**Location**: `lychee-erp-{BusinessModule}/src/main/java/com/lychee/erp/{BusinessModule}/controller/`
**Task**: Create a REST controller named `{ModuleName}Controller.java`.
**Rules**:
- **Must** use the `@RestController` and `@RequiredArgsConstructor` annotations.
- **Must** use `@RequestMapping("/api/v1/{BusinessModule}/{API_PATH}")` to define the base API path with module prefix.
- **All** methods **must** directly return `ApiResponse<T>` (from `com.lychee.erp.common.dto.response.ApiResponse`).
- **All** endpoints that validate a request body **must** use the `@Valid` annotation.
- **Must** specify explicit names for `@PathVariable` and `@RequestParam` annotations (e.g., `@PathVariable("id")`, `@RequestParam("key")`) to ensure compatibility with Spring 6.x.
- **Must** add `@PreAuthorize` for permission control on all endpoints.
- **Must** implement standard RESTful endpoints:
  - `POST /page`: Pagination query (returns list, not Page object).
  - `POST`: Create.
  - `PUT /{id}`: Update.
  - `DELETE /bulk-delete`: Bulk delete.
- **For Master-Detail Structures**:
  - Implement sub-resource endpoints for items:
  - `POST /{id}/items/page`: Item pagination.
  - `POST /{id}/items`: Create item.
  - `PUT /{id}/items/{itemId}`: Update item.
  - `DELETE /{id}/items/bulk-delete`: Bulk delete items.

---

## 5. Common Patterns & Rules

You must follow these patterns when implementing business logic.

### Pagination Pattern

Pagination query methods must adhere to this structure to ensure dynamic queries and name filling are correctly implemented. Note that the Controller returns `ApiResponse<List<...>>`.

```java
@Override
@Transactional(readOnly = true)
public Page<{ModuleName}Response> get{ModuleName}Page(ProPageRequest request) {
    Long tenantId = CurrentTenant.tenantId(); // from com.lychee.erp.common.security.CurrentTenant
    request.getParams().put("tenantId", tenantId);
    var pageable = request.toPageable();
    
    // 1. Build dynamic specification
    Specification<{ModuleName}> spec = DynamicSpecifications.build({ModuleName}.class, request.getParams()); // from com.lychee.erp.common.specification.DynamicSpecifications
    Page<{ModuleName}> entityPage = repository.findAll(spec, pageable);

    // 2. Convert to DTOs
    List<{ModuleName}Response> items = entityPage.getContent().stream()
            .map(mapper::toResponse)
            .collect(Collectors.toList());
 
    // 3. Fill name fields using DictionaryCacheService
    dictionaryCacheService.fillAuditNames(tenantId, items); // from com.lychee.erp.common.service.DictionaryCacheService
    // [Optional] If items implements HasStatusOption
    dictionaryCacheService.fillStatusOption(tenantId, items);

    return new PageImpl<>(items, pageable, entityPage.getTotalElements());
}
```

### Controller Pagination Response Pattern

To accommodate frontend components like Ant Design ProTable, the controller must convert the `Page` object from the service into a specific JSON structure. Use the static helper `ApiResponse.success(page)` for this.

```java
@PostMapping("/page")
@PreAuthorize("hasAuthority('/{BusinessModule}/{API_PATH}:read')")
public ApiResponse<List<{ModuleName}Response>> get{ModuleName}Page(@RequestBody ProPageRequest request) {
    Page<{ModuleName}Response> page = {moduleName}Service.get{ModuleName}Page(request);
    return ApiResponse.success(page);
}
```

### Uniqueness Validation

When creating and updating, you must check for duplicate values in unique-constrained fields (e.g., `code`).

```java
// In create{ModuleName}
if (repository.existsByTenantIdAndCode(tenantId, request.getCode())) {
    throw new ValidationException("validation.{moduleName}.code.duplicate");
}

// In update{ModuleName}
if (!entity.getCode().equals(request.getCode()) 
        && repository.existsByTenantIdAndCode(tenantId, request.getCode())) {
    throw new ValidationException("validation.{moduleName}.code.duplicate");
}
```

### Foreign Key Validation

When creating and updating entities that reference other entities through foreign keys, you **must** extract all foreign key validation logic into a private `validateForeignKeys` (or `validateHeaderForeignKeys`/`validateItemForeignKeys`) method.

**Structure**:
```java
private void validateForeignKeys(Long tenantId, {ModuleName}Request request) {
    // Validate required foreign keys
    repository.findByTenantIdAndId(tenantId, request.getRequiredFieldId())
            .orElseThrow(() -> new NotFoundException("validation.{moduleName}.requiredFieldId.not.found"));

    // Validate optional foreign keys (check for null first)
    if (request.getOptionalFieldId() != null) {
        repository.findByTenantIdAndId(tenantId, request.getOptionalFieldId())
                .orElseThrow(() -> new NotFoundException("validation.{moduleName}.optionalFieldId.not.found"));
    }
}
```

**Note**: `ValidationException` and `NotFoundException` are from `com.lychee.erp.common.exception.*` in the `lychee-erp-common` module.

### Cross-Module Data Fetching

When a module needs to fetch data from another module (e.g., SD module needs Customer info from CRM), follow this pattern:

1.  **Common Interface**: Define a Service interface and DTO in `lychee-erp-common` (e.g., `RemoteCustomerService`, `RemoteCustomerDTO`).
2.  **Implementation**: Implement this interface in the provider module (e.g., `lychee-erp-crm`).
3.  **Injection**: Inject the interface in the consumer module's Service (e.g., `SalesOrderServiceImpl` in SD) to fetch data.

**Example**:
```java
// In Service Implementation
@Autowired
private RemoteCustomerService remoteCustomerService;

// In getPage method
Map<Long, RemoteCustomerDTO> customerMap = remoteCustomerService.getCustomers(tenantId, customerIds);
items.forEach(item -> {
    RemoteCustomerDTO customer = customerMap.get(item.getCustomerId());
    if (customer != null) {
        item.setCustomerCode(customer.code());
        item.setCustomerName(customer.name());
    }
});
```

# 03. Schema 与解析契约

> 未上线：以本文件为设计依据。本波 **不建表、不改唯一键**。  
> 命名一律 **按款生成 BOM**。  
> V1 `copyBom` **不是**依据，见 §1。

---

## 1. 改什么、不改什么

| 对象 | 动作 |
|------|------|
| `bill_of_materials` | **不改**粒度与约束。生成只 INSERT 现网列 |
| `bom_items` | **不改**。生成只 INSERT 现网列 |
| `uk_bom_product_version` | **保留** `(tenant_id, product_material_id, version)` |
| `uk_bom_items` | **保留** `(tenant_id, bom_id, component_material_id)` |
| `uk_bom_items_item_no` | **保留** `(tenant_id, bom_id, item_no)` |
| `bom_templates` / Super BOM | **不建** |
| `bill_of_materials.product_model_id` | **不加**（执行不认款号） |
| `bom_items.match_mode` | **不加**（落库后就是普通行；模式只在请求里） |
| `bom_items` 按码用量列 | **不加**。SIZE_SCALE 只在请求换算，写入仍是单值 `quantity` |
| `materials` / 变体索引 | **不改** |
| `MaterialVariantGenerateRequest.copyBom` | **不实现、不删除字段**（避免无谓改契约） |
| `BillOfMaterial.description` | **补 Entity / Response 映射**（列已在，见 `01` §2） |
| `BomComponentMatchMode` | **新增** Java 枚举 |
| `BomGenerateCellStatus` | **新增**（生成专用，可只活在 PP DTO） |
| MRP / 工单 / LLC 表 | **不改** |
| `status_option_id` | **不用** |

生成结果与手建行在库内无法区分，这是有意的：批准与展开不需要「来自向导」标记。

---

## 2. 实体关系（执行层不变）

```text
product_models 1───* materials (fashion variant SKU)
                        │
                        └── 1───* bill_of_materials 1───* bom_items *───1 materials (component)

请求（不落库）
  BomGenerateRequest
    ├─ productModelId
    ├─ version / validFrom / validTo / description
    ├─ cells[]          色 × 码
    └─ items[]          种子料 + matchMode + quantity + sizeQuantities[]
         │ preview 解析子件、按父件尺码换算用量
         ▼
      每格 resolvedMaterialId + resolvedQty
         → INSERT bom_items.component_material_id / quantity
```

Pegging / 工单组件仍从 SKU BOM 展开，不增加生成专用 FK。

---

## 3. 现网列（生成必须写满）

### 3.1 表头 `bill_of_materials`

| 列 | 生成写入 |
|----|----------|
| `product_material_id` | 该格 SKU id |
| `version` | 请求共用，`varchar(20)` |
| `valid_from` | 请求共用，必填 |
| `valid_to` | 请求共用，可空 |
| `bom_status` | 固定 `DRAFT` |
| `description` | 请求共用，可空；本波补 Entity 映射 |

### 3.2 表身 `bom_items`

| 列 | 生成写入 |
|----|----------|
| `bom_id` | 刚插入的头 |
| `item_no` | 模板项次或 10/20/30… |
| `component_material_id` | 解析结果，不是种子（`FIXED` 时二者相同） |
| `quantity` | 该格 `resolvedQty`（`sizeQuantities[父码]` 或默认 `quantity`），不是模板默认值原样 |
| `scrap_rate` | 模板，默认 0 |
| `is_backflush` | 模板，可空 |
| `remarks` | 模板，可空 |
| `active_status` | 模板，默认 `ACTIVE` |

`item_no` 步长对标现网 `DocumentItemNoAllocator` BOM 默认 10。同一头内项次唯一，由模板校验保证，不要生成后再重排。

---

## 4. 请求 / 响应契约

放 `lychee-erp-pp` DTO，**不要**放进 `RemoteBom*`（现网 Remote 是给 MRP/他模组读生效 BOM，不是生成）。

```java
public enum BomComponentMatchMode {
    FIXED,
    COLOR_MATCH,
    SIZE_MATCH,
    COLOR_SIZE_MATCH
}

public enum BomGenerateCellStatus {
    NEW,
    EXISTS,
    MISSING_SKU,
    INELIGIBLE,
    UNRESOLVED,
    CONFLICT,
    DUPLICATE,
    SELF_REF
}

public enum BomGenerateLineResolveStatus {
    RESOLVED,
    UNRESOLVED,
    CONFLICT,
    DUPLICATE,
    SELF_REF,
    SKIPPED          // EXISTS 格不解析
}

public class BomGenerateRequest {
    @NotNull Long productModelId;
    @NotBlank @Size(max = 20) String version;
    @NotNull LocalDate validFrom;
    JsonNullable<LocalDate> validTo;
    String description;

    /** preview 可空 = 用 colorIds×productSizeIds 展开；generate 必填。不要在字段上 @NotEmpty */
    @Size(max = 200) List<BomGenerateCellRequest> cells;
    List<Long> colorIds;           // 区分色；不分色必须空
    List<Long> productSizeIds;     // preview 展开用；服务层校验，不要 @NotEmpty

    @Valid @Size(max = 50) List<BomGenerateItemRequest> items;
}

public class BomGenerateCellRequest {
    Long colorId;                  // 不分色必须空
    @NotNull Long productSizeId;
}

public class BomGenerateItemRequest {
    Integer itemNo;
    @NotNull BomComponentMatchMode matchMode;
    @NotNull Long seedMaterialId;
    @NotNull BigDecimal quantity;                 // 默认 / 未列码回退
    @Valid List<BomGenerateSizeQuantity> sizeQuantities; // 可空 = 全码同量
    BigDecimal scrapRate;
    Boolean isBackflush;
    String remarks;
    @NotNull ActiveStatus activeStatus;
}

/** 按码绝对用量。不要加 percent 字段。 */
public class BomGenerateSizeQuantity {
    @NotNull Long productSizeId;
    @NotNull BigDecimal quantity;
}

public class BomGeneratePreviewResponse {
    boolean distinguishColor;
    List<BomGeneratePreviewSizeColumn> sizeColumns; // PP 自建；形状同 MM 预览列，禁止 import MM
    List<BomGeneratePreviewColorRow> colorRows;
    List<BomGeneratePreviewCell> cells;
}

/** 与 MaterialVariantPreviewSizeColumn 同形，放 lychee-erp-pp */
public class BomGeneratePreviewSizeColumn {
    Long id;
    String code;
    String name;
    Integer sequence;
}

/** 与 MaterialVariantPreviewColorRow 同形，放 lychee-erp-pp */
public class BomGeneratePreviewColorRow {
    Long id;
    String code;
    String name;
    Integer sequence;
}

public class BomGeneratePreviewCell {
    Long colorId;
    Long productSizeId;
    BomGenerateCellStatus status;
    Long productMaterialId;
    String productMaterialCode;
    Long existingBomId;
    BomStatus existingBomStatus;
    List<BomGeneratePreviewItem> items;
}

public class BomGeneratePreviewItem {
    Integer itemNo;
    BomComponentMatchMode matchMode;
    Long seedMaterialId;
    String seedMaterialCode;
    String seedMaterialName;
    BomGenerateLineResolveStatus resolveStatus;
    Long resolvedMaterialId;
    String resolvedMaterialCode;
    String resolvedMaterialName;
    BigDecimal quantity;          // 该格 resolvedQty
    boolean usedDefaultQuantity;  // true = 回退行级 quantity
    String baseUnitCode;          // 解析子件基本单位；UNRESOLVED 等可空
    String baseUnitName;
    BigDecimal scrapRate;
    Boolean isBackflush;
}

public class BomGenerateResponse {
    List<BillOfMaterialResponse> created;
    int skippedExisting;
}
```

`generate` 入参复用 `BomGenerateRequest`。服务先跑与 preview **同一套**解析；细胞状态与提交前 preview 不一致（并发插了同版本）→ 400 + 新 preview，不要静默跳过变坏格。

校验分组（**服务层**判定，对标 `MaterialVariantServiceImpl.prepareContext`；Controller 只用 `@Valid` 做字段格式，**不要** Validation Group，也**不要**给 `cells` / `productSizeIds` / `items` 加 `@NotEmpty`）：

```text
preview：productModelId、productSizeIds、version、validFrom 必填
         items 可空（有则按模板规则校验）
generate：productModelId、version、validFrom 必填
         items 非空；cells 非空且 1～200
         colorIds / productSizeIds 前端向导应回传；若省略则从 cells 去重推导后再校验色模式
```

---

## 5. 解析查找（应用层，无新索引）

色码池用现网 basis 仓储（**不要**新增、不要调 MM）：

```text
ProductModelRepository.findWithSizeGroupById
ProductModelColorRepository.findFetchedByProductModelId
ProductSizeGroupItemRepository.findFetchedBySizeGroupId
MaterialRepository.findByProductModelIdAndProductSizeIdIsNotNullAndIsFashionVariantTrue  // 父件 SKU
```

家族预取（对色面料常为 `is_fashion_variant = false` 但挂了 `product_model_id`）**按款一次查出，内存过滤**。禁止按格、按行、按色打四套单键 finder：

```java
// MaterialRepository（basis）本波新增：父款 + 各种子款一次预取
@Query("""
        SELECT DISTINCT m FROM Material m
        LEFT JOIN FETCH m.materialType
        LEFT JOIN FETCH m.baseUnit
        WHERE m.productModelId IN :productModelIds
          AND m.activeStatus = :status
        """)
List<Material> findByProductModelIdInAndActiveStatusFetchTypeAndUnit(
        Collection<Long> productModelIds, ActiveStatus status);
```

父件格子：从该款 fashion variant 列表按 `colorId` / `productSizeId` 入 Map，再在内存判 `isManufactured` / `ACTIVE`。  
匹配行：从种子 `productModelId` 的家族 List 按 §3.3 过滤。0 / 1 / >1 → `UNRESOLVED` / `RESOLVED` / `CONFLICT`。

**不要**为「分类 + 颜色」加查询。  
**不要**用 `COALESCE(color_id, 0)` 唯一索引。  
**不要**每格调用现网 `findByProductModelIdAndColorIdAndProductSizeIdAndIsFashionVariantTrue`。

`COLOR_SIZE_MATCH` 命中变体时，现网条件唯一索引保证最多 1 条完整变体；仍用 `List` + 计数，避免漏掉「同款同色同码但 `is_fashion_variant = false`」的 OEM 料造成双命中。

EXISTS：一次查出本批 version，不要 200 次 `exists`：

```java
// BillOfMaterialRepository 本波补
List<BillOfMaterial> findAllByProductMaterialIdInAndVersion(
        Collection<Long> productMaterialIds, String version);
```

用量换算（无 SQL）：见 `02` §3.4。`sizeQuantities` 在校验模板时编成 `Map<productSizeId, qty>`（重复键 400）；`productSizeId` 必须 ∈ 本款尺码组。解析行：`resolvedQty = map.getOrDefault(parent.productSizeId, item.quantity)`。

---

## 6. 状态（沿用现网，不新增头状态）

生成只产生 `DRAFT`。其后：

```text
DRAFT ──批准──► APPROVED ──作废──► OBSOLETE
```

与现网 `BomStatus` 一致。格子状态枚举 **不是** 单据状态，禁止写入 `bom_status`。

---

## 7. 模块归属

| 能力 | 模块 |
|------|------|
| `BomGenerateService` / preview / generate | `lychee-erp-pp` |
| 仓储查找补面 | basis：`MaterialRepository` 家族预取（fetch type+unit）；PP：`findAllByProductMaterialIdInAndVersion`。色码池用现网 `ProductModel*` / `ProductSizeGroupItem*` |
| DTO 归属 | 预览行列 / 格子 / 行态 **全部放 PP**。禁止 `lychee-erp-pp` 依赖 `lychee-erp-mm` |
| 枚举 | `lychee-erp-common`：`BomComponentMatchMode`（前端要）；格子/行态可留 PP |
| `RemoteMaterialService` | **不扩**款色码字段 |
| `RemoteBomService` | **不扩**生成 |
| 前端 | `BomGenerateDrawer` + `services/pp/bill-of-material` 两支新函数 |
| 菜单 / 权限码 | 不新增菜单。preview 走 `:read`，generate 走 `:create` |

### 7.1 服务签名（禁止 TODO 空壳）

```java
public interface BomGenerateService {
    BomGeneratePreviewResponse preview(BomGenerateRequest request);

    BomGenerateResponse generate(BomGenerateRequest request);
}
```

`generate` 内部必须调用与 `preview` 相同的解析函数（同一类 package-private 方法），禁止两套 if/else。  
`BillOfMaterialServiceImpl` **不**塞进生成逻辑（头行 CRUD 已经够长）。Controller 两行委托即可。

现网头行 **无** `@OneToMany` 级联，`id` 是 `IDENTITY`。落库必须两阶段、仍在同一事务：

```text
1. saveAll(headers) + flush 一次          // 拿到头 id，并触发 uk_bom_product_version
2. 给各行填 bomId
3. saveAll(items)                         // 不要再每格 flush
```

`DataIntegrityViolationException`（并发撞版本）在 Service 内转 `validation.billOfMaterial.version.duplicate` 或 `validation.bom.generate.concurrent`（400），不要落到全局 409。禁止调用 `createBillOfMaterial` / `createBomItem`。

---

## 8. 旧草稿 / 废方案

| 废稿 | 处理 |
|------|------|
| V1 `copyBom` 设计句 | 本专题作废；代码字段保留默认 `false` |
| 评估稿 P0「同源复制」 | 不做 |
| 评估稿 P2 Super BOM 表 | 不做；需要时另开专题 |
| 给 `bill_of_materials` 加 `product_model_id` | 不做 |
| MRP `MrpSourceType` 之类与本波无关的占位 | 不动 |

无旧表可迁。无 changelog 要 `DROP`。

---

## 9. 落库顺序（实施时）

```text
1. 无 DDL（description 列已在）
2. common：BomComponentMatchMode + EnumController
3. basis：MaterialRepository 按款批量预取（fetch type+unit）
4. pp：DTO、BomGenerateService、Controller 两路由
5. BillOfMaterial Entity 补 description
6. 前端 Drawer + i18n
7. 单测：解析矩阵 + 按码用量 + 生成事务回滚
```

不要在本波改 `schema_tables/PP/bill_of_materials.sql` 结构（除非把已有 `description` 注释写清「生成可写」）。  
不要改 Liquibase master。

---

## 10. 文档对齐（实施时）

- `database/PP_schema_design.md`：补一句「变体成品用按款生成写入 SKU BOM，无款号 BOM 表」
- 本目录与 `20260911-mm-refactor-v1` Wave C：标注 `copyBom` 不作
- 前端 guidelines：向导属页面专属组件，不新建菜单目录

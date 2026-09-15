# 03. Schema 与数据模型

---

## 1. 改动范围

| 表 | 动作 |
|----|------|
| `materials.is_fashion_variant` | **不改列**。改写入规则；补 V2 未执行的存量打标 |
| `material_images` | 保留。迁完后变体行不再持有行 |
| `product_model_images` | **新建**。款色图 |
| `product_model_colors` | 不改。图不 FK 到本表 `id` |
| `material_categories.code_strategy` | 不改 |

DDL 进 Liquibase `lychee-erp/src/main/resources/db/changelog/v1/2026/`；权威副本同步 `schema_tables/MM/product_model_images.sql`。

---

## 2. `product_model_images`

与 `material_images` 同形，拥有者换成款色键。`color_id` 可空（不分色）。

```sql
CREATE TABLE lychee_erp.product_model_images
(
    id                bigserial PRIMARY KEY,
    tenant_id         bigint NOT NULL,
    product_model_id  bigint NOT NULL,
    color_id          bigint NULL,
    file_path         varchar(500) NOT NULL,
    file_name         varchar(255) NULL,
    file_size         bigint NULL,
    is_primary        boolean DEFAULT false,
    created_at        timestamp without time zone NULL,
    updated_at        timestamp without time zone NULL,
    created_by        bigint NULL,
    updated_by        bigint NULL
);

CREATE INDEX idx_product_model_images_tenant_model_color
    ON lychee_erp.product_model_images (tenant_id, product_model_id, color_id);

CREATE UNIQUE INDEX uk_product_model_images_primary_color
    ON lychee_erp.product_model_images (tenant_id, product_model_id, color_id)
    WHERE is_primary = true AND color_id IS NOT NULL;

CREATE UNIQUE INDEX uk_product_model_images_primary_nocolor
    ON lychee_erp.product_model_images (tenant_id, product_model_id)
    WHERE is_primary = true AND color_id IS NULL;

ALTER TABLE lychee_erp.product_model_images
    ADD CONSTRAINT fk_product_model_images_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.product_model_images
    ADD CONSTRAINT fk_product_model_images_model
        FOREIGN KEY (product_model_id) REFERENCES lychee_erp.product_models (id);
ALTER TABLE lychee_erp.product_model_images
    ADD CONSTRAINT fk_product_model_images_color
        FOREIGN KEY (color_id) REFERENCES lychee_erp.colors (id);
ALTER TABLE lychee_erp.product_model_images
    ADD CONSTRAINT fk_product_model_images_created_by
        FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id);
ALTER TABLE lychee_erp.product_model_images
    ADD CONSTRAINT fk_product_model_images_updated_by
        FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id);
```

注释：`款色产品图。仅 is_fashion_variant = true 的物料共享；color_id 空表示本款不分色。`

应用层：同一 (model, color) 第一张图自动 `is_primary = true`；设主图时同键其它行置 false（与现网物料图相同）。

`color_id` 只 FK `colors`，**不** FK `product_model_colors`。与本款色池的一致性由服务层保证（见 02 §3.1）：分色必须 ∈ 本款色；不分色必须 NULL。删本款色或删款号时**不** ON DELETE CASCADE 图片；有图则业务 400，用户先删图。`file_path` 必须是 `product-model/` 前缀对象，禁止与 `material_images.file_path` 相同。

---

## 3. 存量

### 3.1 Wave 1：补刷 `is_fashion_variant`（V2 `0908-002` 未执行段）

**不要改已发布的 0908-002。** 新 changeset 只打标，不碰索引。

规则与 V2 设计 5.3 一致，**不要**把 MANUAL 上仅有款号的行刷成 true：

```sql
WITH RECURSIVE cat_strategy AS (
    SELECT id, parent_id, code_strategy
    FROM lychee_erp.material_categories
    WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.parent_id,
           COALESCE(c.code_strategy, cs.code_strategy)
    FROM lychee_erp.material_categories c
    INNER JOIN cat_strategy cs ON c.parent_id = cs.id
)
UPDATE lychee_erp.materials m
SET is_fashion_variant = true
FROM cat_strategy cs
WHERE m.material_category_id = cs.id
  AND cs.code_strategy = 'FASHION_VARIANT'
  AND m.product_model_id IS NOT NULL
  AND m.product_size_id IS NOT NULL
  AND m.is_fashion_variant = false;
```

若刷完后条件唯一索引报错：同款色码两颗都在变体分类下——预检列出，人工先合并/停用，再执行 UPDATE。这是 V1 无索引时的脏数据，不是本专题新引入的。

### 3.2 Wave 2：存量变体 SKU 图一次性迁入款色表

仅针对 **脚本执行当时** 已是 `is_fashion_variant = true` 且仍挂在 `material_images` 上的行。这是切断旧源的一次性 ETL，**不是**运行时从物料反写款色（勾选 true 禁止 copy）。

**必须搬 OSS。** 不得让新表 `file_path` 继续指向 `{tenant}/material/{skuCode}/...`。

1. **预检**：同一 `(tenant_id, product_model_id, color_id)` 下多个 SKU 的 primary 不同 → 列出，默认 `min(material_id)` 作主图，其余作非主图。`color_id` 须已在本款色池，否则列入异常、不静默迁入。
2. **按张 copy** 到 `{tenant}/product-model/{modelCode}/{colorId|nocolor}/{新文件名}`，确认可读。
3. **插入** `product_model_images`，`file_path` **只写新路径**。
4. 新行齐了之后：删已迁变体上的 `material_images` 行，再删 **旧** OSS。copy 失败则保留旧行，可重跑。
5. 当时注记 `false` 的 `material_images` **不迁**（勾选 true 也不会自动并入）。

之后运行时：true 只读写款色表。

---

## 4. DTO

`MaterialRequest` 增加：

```java
/** 非变体分类下是否占用款色码格子。变体分类由服务端强制 true，忽略此字段。 */
private Boolean isFashionVariant;
```

`MaterialResponse.isFashionVariant` 已有，继续回传。

款色图响应可复用 `MaterialImageResponse` 形状，或加 `productModelId` / `colorId`、`materialId` 可空。物料门面 GET 变体图时 `materialId` 仍回当前物料，避免前端列表 key 断裂。

---

## 5. 模块边界

| 能力 | 模块 |
|------|------|
| 注记写入、变体校验、物料图门面 | `lychee-erp-mm` |
| 实体 / 仓储 / `MaterialImageHelper` 解析 | `lychee-erp-basis` |
| FO/SO 取图 | PP/SD 只调 Helper，不查 MM Service |
| 款号本款色图 API | MM `ProductModelController` 或并列 `ProductModelImageController` |

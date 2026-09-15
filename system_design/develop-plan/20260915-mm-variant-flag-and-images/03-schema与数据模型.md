# 03. Schema 与数据模型

---

## 1. 改动范围

| 表 | 动作 |
|----|------|
| `materials.is_fashion_variant` | **不改列、不改写入公式、不做存量打标** |
| `material_images` | 保留。变体 SKU 仍可持有行（回退与单码图） |
| `product_model_images` | **新建**。款色图 |
| `product_model_colors` | 不改。图不 FK 到本表 `id` |
| `material_categories.code_strategy` | 不改 |

DDL 进 Liquibase `lychee-erp/src/main/resources/db/changelog/v1/2026/`；权威副本同步 `schema_tables/MM/product_model_images.sql`。

无 `FASHION_VARIANT` 分类存量，**不**新开 changeset 补刷注记，**不**改已发布的 `0908-002`，**不做** OSS 迁图。

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

注释：`款色产品图。按 (款号, 颜色) 共享，不分尺码；color_id 空表示本款不分色。与 materials.is_fashion_variant 无关。`

应用层：同一 (model, color) 第一张图自动 `is_primary = true`；设主图时同键其它行置 false（与现网物料图相同）。

`color_id` 只 FK `colors`，**不** FK `product_model_colors`。与本款色池的一致性由服务层保证（见 02 §3.1）：分色必须 ∈ 本款色；不分色必须 NULL。删本款色或删款号时**不** ON DELETE CASCADE 图片；有图则业务 400，用户先删图。`file_path` 必须是 `product-model/` 前缀对象，禁止与 `material_images.file_path` 相同。

---

## 3. 存量

**不做。** 现无 `code_strategy = FASHION_VARIANT` 的分类树与待补刷物料；旧图全部留在 `material_images`。用户若要把某色做成共享样图，在本款色抽屉重新上传。运行时禁止 SKU → 款色 copy。

---

## 4. DTO

`MaterialRequest` **不增加** `isFashionVariant`。`MaterialResponse.isFashionVariant` 已有，继续回传（只读，来自落库列）。

款色图响应可复用 `MaterialImageResponse` 形状，或加 `productModelId` / `colorId`；**不要**把款色图的 `id` 伪装成某颗物料的 `material_images.id`。物料图 GET 只返回该 SKU 行。

---

## 5. 模块边界

| 能力 | 模块 |
|------|------|
| 变体尺码组校验、物料图 API（仅 SKU 表） | `lychee-erp-mm` |
| 实体 / 仓储 / `MaterialImageHelper` 解析（款色优先 + SKU 回退） | `lychee-erp-basis` |
| FO/SO 取图 | PP/SD 只调 Helper，不查 MM Service |
| 款号本款色图 API | MM `ProductModelImageController`（或并列于 `ProductModelController`） |

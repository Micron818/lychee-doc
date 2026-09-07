# 03. Schema 设计

> `materials` **不重建**。`materials.code` **保持 varchar(50)**。  
> 尺码组**不**存 SKU 流水。流水在 `product_model_size_codes`，按款+色（色可空）。

---

## 1. 改什么、不改什么

| 对象 | 波次 | 动作 |
|------|------|------|
| `materials.code` | — | **不改** varchar(50) |
| `uk_materials_tenant_variant_color` | A | 部分唯一：款+色+码 |
| `uk_materials_tenant_variant_nocolor` | A | 部分唯一：款+码 且 color IS NULL |
| `product_models` | A | 加 `size_group_id` |
| `product_size_groups` / `_items` | A | **新增**；items **无** sku_code，只有 sequence |
| `product_model_colors` | A | **新增**；`sku_code char(1)`；0 行=不分色 |
| `product_model_size_codes` | A | **新增**；`(款, 色可空, 码) → 01–99` |
| `colors` / `product_sizes` | — | 不改 |

---

## 2. 实体关系

```text
product_size_groups 1───* items *───1 product_sizes     // 只定可选码与从小到大
         ▲
product_models 1───* product_model_colors *───1 colors   // 0 行=SKU 无字母
         │
         └──* product_model_size_codes
                (model, color_id NULLABLE, size) → sku_code 01–99

区分色： code = model.code || '-' || letter || sizeSku     12345-A01
不分色： code = model.code || '-' || sizeSku               12345-01
```

---

## 3. Wave A

### 3.1 长度

不 ALTER `materials.code`。

- 区分色：`char_length(model.code) + 4 <= 50`
- 不分色：`char_length(model.code) + 3 <= 50`

否则 OVERFLOW。款号建议不含 `-`。

### 3.2 变体唯一

上线前分别查重复。

```sql
-- 区分色
CREATE UNIQUE INDEX uk_materials_tenant_variant_color
    ON lychee_erp.materials (tenant_id, product_model_id, color_id, product_size_id)
    WHERE product_model_id IS NOT NULL
      AND color_id IS NOT NULL
      AND product_size_id IS NOT NULL;

-- 不分色（同款同码、无颜色）
CREATE UNIQUE INDEX uk_materials_tenant_variant_nocolor
    ON lychee_erp.materials (tenant_id, product_model_id, product_size_id)
    WHERE product_model_id IS NOT NULL
      AND color_id IS NULL
      AND product_size_id IS NOT NULL;
```

无款或无码的原料不进索引。不要只用「三列皆 NOT NULL」一条索引，否则不分色成品会重复。

### 3.3 尺码组（无 SKU 流水）

```sql
CREATE TABLE lychee_erp.product_size_groups ( /* 同前：code/name/status */ );

CREATE TABLE lychee_erp.product_size_group_items
(
    id              bigserial NOT NULL,
    tenant_id       bigint    NOT NULL,
    size_group_id   bigint    NOT NULL,
    product_size_id bigint    NOT NULL,
    sequence        integer   NOT NULL DEFAULT 0,
    created_at      timestamp NULL,
    updated_at      timestamp NULL,
    created_by      bigint    NULL,
    updated_by      bigint    NULL,
    CONSTRAINT pk_product_size_group_items PRIMARY KEY (id),
    CONSTRAINT uk_size_group_items_group_size UNIQUE (tenant_id, size_group_id, product_size_id)
);
```

`sequence` 决定「谁更小」（生成 01 的依据）。组被款号引用则不可删。

### 3.4 款号绑组

```sql
ALTER TABLE lychee_erp.product_models
    ADD COLUMN size_group_id bigint NULL;
```

生成器要求非空。

### 3.5 本款颜色

```sql
CREATE TABLE lychee_erp.product_model_colors
(
    ...
    sku_code char(1) NOT NULL,
    CONSTRAINT uk_product_model_colors UNIQUE (tenant_id, product_model_id, color_id),
    CONSTRAINT uk_product_model_colors_sku UNIQUE (tenant_id, product_model_id, sku_code),
    CONSTRAINT ck_product_model_colors_sku CHECK (sku_code ~ '^[A-Z]$')
);
```

- 0 行 = 不区分颜色。
- ≥1 行且该款已有物料后，禁止清空到 0 行（反之亦然）。
- 该款该色已有物料时禁止改 `sku_code`。

完整列与 FK 同前一版（id/tenant/model/color/sequence/审计），此处只强调约束。

### 3.6 款×色尺码流水

```sql
CREATE TABLE lychee_erp.product_model_size_codes
(
    id               bigserial NOT NULL,
    tenant_id        bigint    NOT NULL,
    product_model_id bigint    NOT NULL,
    color_id         bigint    NULL,
    product_size_id  bigint    NOT NULL,
    sku_code         char(2)   NOT NULL,
    created_at       timestamp NULL,
    updated_at       timestamp NULL,
    created_by       bigint    NULL,
    updated_by       bigint    NULL,
    CONSTRAINT pk_product_model_size_codes PRIMARY KEY (id),
    CONSTRAINT ck_pmsc_sku CHECK (sku_code ~ '^[0-9]{2}$' AND sku_code <> '00')
);

-- color_id NULL 时用 0 占位（色卡 id 从 1 起）
CREATE UNIQUE INDEX uk_pmsc_size
    ON lychee_erp.product_model_size_codes
    (tenant_id, product_model_id, COALESCE(color_id, 0), product_size_id);
CREATE UNIQUE INDEX uk_pmsc_sku
    ON lychee_erp.product_model_size_codes
    (tenant_id, product_model_id, COALESCE(color_id, 0), sku_code);

ALTER TABLE lychee_erp.product_model_size_codes
    ADD CONSTRAINT fk_pmsc_model FOREIGN KEY (product_model_id)
        REFERENCES lychee_erp.product_models (id);
ALTER TABLE lychee_erp.product_model_size_codes
    ADD CONSTRAINT fk_pmsc_color FOREIGN KEY (color_id)
        REFERENCES lychee_erp.colors (id);
ALTER TABLE lychee_erp.product_model_size_codes
    ADD CONSTRAINT fk_pmsc_size FOREIGN KEY (product_size_id)
        REFERENCES lychee_erp.product_sizes (id);
```

生成服务写入。已有对应物料后禁止改 `sku_code`、禁止删行。

区分色时 `color_id` NOT NULL；不分色时必须 NULL。

---

## 4. Wave B / C

同前：打印用组内 `sequence`；copy-from 颜色字母重分配；从属表不改结构。

---

## 5. 格子状态

`NEW|EXISTS|CODE_CONFLICT|OVERFLOW|MISSING_TOKEN` 不落库。

---

## 6. 同步清单

| 产物 | Wave A |
|------|--------|
| `materials.sql` | 两条部分唯一索引 |
| `product_models.sql` | `size_group_id` |
| `product_size_groups.sql` / `_items.sql` | 新建，items 无 sku_code |
| `product_model_colors.sql` | 新建 |
| `product_model_size_codes.sql` | 新建 |
| OpenAPI | preview/generate + 组/款色 |

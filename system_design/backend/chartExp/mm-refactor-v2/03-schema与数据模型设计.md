# 03. Schema 与数据模型设计

---

## 1. 改动范围与向下兼容性原则

```text
┌────────────────────────────────────────────────────────────────────────┐
│                              改动范围总览                              │
├──────────────────────────────┬─────────────────────────────────────────┤
│ 表名                         │ 动作                                    │
├──────────────────────────────┼─────────────────────────────────────────┤
│ lychee_erp.material_categories│ ALTER: 扩展编码策略与轻量序列字段 (ADD) │
│ lychee_erp.materials         │ DROP INDEX: 移除 V1 硬性物理部分唯一索引│
│                              │ 解耦至策略服务与流水表排他 (保持code v50)│
│ lychee_erp.sys_doc_sequence  │ 100% 复用现有高并发原子序列表 (零改动)  │
│ lychee_erp.sys_doc_rule      │ 彻底解耦，不依赖也不侵入该表            │
│ V1 变体生成相关表            │ 不改动 (完整保留款号、尺码组等)          │
└──────────────────────────────┴─────────────────────────────────────────┘
```

1. **零破坏性（Zero Breaking Change）**：
   - 现有的 `materials` 核心字段完全不作修改（保持 `code varchar(50)`）；
   - 移除 V1 在 `materials` 物理表上过度绑定的两条部分唯一索引，解除对 OEM 客供料号及非变体成品的硬性误伤；
2. **渐进式生效（Progressive Enhancement）**：
   - `material_categories.code_strategy` 允许为 `NULL`，为 `NULL` 时按层级向上继承；
   - 未配置任何策略的历史存量顶级分类，系统算法安全回退为 MANUAL（开放手工录入，不强制按变体或流水公式发号）；
3. **架构解耦（Architectural Decoupling）**：
   - 坚决不侵入 `sys_doc_rule`，彻底避免主数据与单据规则的生命周期及字段污染。

---

## 2. DDL 扩展与定义（PostgreSQL）

### 2.1 修改 `material_categories` 表

```sql
-- 1. 扩展字段（自闭环轻量序列属性，不外键依赖 sys_doc_rule）
ALTER TABLE lychee_erp.material_categories
    ADD COLUMN IF NOT EXISTS code_strategy varchar(30) NULL,
    ADD COLUMN IF NOT EXISTS code_prefix varchar(20) NULL,
    ADD COLUMN IF NOT EXISTS seq_length integer NULL,
    ADD COLUMN IF NOT EXISTS date_format varchar(20) NULL,
    ADD COLUMN IF NOT EXISTS is_seq_shared boolean NOT NULL DEFAULT false;

-- 2. 字段业务注释与合法性约束
ALTER TABLE lychee_erp.material_categories
    DROP CONSTRAINT IF EXISTS ck_material_categories_strategy;
ALTER TABLE lychee_erp.material_categories
    ADD CONSTRAINT ck_material_categories_strategy 
    CHECK (code_strategy IS NULL OR code_strategy IN ('FASHION_VARIANT', 'SEQUENTIAL', 'MANUAL'));

ALTER TABLE lychee_erp.material_categories
    DROP CONSTRAINT IF EXISTS ck_material_categories_shared;
ALTER TABLE lychee_erp.material_categories
    ADD CONSTRAINT ck_material_categories_shared 
    CHECK (NOT (parent_id IS NULL AND is_seq_shared = true));

COMMENT ON COLUMN lychee_erp.material_categories.code_strategy IS 
    '编码策略: FASHION_VARIANT(款色码变体), SEQUENTIAL(序列流水号), MANUAL(手工输入). 为空则继承父分类';

COMMENT ON COLUMN lychee_erp.material_categories.code_prefix IS 
    '自定义编码前缀 (仅限大写英文字母、数字及连字符，如 FAB, MAT-01). 若为空则默认使用分类自身 code 作为流水号前缀';

COMMENT ON COLUMN lychee_erp.material_categories.seq_length IS 
    '流水号长度 (补零位宽). 数据库允许为空以支持向上继承，全链为空时由系统服务默认 5 位';

COMMENT ON COLUMN lychee_erp.material_categories.date_format IS 
    '可选日期掩码 (如 yyMM). 主数据建议为空 (避免跨年断号/重置)';

COMMENT ON COLUMN lychee_erp.material_categories.is_seq_shared IS 
    '是否与上级号池属主共用同一流水号池 (true 时 seq_key 锚定号池属主分类 ID)';

-- 3. 索引优化 (用于树状策略继承递归查询)
CREATE INDEX IF NOT EXISTS idx_material_categories_strategy 
    ON lychee_erp.material_categories (tenant_id, code_strategy)
    WHERE code_strategy IS NOT NULL;
```

### 2.2 解除 `materials` 表上的硬性变体唯一索引（解耦至策略层）

V1 版本在 `materials` 表上创建了两条部分唯一索引：
* `uk_materials_tenant_variant_color (tenant_id, product_model_id, color_id, product_size_id)`
* `uk_materials_tenant_variant_nocolor (tenant_id, product_model_id, product_size_id)`

#### 为什么必须在 V2 移除？
1. **DB 物理索引无法感知业务策略**：PostgreSQL 索引的 `WHERE` 条件无法跨表感知 `material_categories.code_strategy`。只要物料挂载了款号和尺码，无论走什么策略，数据库一律强制拒绝重复；
2. **严重破坏 OEM / 客户指定料号场景（MANUAL 策略死局）**：代工厂客户 A 和客户 B 订购同一款版型的尺码 40，客户 A 要求编码为 `NIKE-40`，客户 B 要求编码为 `ADIDAS-40`。两笔物料具有相同的 `(product_model_id, product_size_id)` 但不同的 `code`，V1 的硬性索引会直接阻断第二笔保存；
3. **标品周边配件受限**：同一款号下的配件周边等标品物料（非变体）受到无差别的变体排他限制。

#### 移除后的唯一性与并发安全保障机制：
移除 `materials` 上的硬性约束后，标准 ERP（如 SAP）的做法是：**「物理表保留 `UNIQUE(tenant_id, code)` 作为全局兜底，变体排他性由业务策略服务与全局唯一索引双重保障」**：
1. **上线依赖约束（安全红线）**：
   **严禁在波次 1 中孤立执行 DROP INDEX！** 移除这两条索引必须与波次 2 的「后端策略路由工厂及多策略保存逻辑」同步上线。在策略服务就绪前，物理索引是现有生产环境防止变体撞车的最后一道硬防线。
2. **`FASHION_VARIANT` 场景下的双保险机制**：
   - 业务防线：`FashionVariantCodeGenerator` 在落库前调用 `assertVariantUnique()` 严格查重，并限制尺码属于款号绑定的尺码组；
   - 并发兜底：由于变体物料编码严格由公式生成（如 `A12345-A01`），两笔并发请求即便同时绕过 Java 查重，第二笔也必然被 `materials` 表的 `uk_materials_tenant_code` 唯一约束拦截并抛出并发冲突，绝不可能产生重复变体物料。
3. **`MANUAL` 和 `SEQUENTIAL` 策略赋能**：
   - 跳过 `assertVariantUnique`，仅校验 `code` 唯一性，赋能 OEM 代工与配件标品。

```sql
-- DDL 执行：移除 materials 上的硬性物理唯一索引 (必须与波次 2 后端业务策略同批次发布)
DROP INDEX IF EXISTS lychee_erp.uk_materials_tenant_variant_color;
DROP INDEX IF EXISTS lychee_erp.uk_materials_tenant_variant_nocolor;
```

---

## 3. 枚举与数据传输对象定义（Java / TypeScript）

### 3.1 后端 Java 枚举（`CodingStrategyEnum`）

```java
package com.lychee.erp.mm.enums;

import lombok.Getter;

@Getter
public enum CodingStrategyEnum {
    /**
     * 鞋服款色码变体矩阵策略 (A12345-A01 / A12345-01)
     * 依赖 product_models, colors, product_sizes
     */
    FASHION_VARIANT("款色码变体"),

    /**
     * 分类前缀序列流水号策略 (FAB-00042 或 FAB-2609-00042)
     * 依赖 material_categories 配置与 sys_doc_sequence 原子发号
     */
    SEQUENTIAL("序列流水号"),

    /**
     * 外部手工录入 / 客户指定料号策略
     * 前端开放输入，后端校验唯一性
     */
    MANUAL("手工录入");

    private final String description;

    CodingStrategyEnum(String description) {
        this.description = description;
    }
}
```

### 3.2 前端 TypeScript 类型

```typescript
export type CodingStrategy = 'FASHION_VARIANT' | 'SEQUENTIAL' | 'MANUAL';

export interface EffectiveCodingPolicy {
  strategy: CodingStrategy;
  sourceCategoryId: number;       // 策略由哪一级分类继承而来
  sourceCategoryName?: string;
  codePrefix?: string;
  seqLength?: number;
  dateFormat?: string;
  isSeqShared?: boolean;
  seqScopeCategoryId: number;     // 物理流水池锚定分类 ID (seq_key 归宿)
  categoryId: number;             // 当前分类 ID
  categoryCode: string;           // 当前分类代码
}
```

### 3.3 Bean Validation 与 DTO 改造规格（解决空 Code 契约冲突）

现网 `MaterialRequest.java` 中对编码字段标注了 `@NotBlank(message = "{validation.material.code.required}")`。若前端在 `SEQUENTIAL` 策略下传空 `code`，请求会在进入 Controller 前被 Spring MVC 的 `@Valid` 机制直接拦截并报 400 校验错误。

**解决方案**：
1. **DTO 注解调整**：将 `MaterialRequest.code` 上的 `@NotBlank` 降级为 `@Size(max = 50)`，不再强求入参必须非空；
2. **策略层动态校验**：
   - 当策略为 `MANUAL`：`ManualCodeGenerator.validate()` 强行要求 `StringUtils.hasText(request.getCode())`，为空时抛出 `validation.material.code.required`；
   - 当策略为 `FASHION_VARIANT`：若传入了 `code`，校验其是否符合生成公式；若为空，则由生成器自动生成回填；
   - 当策略为 `SEQUENTIAL`：允许 `code` 为空，保存前自动调用发号器分配流水；若显式手填了 `code`，则原样校验唯一性。

---

## 4. 物料分类流水与 `sys_doc_rule` 的深度架构对比与设计定型

在评估系统既有的号码生成机制时，我们对 `sys_doc_rule` 进行了深度源码与 DDL 审查。

### 4.1 为什么必须放弃沿用 `sys_doc_rule`？

| 冲突维度 | `sys_doc_rule` 现状 | 物料主数据分类编码诉求 | 强套导致的严重缺陷 |
| :--- | :--- | :--- | :--- |
| **1. 领域模型与类型** | `rule_code` 强绑定 Java 枚举 `DocumentTypeEnum` | 分类由租户在运行时动态增删改，多达数十上百个 | **致命矛盾**：不可能每次新增一个物料分类就改代码加 Java 枚举。 |
| **2. 唯一索引与流水池** | `uk_sys_doc_rule UNIQUE (tenant_id, rule_code)` | 各个物料分类需要独立、连续的递增序列 | 若只配一个 `MATERIAL` 规则，**所有分类被迫共用同一个流水池**：面料佔 1、拉鍊佔 2、面料再建變 3，號碼跳躍無法連續。 |
| **3. 重置週期生命週期** | 內置 `reset_type` (DAILY / MONTHLY / YEARLY) | 物料編碼是資產永久唯一標識，**嚴禁任何跨期重置** | 單據重置邏輯可能導致次年元旦流水重置，造成物料編碼大面積撞號衝突。 |
| **4. 單據專用欄位冗餘** | 包含 `item_first_no`, `item_step`, `is_item_manual_edit` | 物料主檔是單頭資產，根本沒有明細行項與插單概念 | 產生嚴重的欄位語義污染與模型腐化。 |

---

### 4.2 推薦架構：分類表自閉環 + 複用 `sys_doc_sequence` 原子序列表

**核心設計**：
不使用 `sys_doc_rule`，規則屬性（前綴、長度、日期掩碼、共用標記）直接內聚在 `material_categories` 樹中；
**流水計數器 100% 複用現有的 `sys_doc_sequence` 高並發原子表**，通過規範化 `seq_key` 實現物理隔離。

```text
┌────────────────────────────────────────────────────────┐
│              material_categories (物料分類)             │
│  - code_prefix: 'FAB'                                  │
│  - seq_length: 5                                       │
│  - date_format: null (或 'yyMM')                       │
│  - is_seq_shared: false                                │
└──────────────────────────┬─────────────────────────────┘
                           │ 決定 seqKey
                           ▼
┌────────────────────────────────────────────────────────┐
│            sys_doc_sequence (原子遞增序列表)           │
│  - tenant_id: 1                                        │
│  - seq_key: 'MATERIAL_CAT:105'                         │
│  - current_value: 42                                   │
└────────────────────────────────────────────────────────┘
                           │ ON CONFLICT RETURNING
                           ▼
           最终物料编码: "FAB-00042" (原子自增保证全局唯一)
```

#### `seq_key` 生成规则：
1. **独立计数模式（默认，`is_seq_shared = false`）**：
   $$\text{seq\_key} = \text{"MATERIAL\_CAT:"} + \text{categoryId}$$
   * 范例：面料大类（ID=10）为 `MATERIAL_CAT:10`，拉链大类（ID=20）为 `MATERIAL_CAT:20`。两者计数器彻底隔离，各自从 1 开始连续递增。
2. **共用上级流水模式（`is_seq_shared = true` 且存在父级）**：
   $$\text{seq\_key} = \text{"MATERIAL\_CAT:"} + \text{seqScopeCategoryId}$$
   * 范例：梭织面料（ID=101）与针织面料（ID=102）勾选共用流水，发号时统一锚定上级面料大类（ID=10）的流水池，共享总序列。该 ID 由策略解析算法统一追溯计算得出。

---

## 5. 存量历史数据平滑迁移与上线安全指南

为确保上线时不破坏老系统既有逻辑，迁移应遵循**「数据预检 -> 显式白名单打标 -> 安全兜底回退」**的稳妥步骤：

### 5.1 上线前预检脚本（审查分类及其物料形态）

```sql
-- 预检 1: 统计各顶级分类及其下属物料的变体特征 (帮助运营与实施人员确认品类性质)
SELECT 
    c.id AS category_id,
    c.code AS category_code,
    c.name AS category_name,
    COUNT(m.id) AS total_materials,
    COUNT(CASE WHEN m.product_model_id IS NOT NULL AND m.product_size_id IS NOT NULL THEN 1 END) AS fashion_variant_count,
    COUNT(CASE WHEN m.product_model_id IS NULL AND m.color_id IS NULL AND m.product_size_id IS NULL THEN 1 END) AS standard_sku_count
FROM lychee_erp.material_categories c
LEFT JOIN lychee_erp.materials m ON m.material_category_id = c.id
WHERE c.level = 1
GROUP BY c.id, c.code, c.name
ORDER BY c.code;
```

### 5.2 生产平滑迁移脚本（按明确代码白名单打标）

严禁使用模糊匹配（如 `LIKE '%鞋%'`），避免多语言（如英文、越南文）环境误伤或将鞋垫、鞋盒等包装辅料误判为鞋服变体。

```sql
-- 1. 服装成衣/鞋靴类 (鞋服变体矩阵)
UPDATE lychee_erp.material_categories
SET code_strategy = 'FASHION_VARIANT'
WHERE level = 1 
  AND code IN ('APP', 'SHOE', 'CLOTH', 'GARMENT', 'FOOTWEAR')
  AND code_strategy IS NULL;

-- 2. 原材料与辅料类 (序列流水号，默认 5 位流水，分类 code 作为前缀)
UPDATE lychee_erp.material_categories
SET code_strategy = 'SEQUENTIAL',
    seq_length = 5
WHERE level = 1 
  AND code IN ('FAB', 'ACC', 'ROH', 'TRIM', 'PKG', 'RAW_MAT')
  AND code_strategy IS NULL;

-- 3. 定制加工/客供料/外协类 (手工录入)
UPDATE lychee_erp.material_categories
SET code_strategy = 'MANUAL'
WHERE level = 1 
  AND code IN ('OEM', 'ODM', 'CUST', 'EXT')
  AND code_strategy IS NULL;

-- 4. 其余未显式打标的存量顶级分类：
-- 保持 code_strategy IS NULL，由系统算法安全回退为 MANUAL (避免未知品类被系统强行按照错误前缀分配流水号)
```

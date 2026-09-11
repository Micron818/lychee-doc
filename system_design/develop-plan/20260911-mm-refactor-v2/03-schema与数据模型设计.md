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
│ lychee_erp.materials         │ ALTER: 增加物化策略标记列 is_fashion_variant (ADD) │
│                              │ REFACTOR INDEX: 将 V1 硬性无条件索引重构为精细条件部分唯一索引 (保持code v50)│
│ lychee_erp.sys_doc_sequence  │ 100% 复用现有高并发原子序列表 (零改动)  │
│ lychee_erp.sys_doc_rule      │ 彻底解耦，不依赖也不侵入该表            │
│ V1 变体生成相关表            │ 不改动 (完整保留款号、尺码组等)          │
└──────────────────────────────┴─────────────────────────────────────────┘
```

1. **零破坏性（Zero Breaking Change）**：
   - 现有的 `materials` 核心字段完全不作修改（保持 `code varchar(50)`）；
   - 将 V1 在 `materials` 物理表上过度绑定的两条硬性部分唯一索引重构为精准条件索引，解除对 OEM 客供料号及非变体成品的误伤，同时不牺牲变体排他底线；
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

ALTER TABLE lychee_erp.material_categories
    DROP CONSTRAINT IF EXISTS ck_material_categories_seq_length;
ALTER TABLE lychee_erp.material_categories
    ADD CONSTRAINT ck_material_categories_seq_length
    CHECK (seq_length IS NULL OR (seq_length >= 2 AND seq_length <= 10));

ALTER TABLE lychee_erp.material_categories
    DROP CONSTRAINT IF EXISTS ck_material_categories_prefix;
ALTER TABLE lychee_erp.material_categories
    ADD CONSTRAINT ck_material_categories_prefix
    CHECK (code_prefix IS NULL OR code_prefix ~ '^[A-Z0-9_-]{1,20}$');

COMMENT ON COLUMN lychee_erp.material_categories.code_strategy IS 
    '编码策略: FASHION_VARIANT(款色码变体), SEQUENTIAL(序列流水号), MANUAL(手工输入). 为空则继承父分类';

COMMENT ON COLUMN lychee_erp.material_categories.code_prefix IS 
    '自定义编码前缀 (仅限大写英文字母、数字及连字符，如 FAB, MAT-01). 若为空则默认使用分类自身 code 作为流水号前缀';

COMMENT ON COLUMN lychee_erp.material_categories.seq_length IS 
    '流水号长度 (补零位宽 2~10 位). 数据库允许为空以支持向上继承，全链为空时由系统服务默认 5 位';

COMMENT ON COLUMN lychee_erp.material_categories.date_format IS 
    '可选静态日期掩码 (如 yyMM). 主数据建议为空 (主数据跨期永不重置)';

COMMENT ON COLUMN lychee_erp.material_categories.is_seq_shared IS 
    '是否与上级号池属主共用同一流水号池 (true 时 seq_key 锚定号池属主分类 ID)';

-- 3. 索引优化 (用于树状策略继承递归查询)
CREATE INDEX IF NOT EXISTS idx_material_categories_strategy 
    ON lychee_erp.material_categories (tenant_id, code_strategy)
    WHERE code_strategy IS NOT NULL;
```

### 2.2 重构 `materials` 表变体部分唯一索引（物化分流）

V1 版本在 `materials` 表上创建了两条无条件的部分唯一索引：
* `uk_materials_tenant_variant_color (tenant_id, product_model_id, color_id, product_size_id)`
* `uk_materials_tenant_variant_nocolor (tenant_id, product_model_id, product_size_id)`

#### 为什么不能直接裸 DROP 索引？
若单纯直接 `DROP INDEX` 并完全交由 Java 代码 `SELECT` 查重，存在显著风险：
1. **款号变更后防线失守**：若款号 `code` 发生更名修改，变体生成的物料编码随之改变，失去 `UNIQUE(tenant_id, code)` 的兜底效果，可能并发插入完全相同款色码的物料；
2. **高并发竞争漏洞**：若两笔请求并发到达且越过应用层查询，没有数据库唯一索引作底线，将产生变体三维重复的脏数据。

#### 优雅方案：物化策略列（`is_fashion_variant`）+ 条件唯一索引
我们通过在 `materials` 增加物化标记列，将无条件索引精准重构为条件索引：

```sql
-- 1. materials 增加物化策略列 (默认 false，仅变体物料落库/生成时写入 true)
ALTER TABLE lychee_erp.materials
    ADD COLUMN IF NOT EXISTS is_fashion_variant boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN lychee_erp.materials.is_fashion_variant IS
    '物化标记: 所属物料分类是否生效 FASHION_VARIANT 变体策略 (用于变体子系统索引与查询分流)';

CREATE INDEX IF NOT EXISTS idx_materials_fashion_variant
    ON lychee_erp.materials (tenant_id, is_fashion_variant, product_model_id);

-- 2. 移除 V1 无条件物理索引
DROP INDEX IF EXISTS lychee_erp.uk_materials_tenant_variant_color;
DROP INDEX IF EXISTS lychee_erp.uk_materials_tenant_variant_nocolor;

-- 3. 重建为精细化变体条件唯一索引 (仅对变体物料生效，OEM与标品物料完全不进该索引)
CREATE UNIQUE INDEX uk_materials_tenant_fashion_variant_color
    ON lychee_erp.materials (tenant_id, product_model_id, color_id, product_size_id)
    WHERE is_fashion_variant = true
      AND product_model_id IS NOT NULL
      AND color_id IS NOT NULL
      AND product_size_id IS NOT NULL;

CREATE UNIQUE INDEX uk_materials_tenant_fashion_variant_nocolor
    ON lychee_erp.materials (tenant_id, product_model_id, product_size_id)
    WHERE is_fashion_variant = true
      AND product_model_id IS NOT NULL
      AND color_id IS NULL
      AND product_size_id IS NOT NULL;
```

#### 重构收益：
1. **上线依赖约束（安全红线）**：
   此 DDL 必须与波次 2 后端业务策略同批次发布；
2. **变体物料硬防线保留**：
   鞋服变体（`is_fashion_variant = true`）依然在数据库层面享受绝对唯一性保护；
3. **彻底赋能代工与标品**：
   `MANUAL`（客供定制）与 `SEQUENTIAL`（标品）物料写入时 `is_fashion_variant = false`，不进入该部分索引，即使款号尺码相同也绝不会被拦截！

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
  codePrefix?: string;           // 原始配置的前缀
  effectivePrefix: string;       // 计算继承/属主后的最终生效前缀 (用于前端提示与展示)
  seqLength: number;             // 最终生效位宽 (默认 5)
  dateFormat?: string;
  isSeqShared: boolean;
  seqScopeCategoryId: number;     // 物理流水池锚定分类 ID (seq_key 归宿)
  categoryId: number;             // 当前分类 ID
  categoryCode: string;           // 当前分类代码
}
```

### 3.3 实体与 DTO 改造规格（解决物化列与空 Code 契约冲突）

1. **`Material.java` 实体扩展**：
   ```java
   @Column(name = "is_fashion_variant", nullable = false)
   private Boolean isFashionVariant = false;
   ```
2. **Bean Validation 注解降级**：
   现网 `MaterialRequest.java` 中对编码字段标注了 `@NotBlank(message = "{validation.material.code.required}")`。将 `MaterialRequest.code` 上的 `@NotBlank` 降级为 `@Size(max = 50)`，不再强求入参必须非空；
3. **策略层动态校验与物化标记写入**：
   - 当策略为 `MANUAL`：`ManualCodeGenerator.validate()` 强行要求 `StringUtils.hasText(request.getCode())`，为空时抛出 `validation.material.code.required`，落库时 `entity.setIsFashionVariant(false)`；
   - 当策略为 `FASHION_VARIANT`：前端通过款式色码动态回填建议编码，保存时由发号器严格核验并落库流水，落库时 `entity.setIsFashionVariant(true)`；
   - 当策略为 `SEQUENTIAL`：允许 `code` 为空，保存前自动调用发号器分配流水，落库时 `entity.setIsFashionVariant(false)`。

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

为确保上线时不破坏老系统既有逻辑，迁移应遵循**「数据预检 -> 显式打标 -> 物料物化列补齐 -> 号池流水种子初始化 -> 索引无缝切换」**的严密步骤：

### 5.1 上线前预检脚本（审查分类树及其物料形态）

> **关键修正**：ERP 物料往往挂接在末级子分类上。预检脚本必须使用递归 CTE 将全部下级子分类的物料汇总到顶级分类，杜绝顶级分类统计显示 0 笔的误导。

```sql
-- 预检 1: 递归汇总各顶级大类及其全树枝叶物料的变体特征分布
WITH RECURSIVE cat_tree AS (
    -- 锚点：所有顶级分类
    SELECT id AS root_id, id AS current_id, code AS root_code, name AS root_name
    FROM lychee_erp.material_categories
    WHERE parent_id IS NULL
    UNION ALL
    -- 递归向下展开子孙分类
    SELECT ct.root_id, c.id, ct.root_code, ct.root_name
    FROM lychee_erp.material_categories c
    INNER JOIN cat_tree ct ON c.parent_id = ct.current_id
)
SELECT 
    ct.root_id,
    ct.root_code,
    ct.root_name,
    COUNT(m.id) AS total_materials,
    COUNT(CASE WHEN m.product_model_id IS NOT NULL AND m.product_size_id IS NOT NULL THEN 1 END) AS fashion_variant_count,
    COUNT(CASE WHEN m.product_model_id IS NULL AND m.product_size_id IS NULL THEN 1 END) AS standard_sku_count
FROM cat_tree ct
LEFT JOIN lychee_erp.materials m ON m.material_category_id = ct.current_id
GROUP BY ct.root_id, ct.root_code, ct.root_name
ORDER BY ct.root_code;
```

```sql
-- 预检 2 (安全红线门禁): 检查是否有存量具有款号与尺码的变体物料，但挂在有效策略非 FASHION_VARIANT 的分类下
-- 必须使用递归 CTE 解析分类继承的最终有效策略 (避免因子分类未直接设策略 code_strategy IS NULL 造成误漏)
WITH RECURSIVE cat_strategy AS (
    SELECT id, parent_id, code_strategy, code, name
    FROM lychee_erp.material_categories
    WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.parent_id, 
           COALESCE(c.code_strategy, cs.code_strategy) AS code_strategy,
           c.code, c.name
    FROM lychee_erp.material_categories c
    INNER JOIN cat_strategy cs ON c.parent_id = cs.id
)
SELECT m.id, m.code, m.name, cs.code AS cat_code, cs.name AS cat_name, cs.code_strategy AS effective_strategy
FROM lychee_erp.materials m
JOIN cat_strategy cs ON m.material_category_id = cs.id
WHERE m.product_model_id IS NOT NULL 
  AND m.product_size_id IS NOT NULL
  AND cs.code_strategy IS DISTINCT FROM 'FASHION_VARIANT';
```

> **门禁性质与执行机制（发布流程人工/流水线硬卡点）**：
> 特别说明：此预检是 **发布流程与运维部署的硬性门禁（Gating Check）**，由 DBA、运维实施人员或 CI/CD 部署流水线在触发 Liquibase 迁移前显式执行校验。**Liquibase changeset 本身为纯 SQL 执行器，不会因 SELECT 结果自动报错终止**，因此防线必须设在发布执行前。
> 
> **发布操作前置规范**：
> 1. 在生产/测试环境执行 `0908-002` 脚本前，必须先在目标库手动或通过 CI 脚本运行预检 2 查询；
> 2. 凡确认属于企业自制成衣/鞋靴变体的物料，必须追溯其分类链并在祖先分类上显式打标为 `FASHION_VARIANT`，确保其在迁移时被正确刷为 `is_fashion_variant = true` 并进入精准变体索引保护；
> 3. 仅当确认属于 OEM 客户指定料号或代工定制时，将相关物料 ID 录入发布审批白名单，其余非白名单物料记录数**必须严格为 0**；
> 4. **若预检 2 存在未归正的非白名单物料，部署流水线必须立刻中止，严禁触发 `0908-002` 执行**，防止变体物料因分类漏标而失守三维排他防线。

### 5.2 生产平滑迁移与打标脚本

```sql
-- 1. 服装成衣/鞋靴类 (鞋服变体矩阵)
UPDATE lychee_erp.material_categories
SET code_strategy = 'FASHION_VARIANT'
WHERE parent_id IS NULL
  AND code IN ('APP', 'SHOE', 'CLOTH', 'GARMENT', 'FOOTWEAR')
  AND code_strategy IS NULL;

-- 2. 原材料与辅料类 (序列流水号，默认 5 位流水，分类 code 作为默认前缀)
UPDATE lychee_erp.material_categories
SET code_strategy = 'SEQUENTIAL',
    seq_length = 5
WHERE parent_id IS NULL
  AND code IN ('FAB', 'ACC', 'ROH', 'TRIM', 'PKG', 'RAW_MAT')
  AND code_strategy IS NULL;

-- 3. 定制加工/客供料/外协类 (手工录入)
UPDATE lychee_erp.material_categories
SET code_strategy = 'MANUAL'
WHERE parent_id IS NULL
  AND code IN ('OEM', 'ODM', 'CUST', 'EXT')
  AND code_strategy IS NULL;

-- 4. 其余未显式打标的顶级分类保持 NULL (算法安全回退为 MANUAL，避免未知品类强行发号)
```

### 5.3 存量物料物化列补齐（`is_fashion_variant`）

```sql
-- 根据分类有效策略，将所有成衣变体物料的物化列设置为 true (支撑条件唯一索引与切面查询)
WITH RECURSIVE cat_strategy AS (
    SELECT id, parent_id, code_strategy, id AS root_id
    FROM lychee_erp.material_categories
    WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.parent_id, 
           COALESCE(c.code_strategy, cs.code_strategy) AS code_strategy,
           cs.root_id
    FROM lychee_erp.material_categories c
    INNER JOIN cat_strategy cs ON c.parent_id = cs.id
)
UPDATE lychee_erp.materials m
SET is_fashion_variant = true
FROM cat_strategy cs
WHERE m.material_category_id = cs.id
  AND cs.code_strategy = 'FASHION_VARIANT'
  AND m.product_model_id IS NOT NULL
  AND m.product_size_id IS NOT NULL;
```

### 5.4 流水号池种子数据初始化（Seed `sys_doc_sequence`，防止重号）

> **必须执行！** 若已有物料存在如 `FAB-00042`，新建物料若计数器从 1 开始分配，系统重试 3 次后立刻报主键/编码冲突。
> **关键设计**：初始化脚本必须使用递归 CTE **完整解析分类树的继承策略与号池属主（`seq_scope_category_id`）**，确保挂载在叶子分类上的存量物料、以及配置了 `is_seq_shared=true` 共享号池的分类，其流水能够准确汇总并初始化到正确的号池键（`MATERIAL_CAT:{seqScopeCategoryId}`）：

```sql
-- 针对生效策略为 SEQUENTIAL 的分类及其号池，从存量物料中提取最大流水号初始化
WITH RECURSIVE cat_tree AS (
    -- 锚点: 所有顶级分类 (根节点 is_seq_shared 恒为 false，号池属主即为自身)
    SELECT 
        id, 
        parent_id, 
        code_strategy AS effective_strategy,
        id AS seq_scope_category_id
    FROM lychee_erp.material_categories
    WHERE parent_id IS NULL
    UNION ALL
    -- 递归向下展开子孙分类，推导继承策略与号池属主
    SELECT 
        c.id, 
        c.parent_id, 
        COALESCE(c.code_strategy, ct.effective_strategy) AS effective_strategy,
        CASE 
            WHEN c.is_seq_shared = true THEN ct.seq_scope_category_id
            ELSE c.id
        END AS seq_scope_category_id
    FROM lychee_erp.material_categories c
    INNER JOIN cat_tree ct ON c.parent_id = ct.id
)
INSERT INTO lychee_erp.sys_doc_sequence (tenant_id, seq_key, current_value)
SELECT 
    m.tenant_id,
    'MATERIAL_CAT:' || ct.seq_scope_category_id AS seq_key,
    COALESCE(MAX(
        CASE 
            WHEN m.code ~ '^[A-Z0-9_-]+-([0-9]+)$' 
            THEN CAST(SUBSTRING(m.code FROM '[0-9]+$') AS BIGINT)
            ELSE 0 
        END
    ), 0) AS current_value
FROM cat_tree ct
JOIN lychee_erp.materials m ON m.material_category_id = ct.id
WHERE ct.effective_strategy = 'SEQUENTIAL'
GROUP BY m.tenant_id, ct.seq_scope_category_id
ON CONFLICT (tenant_id, seq_key) 
DO UPDATE SET current_value = GREATEST(sys_doc_sequence.current_value, EXCLUDED.current_value);
```

### 5.5 Liquibase Changelog 变更规划

遵循工程目录 `lychee-erp/src/main/resources/db/changelog/v1/2026/` 结构：
1. `2026/0908-001-mm-category-coding-policy.sql`（波次 1）：
   - `material_categories` 新增 5 列及 CHECK 约束；
   - 历史顶级分类白名单策略初始化；
2. `2026/0908-002-mm-materials-variant-decouple.sql`（波次 2，与后端业务逻辑同批发布）：
   - **发布流水线前置门禁（CI / DBA 手工卡点）**：
     该 changeset 本身为纯 DDL/DML，不会自动终止于数据异常。因此在流水线触发该文件前，必须由 CI 部署脚本或 DBA 手工执行预检 2 查询，确认异常成衣变体数已清零（或全部纳入 OEM 白名单），方可触发执行；
   - **单事务强一致性保证**：以下所有操作必须在同一个 Liquibase changeset 内以单数据库事务（`runInTransaction: true`）执行，绝不允许出现索引缺失的中间空窗期：
     1. `materials` 增加 `is_fashion_variant` 字段及索引；
     2. 执行递归 CTE，将存量成衣物料 `is_fashion_variant` 刷为 `true`；
     3. 执行递归 CTE，初始化 `sys_doc_sequence` 种子流水号；
     4. `DROP INDEX uk_materials_tenant_variant_color / nocolor`；
     5. `CREATE UNIQUE INDEX uk_materials_tenant_fashion_variant_color / nocolor`。

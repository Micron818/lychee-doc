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
   - 未配置任何策略的历史存量数据，系统安全回退为现网既有逻辑，完全不影响老系统运行；
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
    ADD COLUMN IF NOT EXISTS seq_length integer NULL DEFAULT 5,
    ADD COLUMN IF NOT EXISTS date_format varchar(20) NULL,
    ADD COLUMN IF NOT EXISTS is_seq_shared boolean NOT NULL DEFAULT false;

-- 2. 字段业务注释
COMMENT ON COLUMN lychee_erp.material_categories.code_strategy IS 
    '编码策略: FASHION_VARIANT(款色码变体), SEQUENTIAL(序列流水号), MANUAL(手工输入). 为空则继承父分类';

COMMENT ON COLUMN lychee_erp.material_categories.code_prefix IS 
    '自定义编码前缀. 若为空则默认使用分类自身 code 作为流水号前缀 (如 FAB)';

COMMENT ON COLUMN lychee_erp.material_categories.seq_length IS 
    '流水号长度 (补零位宽)，默认 5 位. 为空则向上继承';

COMMENT ON COLUMN lychee_erp.material_categories.date_format IS 
    '可选日期掩码 (如 yyMM). 主数据建议为空 (避免跨年断号/重置)';

COMMENT ON COLUMN lychee_erp.material_categories.is_seq_shared IS 
    '是否与父分类共用同一流水号池 (true 时 seq_key 锚定父分类)';

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
1. **DB 物理索引无法感知业务策略**：PostgreSQL 索引的 `WHERE` 条件无法跨表感知 `material_categories.code_strategy`。只要物料挂载了款号和尺码，无论走什么策略，資料庫一律強制拒絕重複；
2. **嚴重破壞 OEM / 客戶指定料號場景（MANUAL 策略死局）**：代工廠客戶 A 和客戶 B 訂購同一款版型的尺碼 40，客戶 A 要求編碼為 `NIKE-40`，客戶 B 要求編碼為 `ADIDAS-40`。兩筆物料具有相同的 `(product_model_id, product_size_id)` 但不同的 `code`，V1 的硬性索引會直接阻斷第二筆保存；
3. **樣品/大貨及改版場景受限**：無法在同一款色碼下並存樣品物料與大貨物料。

#### 移除後的唯一性與並發安全保障機制：
移除 `materials` 上的硬性約束後，標準 ERP（如 SAP）的做法是：**「物理表僅保留 `UNIQUE(tenant_id, code)`，變體排他性由業務策略與流水表保障」**：
1. **並發物理排他門禁（流水表已由 DB 鎖死）**：
   在 `FASHION_VARIANT` 策略下，變體生成必須先分配並持久化 `product_model_size_codes` 流水。該表在 V1 中已具備嚴格的四條部分唯一索引（`(tenant_id, product_model_id, color_id, product_size_id)`）。因此，**物理上絕不可能並發生成兩筆相同的變體流水**！
2. **業務領域層校驗（Domain Assertion）**：
   `FashionVariantCodeGenerator` 在落庫前調用 `assertVariantUnique()` 執行查重；而 `MANUAL` 和 `SEQUENTIAL` 策略則跳過該限制，賦予代工與多渠道業務充分的彈性。

```sql
-- DDL 执行：移除 materials 上的硬性物理唯一索引
DROP INDEX IF EXISTS lychee_erp.uk_materials_tenant_variant_color;
DROP INDEX IF EXISTS lychee_erp.uk_materials_tenant_variant_nocolor;
```

---

## 3. 枚举类型定义（Java / TypeScript）

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
  sourceCategoryId: number; // 策略由哪一级分类继承而来
  codePrefix?: string;
  seqLength?: number;
  dateFormat?: string;
  isSeqShared?: boolean;
  parentCategoryId?: number;
}
```

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
           最終物料編碼: "FAB-00042" (連續無跳號)
```

#### `seq_key` 生成規則：
1. **獨立計數模式（默認，`is_seq_shared = false`）**：
   $$\text{seq\_key} = \text{"MATERIAL\_CAT:"} + \text{categoryId}$$
   * 範例：面料大類（ID=10）為 `MATERIAL_CAT:10`，拉鍊大類（ID=20）為 `MATERIAL_CAT:20`。兩者計數器徹底隔離，各自從 1 開始連續遞增。
2. **共用父級流水模式（`is_seq_shared = true` 且存在 `parent_id`）**：
   $$\text{seq\_key} = \text{"MATERIAL\_CAT:"} + \text{parentCategoryId}$$
   * 範例：梭織面料（ID=101）與針織面料（ID=102）勾選共用流水，發號時統一錨定父級面料大類（ID=10）的流水池，共享總序列。

---

## 5. 存量歷史數據平滑遷移腳本

為確保上線時老數據不受影響，可通過一次性數據補錄腳本，僅為頂級分類（`level = 1`）打上策略標籤，子分類自動繼承：

```sql
-- 1. 服裝類頂級分類設為 FASHION_VARIANT
UPDATE lychee_erp.material_categories
SET code_strategy = 'FASHION_VARIANT'
WHERE level = 1 
  AND (code IN ('APP', 'SHOE', 'CLOTH') OR name LIKE '%服装%' OR name LIKE '%成衣%' OR name LIKE '%鞋%')
  AND code_strategy IS NULL;

-- 2. 原料與輔料類設為 SEQUENTIAL (默認 5 位長度，自身 code 作為前綴)
UPDATE lychee_erp.material_categories
SET code_strategy = 'SEQUENTIAL',
    seq_length = 5
WHERE level = 1 
  AND (code IN ('FAB', 'ACC', 'ROH', 'MAT') OR name LIKE '%原料%' OR name LIKE '%辅料%' OR name LIKE '%面料%')
  AND code_strategy IS NULL;

-- 3. 其餘未匹配的頂級分類，默認初始化為 MANUAL，避免未知類型強行算號
UPDATE lychee_erp.material_categories
SET code_strategy = 'MANUAL'
WHERE level = 1 
  AND code_strategy IS NULL;
```

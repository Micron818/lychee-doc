# 03. Schema 与数据模型设计

---

## 1. 改动范围与向下兼容性原则

```text
┌─────────────────────────────────────────────────────────────┐
│                       改动范围总览                          │
├──────────────────────────┬──────────────────────────────────┤
│ 表名                     │ 动作                             │
├──────────────────────────┼──────────────────────────────────┤
│ lychee_erp.material_categories │ ALTER: 扩展编码策略相关字段 (ADD)│
│ lychee_erp.materials     │ 不改动 (保持 code varchar(50))   │
│ lychee_erp.sys_doc_rule  │ 复用现有单据/主数据流水规则表     │
│ V1 变体生成相关表        │ 不改动 (完整保留款号、尺码组等)   │
└──────────────────────────┴──────────────────────────────────┘
```

1. **零破坏性（Zero Breaking Change）**：
   - 现有的 `materials` 核心表完全不作修改；
   - V1 建立的 `product_models`, `product_size_groups`, `product_model_colors`, `product_model_size_codes` 及两条变体唯一索引原封不动保留；
2. **渐进式生效（Progressive Enhancement）**：
   - `material_categories.code_strategy` 允许为 `NULL`，为 `NULL` 时按层级向上继承；
   - 未配置任何策略的历史存量数据，系统安全回退为现网既有逻辑，完全不影响老系统运行。

---

## 2. DDL 扩展与定义（PostgreSQL）

### 2.1 修改 `material_categories` 表

```sql
-- 1. 扩展字段
ALTER TABLE lychee_erp.material_categories
    ADD COLUMN IF NOT EXISTS code_strategy varchar(30) NULL,
    ADD COLUMN IF NOT EXISTS number_rule_id bigint NULL,
    ADD COLUMN IF NOT EXISTS code_prefix varchar(20) NULL;

-- 2. 字段业务注释
COMMENT ON COLUMN lychee_erp.material_categories.code_strategy IS 
    '编码策略: FASHION_VARIANT(款色码变体), SEQUENTIAL(序列流水号), MANUAL(手工输入). 为空则继承父分类';

COMMENT ON COLUMN lychee_erp.material_categories.number_rule_id IS 
    '关联合同/单据号码规则 ID (sys_doc_rule.id). 当 strategy 为 SEQUENTIAL 时生效';

COMMENT ON COLUMN lychee_erp.material_categories.code_prefix IS 
    '自定义编码前缀. 若为空则默认使用分类自身 code 作为流水号前缀';

-- 3. 添加外键约束
ALTER TABLE lychee_erp.material_categories
    ADD CONSTRAINT fk_material_categories_number_rule
    FOREIGN KEY (number_rule_id) REFERENCES lychee_erp.sys_doc_rule (id)
    ON DELETE SET NULL ON UPDATE NO ACTION;

-- 4. 索引优化 (用于树状策略继承递归查询)
CREATE INDEX IF NOT EXISTS idx_material_categories_strategy 
    ON lychee_erp.material_categories (tenant_id, code_strategy)
    WHERE code_strategy IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_material_categories_num_rule 
    ON lychee_erp.material_categories (number_rule_id)
    WHERE number_rule_id IS NOT NULL;
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
     * 分类前缀序列流水号策略 (FAB-2609-00012)
     * 依赖 sys_doc_rule 或分类自定义前缀
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
  prefix?: string;
  numberRuleId?: number;
}
```

---

## 4. 与 `sys_doc_rule`（系统号码规则）的协同设计

当前系统已在 `lychee-erp-common` 建立了通用的流水发号机制 `DocumentNumberGeneratorService` 与 `sys_doc_rule`。

```text
┌───────────────────────────────┐
│   material_categories 表      │
│   - code_strategy: SEQUENTIAL │
│   - number_rule_id ───────────┼──────┐
└───────────────────────────────┘      │ 外键引用
                                       ▼
┌────────────────────────────────────────────────────────┐
│              sys_doc_rule (系统号码规则表)             │
│  - rule_code: MATERIAL (或特定分类规则代码)             │
│  - prefix: FAB (默认前缀)                              │
│  - date_format: YYYYMM (可选嵌入年月)                  │
│  - seq_length: 5 (流水长度，补零)                      │
│  - reset_type: NEVER / MONTHLY / YEARLY (重置周期)     │
└────────────────────────────────────────────────────────┘
```

* 当分类指定了 `number_rule_id` 时，流水规则完全受该规则托管（重置周期、长度、日期段）；
* 当分类未指定 `number_rule_id` 但策略为 `SEQUENTIAL` 时，系统自动采用轻量默认规则：`{分类Code}-{5位自增流水}`。

---

## 5. 存量历史数据平滑迁移脚本

为确保上线时老数据不受影响，可通过一次性数据补录脚本，仅为顶级分类（`level = 1`）打上策略标签，子分类自动继承：

```sql
-- 假设服装类顶级分类 code 为 'APP' 或名称含 '服装'、'鞋'
UPDATE lychee_erp.material_categories
SET code_strategy = 'FASHION_VARIANT'
WHERE level = 1 
  AND (code IN ('APP', 'SHOE', 'CLOTH') OR name LIKE '%服装%' OR name LIKE '%成衣%' OR name LIKE '%鞋%')
  AND code_strategy IS NULL;

-- 原料与辅料类设为 SEQUENTIAL
UPDATE lychee_erp.material_categories
SET code_strategy = 'SEQUENTIAL'
WHERE level = 1 
  AND (code IN ('FAB', 'ACC', 'ROH', 'MAT') OR name LIKE '%原料%' OR name LIKE '%辅料%' OR name LIKE '%面料%')
  AND code_strategy IS NULL;

-- 其余未匹配的顶级分类，默认初始化为 MANUAL，避免未知类型强行算号
UPDATE lychee_erp.material_categories
SET code_strategy = 'MANUAL'
WHERE level = 1 
  AND code_strategy IS NULL;
```

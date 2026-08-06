# MM (Material Management) 模組資料庫設計文件

## 1. 模組概述
MM 模組負責管理系統中所有的物料主檔資料，包含分類、屬性、單位以及物料本身的定義。此模組為 ERP 系統的核心基礎，支援 PP (生產)、SCM (供應鏈)、SD (銷售) 等其他模組運作。

## 2. 實體關係圖 (ERD) 概念

核心以 `materials` (物料主檔) 為中心，向外關聯至各屬性表：

*   **分類架構**: `material_categories` (樹狀結構)
*   **屬性定義**: `material_types` (類型控制), `material_units` (計量單位)
*   **財務評估類**: `materials.valuation_class_id` → FI `valuation_classes`；類型允許範圍見 `material_type_valuation_classes`
*   **產品變體**: `product_models` (型體), `colors` (顏色), `product_sizes` (尺碼)
*   **單位換算**: `material_unit_conversions` (多單位支援)

## 3. 資料表清單與設計備忘

### 3.1 物料主檔 (materials)
*   **用途**: 系統中最小庫存管理單位 (SKU) 的唯一定義。
*   **關鍵欄位**:
    *   `code`: 物料編號，全 Tenant 唯一。
    *   `material_type_id`: 決定是否可銷售/採購/生產。
    *   `base_unit_id`: **庫存計價單位**。所有庫存異動與成本計算的基準。
    *   `purchase_unit_id`: **預設採購單位**。例如：庫存管「個」，但向供應商買「箱」。
    *   `sales_unit_id`: **預設銷售單位**。
    *   `status_option_id`: 資料狀態 (Active/Inactive/Obsolete)。

### 3.2 單位換算 (material_unit_conversions)
*   **用途**: 定義物料在不同單位間的換算規則。
*   **關鍵欄位**:
    *   `unit_id`: 替代單位 (如 Box)。
    *   `to_base_unit_id`: 目標基本單位 (如 PCS)。
    *   `conversion_rate`: 換算率。公式：`基本單位數量 = 替代單位數量 * 換算率`。
*   **設計決策**:
    *   支援「一物多單位」，解決進貨 (箱)、庫存 (個)、出貨 (打) 單位不一致的問題。

### 3.3 物料分類 (material_categories)
*   **用途**: 定義物料的階層式分類 (大類 > 中類 > 小類)。
*   **特性**: 使用 `parent_id` 實作無限層級樹狀結構。

### 3.4 物料類型 (material_types)
*   **用途**: 定義物料的業務屬性 (是否庫存/採購/銷售/自製)。

## 4. 關鍵選項值建議 (Reference Data)

*   **Status (狀態)**
    *   `Active`: 啟用中。
    *   `Inactive`: 停用。
    *   `Obsolete`: 廢止。

## 5. 檔案路徑對照

| 資料表 | SQL 檔案路徑 |
| :--- | :--- |
| materials | `docs/database/sql/schema_tables/MM/materials.sql` |
| material_categories | `docs/database/sql/schema_tables/MM/material_categories.sql` |
| material_types | `docs/database/sql/schema_tables/MM/material_types.sql` |
| material_type_valuation_classes | `docs/database/sql/schema_tables/MM/material_type_valuation_classes.sql` |
| material_units | `docs/database/sql/schema_tables/MM/material_units.sql` |
| material_unit_conversions | `docs/database/sql/schema_tables/MM/material_unit_conversions.sql` |
| product_models | `docs/database/sql/schema_tables/MM/product_models.sql` |
| colors | `docs/database/sql/schema_tables/MM/colors.sql` |
| product_sizes | `docs/database/sql/schema_tables/MM/product_sizes.sql` |

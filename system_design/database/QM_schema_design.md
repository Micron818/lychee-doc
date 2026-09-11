# QM (Quality Management) 模組資料庫設計文件

## 1. 模組概述
QM 模組負責管理企業的品質檢驗流程，包含進料檢驗 (IQC)、製程檢驗 (IPQC) 與成品出貨檢驗 (OQC/FQC)。此模組與 MM (物料)、SCM (採購收貨) 與 PP (生產) 緊密整合。

## 2. 實體關係圖 (ERD) 概念

核心為 **檢驗單 (Inspection Order)** 與 **檢驗計畫 (Inspection Plan)**：

*   **檢驗項目 (Characteristics)**: `inspection_characteristics` 定義要檢測的項目 (如長度、重量、顏色)。
*   **檢驗計畫 (Plans)**: `inspection_plans` 與 `inspection_plan_items` 定義特定物料需要進行哪些檢驗項目，以及其合格標準 (規格上下限)。
*   **檢驗單 (Orders)**: `inspection_orders` 是實際的檢驗任務，通常由收貨或生產完工觸發。
*   **檢驗結果 (Results)**: `inspection_results` 記錄每個項目的實測值與判定結果 (Pass/Fail)。
*   **使用決策 (Usage Decision)**: 檢驗完成後，對整批貨物做出的最終處置 (允收 Accept、拒收 Reject、特採 Concession)。

## 3. 資料表清單與設計備忘

### 3.1 檢驗項目 (inspection_characteristics)
*   **用途**: 檢驗參數主檔。
*   **關鍵欄位**:
    *   `data_type_option_id`: 資料型態 (數值 Numeric、布林 Boolean、文字 Text)。
    *   `uom_id`: 檢驗單位的度量衡 (如 cm, kg)。

### 3.2 檢驗計畫 (inspection_plans)
*   **用途**: 物料的檢驗規範 (Header)。
*   **關鍵欄位**:
    *   `material_id`: 關聯物料。
    *   `inspection_type_option_id`: 檢驗時機 (進料、製程、成品)。
    *   `valid_from` / `valid_to`: 計畫有效期。

### 3.3 檢驗計畫明細 (inspection_plan_items)
*   **用途**: 定義該計畫下的具體檢驗項目與規格。
*   **關鍵欄位**:
    *   `upper_limit` / `lower_limit`: 規格上下限 (USL/LSL)。
    *   `target_value`: 目標值。
    *   `text_value_expected`: 預期文字結果 (如 'PASS', 'RED')。

### 3.4 檢驗單 (inspection_orders)
*   **用途**: 檢驗執行單據。
*   **關鍵欄位**:
    *   `source_doc_type` / `source_doc_id`: 來源單據 (如 Goods Receipt Item ID)。
    *   `usage_decision_option_id`: 最終判定結果 (允收/拒收)。
    *   `quantity`: 送檢數量。
    *   `sample_size`: 抽樣數量。

### 3.5 檢驗結果 (inspection_results)
*   **用途**: 記錄實測數據。
*   **關鍵欄位**:
    *   `measured_value`: 實際量測值。
    *   `is_passed`: 單項判定結果。

## 4. 關鍵選項值建議 (Reference Data)

以下為 QM 模組中常用 `option_values` 的建議值：

### 4.1 檢驗類型 (Inspection Type)
*   **Category Code**: `INSPECTION_TYPE`
*   **Values**: 
    *   `INCOMING` (進料檢驗 IQC)
    *   `IN_PROCESS` (製程檢驗 IPQC)
    *   `FINAL` (成品檢驗 FQC)
    *   `OUTGOING` (出貨檢驗 OQC)

### 4.2 資料型態 (Data Type)
*   **Category Code**: `DATA_TYPE`
*   **Values**: `NUMERIC`, `BOOLEAN`, `TEXT`

### 4.3 檢驗單狀態 (Inspection Status)
*   **Category Code**: `INSPECTION_STATUS`
*   **Values**: `CREATED`, `IN_PROCESS`, `COMPLETED`, `CLOSED`

### 4.4 使用決策 (Usage Decision)
*   **Category Code**: `USAGE_DECISION`
*   **Values**: 
    *   `ACCEPT` (允收)
    *   `REJECT` (拒收)
    *   `CONCESSION` (特採)
    *   `SCRAP` (報廢)

## 5. 檔案路徑對照

| 資料表 | SQL 檔案路徑 |
| :--- | :--- |
| inspection_characteristics | `docs/database/sql/schema_tables/QM/inspection_characteristics.sql` |
| inspection_plans | `docs/database/sql/schema_tables/QM/inspection_plans.sql` |
| inspection_plan_items | `docs/database/sql/schema_tables/QM/inspection_plan_items.sql` |
| inspection_orders | `docs/database/sql/schema_tables/QM/inspection_orders.sql` |
| inspection_results | `docs/database/sql/schema_tables/QM/inspection_results.sql` |


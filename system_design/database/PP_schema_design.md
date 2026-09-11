# PP (Production Planning) 模組資料庫設計文件

## 1. 模組概述
PP 模組負責管理生產製造相關的基礎資料與流程。本模組設計遵循以下標準作業流程 (SOP)：
**Sales Order (SO)** -> **Factory Order (FO)** -> **MRP** -> **Planned Order** -> **Production Order (MO)**。

1.  **Factory Order (投產單)**: 承接銷售需求，整合為內部的生產需求指令。
2.  **MRP (物料需求規劃)**: 根據 FO 需求與庫存狀況，運算產生建議的供應計畫。
3.  **Planned Order (計劃訂單)**: MRP 的產出結果，經確認後轉為正式單據。
4.  **Production Order (工單/MO)**: 正式下達給產線的執行命令，包含發料與完工入庫。

## 2. 實體關係圖 (ERD) 概念

### 2.1 主流程串接
*   **需求來源**: `factory_orders` (投產單)。
    *   這是一個**匯總 (Aggregation)** 層級的單據。
    *   透過 `factory_order_items` 關聯多筆 `sales_order_items`，將多張客戶訂單合併為一張工廠生產指令。
*   **規劃引擎**: MRP 運算讀取 `factory_orders` 的總需求量，產生 `planned_orders`。
*   **執行單據**:
    *   `planned_orders` (Type=MAKE) -> 轉為 `production_orders`。
    *   `planned_orders` (Type=BUY) -> 轉為 `purchase_requisitions` (SCM模組)。

### 2.2 BOM 結構
核心為 BOM 的「表頭-表身」結構，並與 MM 模組的 `materials` 表形成關聯：
*   **父階成品**: 由 `bill_of_materials` 連結至 `materials` (Product Material)。
*   **子階組件**: 由 `bom_items` 連結至 `materials` (Component Material)。
*   **工單用料**: 當建立 `production_orders` 時，會將 BOM 展開並複製到 `production_order_components`，作為領料依據。

## 3. 資料表清單與設計備忘

### 3.1 工廠訂單 (factory_orders)
*   **用途**: 生產部門的頂層需求單，用於銜接業務端 (SO) 與製造端。
*   **關鍵欄位**:
    *   `product_material_id`: 需生產的產品。
    *   `quantity`: 匯總後的總生產數量。
    *   `due_date`: 預計完工日 (作為 MRP 的需求日期)。
    *   `status`: 控制是否參與 MRP 運算：Draft, Confirmed, Closed

### 3.1.1 工廠訂單明細 (factory_order_items)
*   **用途**: 記錄工廠訂單的來源構成，實現從「生產指令」回溯至「客戶訂單」的追蹤。
*   **關鍵欄位**:
    *   `factory_order_id`: 關聯主檔。
    *   `sales_order_item_id`: 關聯至具體的銷售訂單明細 (SO Line)。
    *   `allocated_quantity`: 該張 SO 在此 FO 中分配的數量（例如：FO 總數 300，其中 100 來自 SO-A，200 來自 SO-B）。

### 3.2 計劃訂單 (planned_orders)
*   **用途**: MRP 運算後的「建議」單據，尚未正式執行。
*   **關鍵欄位**:
    *   `mrp_run_id`: 來源 MRP 批次。
    *   `source_factory_order_id`: 滿足哪張 FO 的需求。
    *   `order_type`: `MAKE` (自製) 或 `BUY` (外購)。
    *   `start_date` / `end_date`: 建議的開工/完工日。
    *   `status`: `Proposed` (系統建議) -> `Firmed` (人工確認) -> `Converted` (已轉單)。

### 3.3 生產工單 (production_orders) - 即 MO
*   **用途**: 正式生產命令，追蹤進度與成本。
*   **關鍵欄位**:
    *   `source_planned_order_id`: 來源計劃單。
    *   `bom_id`: 鎖定當下生產使用的 BOM 版本。
    *   `planned_quantity` vs `completed_quantity`: 預計 vs 實績。
    *   `department_id`: 負責生產的車間/部門。

### 3.4 工單用料明細 (production_order_components)
*   **用途**: 該張工單應領取的材料清單 (Pick List)。
*   **關鍵欄位**:
    *   `required_quantity`: 根據 BOM 與工單數量計算的應領量。
    *   `issued_quantity`: 實際已從倉庫領出的數量 (回寫自 WM 的 `stock_issues`)。
    *   `is_backflush`: 是否採用倒扣料模式。

### 3.5 BOM 表頭 (bill_of_materials)
*   **用途**: 定義一個產品 (成品/半成品) 的 BOM 版本與生效資訊。
*   **關鍵欄位**:
    *   `product_material_id`: 對應到 MM 模組的父階物料 ID。
    *   `version`: 版本號 (如 V1.0, 2023-Q1)。
    *   `is_active`: 標記是否為當前生效的主要版本。

### 3.6 MRP 運算紀錄 (mrp_runs / mrp_results)
*   `mrp_runs`: 記錄每次 MRP 的執行參數。
*   `mrp_results`: (可選) 暫存詳細運算過程或例外訊息，但主要產出已實體化為 `planned_orders`。

## 4. 關鍵選項值建議 (Reference Data)

*   **Factory Order Status**
    *   `Draft`: 草稿 (不跑 MRP)。
    *   `Confirmed`: 已確認 (納入 MRP 需求)。
    *   `Closed`: 已結案。
*   **Planned Order Status**
    *   `Proposed`: 系統自動產生。
    *   `Firmed`: 計劃員已確認，MRP 重跑時不覆蓋。
    *   `Converted`: 已轉為 MO/PR。
*   **Production Order Status**
    *   `Created`: 建立。
    *   `Released`: 下達 (允許領料)。
    *   `In_Progress`: 生產中。
    *   `Finished`: 完工入庫。
    *   `Closed`: 結案 (成本結算)。
*   **BOM Status**
    *   `Draft`: 草稿 (初始錄入)。
    *   `Auditing`: 審核中 (鎖定編輯)。
    *   `Released`: 已發佈 (正式生效，供 MRP/工單使用)。
    *   `UnderECN`: 變更中 (工程變更執行中)。
    *   `Obsolete`: 已廢棄 (舊版歸檔)。

## 5. 檔案路徑對照表

| 表格名稱 | SQL 定義檔路徑 | 說明 |
| :--- | :--- | :--- |
| **factory_orders** | `docs/database/sql/schema_tables/PP/factory_orders.sql` | 工廠訂單 (生產需求) |
| **factory_order_items** | `docs/database/sql/schema_tables/PP/factory_order_items.sql` | 工廠訂單明細 (來源追溯) |
| **planned_orders** | `docs/database/sql/schema_tables/PP/planned_orders.sql` | 計劃訂單 (MRP 建議) |
| **production_orders** | `docs/database/sql/schema_tables/PP/production_orders.sql` | 生產工單 (MO) |
| **production_order_components** | `docs/database/sql/schema_tables/PP/production_order_components.sql` | 工單用料明細 |
| **bill_of_materials** | `docs/database/sql/schema_tables/PP/bill_of_materials.sql` | BOM 表頭 |
| **bom_items** | `docs/database/sql/schema_tables/PP/bom_items.sql` | BOM 表身 |
| **mrp_runs** | `docs/database/sql/schema_tables/PP/mrp_runs.sql` | MRP 執行紀錄 |


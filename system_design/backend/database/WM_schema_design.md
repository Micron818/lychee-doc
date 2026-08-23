# WM (Warehouse Management) 模組資料庫設計文件

## 1. 模組概述
WM 模組負責管理企業的庫存與物流作業。核心功能包含 **倉庫定義 (Warehouses)** 以及各類型的 **庫存異動 (Stock Transactions)**。
在 Lychee ERP 的架構中，庫存異動分散於各業務模組觸發（如 SCM 收貨、PP 完工入庫、SD 出貨），而 WM 模組本身則負責處理 **內部領用 (Internal Issues)**、**退料 (Issue Return)**、**調撥 (Transfer)** 與 **盤點 (Stocktaking)** 等庫存專屬作業。

所有數量增減最終寫入 `stock_transactions`（流水帳，Source of Truth），並同步更新 `stock_on_hand`（即時庫存）。

## 2. 實體關係圖 (ERD) 概念

以 `warehouses` 為物理儲存中心，透過不同單據進行數量增減：

*   **入庫 (Inbound)**: 由 `goods_receipts` 觸發。涵蓋採購收貨、生產完工入庫、雜項入庫、託外收回等。
*   **出庫 (Outbound - Sales)**: 由 SD 模組的 `shipments` / `DELIVERY` 觸發（銷售出貨）。
*   **出庫 (Outbound - Internal)**: 由 WM 模組的 `stock_issues` 觸發（生產領料、部門領用、報廢、樣品）。
*   **退料入庫 (Issue Return)**: 由 `stock_issue_returns` 觸發。僅沖回內部領料，不是客戶退貨或採購退貨。
*   **庫存帳**: `stock_on_hand` 記錄當下餘額；`stock_transactions` 記錄每一筆異動軌跡。

## 3. 資料表清單與設計備忘

### 3.1 倉庫主檔 (warehouses)
*   **用途**: 定義庫存存放的物理位置。
*   **關鍵欄位**:
    *   `code`: 倉庫代號（如: RW01-原料倉, FG01-成品倉）。
    *   `active_status`: 標記倉庫是否可進行異動。

### 3.2 收貨單 (goods_receipts / items)
*   **用途**: 各類入庫的統一單據。業務可由 SCM / PP 觸發，表結構屬於 WM 庫存入口。
*   **主表關鍵欄位**:
    *   `supplier_id`: 關聯供應商，採購收貨必填。
    *   `delivery_note_no`: 外部送貨單號，用於實務核對與三單匹配。
    *   `receipt_type`: `PURCHASE`, `PRODUCTION_REPORT`, `MISC`, `OUTSOURCE`。
    *   `status`: `DRAFT`（編輯中）, `POSTED`（已過帳）, `REVERSED`（已沖銷）。
*   **明細關鍵欄位**:
    *   `source_doc_id` / `source_doc_type`: 來源追蹤。支援 `PURCHASE_ORDER_ITEM`, `PRODUCTION_REPORT`, `CUSTOMER_RETURN_ITEM`, `OUTSOURCE_ORDER_ITEM` 等。
    *   `batch_no`: 批號維度，無批號時預設空字串 `''`。
    *   `is_foc`: 贈品標記，影響 AP 核銷邏輯。
    *   `transaction_unit` / `base_unit`: 雙單位設計。`transaction` 為單據單位，`base` 為庫存結算基本單位。
    *   `expiry_date`: 批號有效期限，支援 FEFO 邏輯。
    *   `stock_type`: 入庫庫存狀態。`UNRESTRICTED`（可用）, `INSPECTION`（待檢）, `BLOCKED`（凍結）。

### 3.3 領料單 (stock_issues / items)
*   **用途**: 處理所有 **非銷售** 的出庫行為。
*   **主表關鍵欄位**:
    *   `issue_type`: 領料目的（生產 / 部門 / 報廢 / 樣品等）。
    *   `department_id`: **成本中心**，費用歸屬的責任單位。
    *   `status`: `DRAFT`, `POSTED`, `REVERSED`。
*   **明細關鍵欄位**:
    *   `source_doc_id` / `source_doc_type`: 關聯來源，如 `PRODUCTION_ORDER_COMPONENT` 用於核銷工單預留量。
    *   `returned_quantity`: 已過帳退料的基本單位合計。可退數量 = `base_quantity - returned_quantity`。
    *   `transaction_unit` / `base_unit`: 與收貨相同的雙單位設計。

### 3.4 退料單 (stock_issue_returns / items)
*   **用途**: 內部領料的反向單。**不是**客戶退貨（`CUSTOMER_RETURN`）或採購退貨（`VENDOR_RETURN`）。
*   **可退領料類型**: 僅已過帳 `PRODUCTION` / `COST_CENTER` / `SAMPLE`。不含 `PRODUCTION_REPORT`（沖銷生產日報）、`SCRAP`、`SALES_DELIVERY`。
*   **主表關鍵欄位**:
    *   `original_stock_issue_id`: 一張退料單只對應一張已過帳領料單。
    *   `return_type`: `PRODUCTION`, `COST_CENTER`, `SAMPLE`（從原領料 `issue_type` 複製，不可改）。
    *   `status`: `DRAFT`, `POSTED`, `REVERSED`。
*   **明細關鍵欄位**:
    *   `original_issue_item_id`: 必須參照原領料明細；同一退料單內一行對應一條領料明細。
    *   倉庫與批號鎖定原領料明細，不可改。
    *   `stock_type`: 退回庫存狀態，可選 `UNRESTRICTED`, `INSPECTION`, `BLOCKED`。
*   **流水帳規則**: 過帳寫入 `STOCK_ISSUE_RETURN`；領料單本身的沖銷仍寫 `STOCK_ISSUE`（進出方向對調）。原領料存在草稿或已過帳退料時禁止沖銷。

### 3.5 庫存帳務體系 (Stock Ledger)
為了滿足即時查詢與歷史報表需求，採用三層式架構：

1.  **即時庫存 (stock_on_hand)**
    *   **用途**: 查詢「當下有多少貨」。
    *   **維度**: 工廠 + 倉庫 + 物料 + 批號（核心索引）。
    *   **關鍵欄位**:
        *   `physical_quantity`: 帳面實物數量。
        *   `reserved_quantity`: 已鎖定但未出庫數（如訂單 / 工單預留）。
        *   `blocked_quantity` / `qa_quantity`: 凍結與待檢數量，不計入可用數。
        *   `location_code`: 儲位代碼。

2.  **異動明細 (stock_transactions)**
    *   **用途**: 庫存流水帳 (Log)，所有增減行為的單一真理來源 (Source of Truth)。
    *   **關鍵欄位**:
        *   `transaction_type`: 異動類型（見第 4 節）。沖銷沿用原過帳類型，進出方向對調。
        *   `before_quantity` / `in_quantity` / `out_quantity` / `after_quantity`: 數量變動軌跡，確保帳務連續性。
        *   `unit_cost` / `total_amount`: 異動當下的成本與金額，用於庫存估值。
        *   `source_doc_id` / `source_doc_type`: 追溯至觸發異動的原始單據。

3.  **庫存期間 (inventory_periods)**
    *   **用途**: 定義庫存月結 / 進耗存報表的會計期間（起迄日、關帳狀態）。
    *   **特色**: 與 `fiscal_periods` 分離，支援庫存關帳流程獨立於財務關帳。

4.  **進耗存結餘表 (inventory_balances)**
    *   **用途**: 快速產出期初、期末、本期進出的月報表。
    *   **特色**: 透過每月批次作業自 `stock_transactions` 彙總更新，大幅提升報表查詢效能。

### 3.6 批號管理 (Batch / Lot Management)
`batch_no` 欄位貫穿庫存體系的三大核心表（即時庫存、異動明細、結餘表），其設計目的如下：

1.  **追溯性 (Traceability)**:
    *   可追蹤特定批次的原物料是用於生產哪些成品，或銷售給哪些客戶。
    *   當發生品質異常時，可鎖定特定批號進行召回或凍結，而非全面下架。
2.  **效期管理 (Expiration)**:
    *   通常批號會綁定製造日期與有效期限（在 `goods_receipt_items` 或批號主檔中維護）。
    *   支援 **FEFO (First Expired, First Out)** 先到期先出貨的撿貨邏輯。
3.  **成本計算 (Costing)**:
    *   若採用「個別認定法」或「分批 FIFO」，成本是依附在批號上的。
4.  **庫存顆粒度**:
    *   庫存的最小單位定義為：`Material` + `Warehouse` + `Batch No`。
    *   **無批號管理**: 若物料不需批號管理，系統預設存入空字串 `''` (Default Empty)，以統一索引鍵值，避免 SQL `NULL` 分組統計的問題。

## 4. 關鍵選項值建議 (Reference Data)

*   **Document Status (單據狀態)**
    *   `DRAFT`: 編輯中，可修改。
    *   `POSTED`: 已過帳 / 生效。
    *   `REVERSED`: 已沖銷。
*   **Stock Type (庫存狀態)**
    *   `UNRESTRICTED`: 可用。
    *   `INSPECTION`: 待檢。
    *   `BLOCKED`: 凍結。
*   **Issue Type (領料類型)**
    *   `PRODUCTION`: 生產領料（發至 WIP）。
    *   `PRODUCTION_REPORT`: 依生產日報領料。
    *   `COST_CENTER`: 部門費用領用（如文具、耗材）。
    *   `SCRAP`: 報廢 / 銷毀。
    *   `SAMPLE`: 樣品領用（研發 / 業務）。
    *   `SALES_DELIVERY`: 銷售出貨相關領用。
*   **Return Type (退料類型)**
    *   `PRODUCTION`: 生產退料。
    *   `COST_CENTER`: 部門退料。
    *   `SAMPLE`: 樣品退料。
*   **Transaction Type (異動類型)**
    *   `GOODS_RECEIPT`: 採購 / 雜項收貨 (+)。
    *   `PRODUCTION_RECEIPT`: 生產完工入庫 (+)。
    *   `VENDOR_RETURN`: 採購退貨 (-)。
    *   `DELIVERY`: 銷售出貨 (-)。
    *   `CUSTOMER_RETURN`: 客戶退貨 (+)。
    *   `STOCK_ISSUE`: 內部領用 (-)。領料單沖銷沿用此類型，進出方向對調。
    *   `STOCK_ISSUE_RETURN`: 領料退料單過帳 (+)。僅用於退料單，不是客戶退貨或採購退貨。
    *   `ADJUSTMENT`: 盤點調整 (+/-)。
    *   `STOCK_TRANSFER`: 倉庫調撥（出庫 / 入庫成對）。
    *   `BACKFLUSH`: 倒沖發料 (-)。

## 5. 檔案路徑對照表

| 表格名稱 | SQL 定義檔路徑 | 說明 |
| :--- | :--- | :--- |
| **warehouses** | `docs/database/sql/schema_tables/WM/warehouses.sql` | 倉庫主檔 |
| **goods_receipts** | `docs/database/sql/schema_tables/WM/goods_receipts.sql` | 收貨單表頭 |
| **goods_receipt_items** | `docs/database/sql/schema_tables/WM/goods_receipt_items.sql` | 收貨單明細 |
| **stock_issues** | `docs/database/sql/schema_tables/WM/stock_issues.sql` | 領料單表頭 |
| **stock_issue_items** | `docs/database/sql/schema_tables/WM/stock_issue_items.sql` | 領料單明細 |
| **stock_issue_returns** | `docs/database/sql/schema_tables/WM/stock_issue_returns.sql` | 退料單表頭 |
| **stock_issue_return_items** | `docs/database/sql/schema_tables/WM/stock_issue_return_items.sql` | 退料單明細 |
| **stock_on_hand** | `docs/database/sql/schema_tables/WM/stock_on_hand.sql` | 即時庫存量 |
| **stock_transactions** | `docs/database/sql/schema_tables/WM/stock_transactions.sql` | 庫存異動流水帳 |
| **inventory_periods** | `docs/database/sql/schema_tables/WM/inventory_periods.sql` | 庫存期間 |
| **inventory_balances** | `docs/database/sql/schema_tables/WM/inventory_balances.sql` | 進耗存結餘表 |

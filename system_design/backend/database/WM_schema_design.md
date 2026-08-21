# WM (Warehouse Management) 模組資料庫設計文件

## 1. 模組概述
WM 模組負責管理企業的庫存與物流作業。核心功能包含 **倉庫定義 (Warehouses)** 以及各類型的 **庫存異動 (Stock Transactions)**。
在 Lychee ERP 的架構中，庫存異動分散於各業務模組觸發（如 SCM 收貨、SD 出貨），而 WM 模組本身則負責處理 **內部領用 (Internal Issues)**、**調撥 (Transfer)** 與 **盤點 (Stocktaking)** 等庫存專屬作業。

## 2. 實體關係圖 (ERD) 概念

以 `warehouses` 為物理儲存中心，透過不同單據進行數量增減：

*   **入庫 (Inbound)**: 由 SCM 模組的 `goods_receipts` 觸發。
*   **出庫 (Outbound - Sales)**: 由 SD 模組的 `shipments` 觸發 (銷售出貨)。
*   **出庫 (Outbound - Internal)**: 由 WM 模組的 `stock_issues` 觸發 (生產領料、部門領用、報廢)。

## 3. 資料表清單與設計備忘

### 3.1 倉庫主檔 (warehouses)
*   **用途**: 定義庫存存放的物理位置。
*   **關鍵欄位**:
    *   `code`: 倉庫代號 (如: RW01-原料倉, FG01-成品倉)。
    *   `active_status`: 標記倉庫是否可進行異動。

### 3.2 領料單 (stock_issues / items)
*   **用途**: 處理所有 **非銷售** 的出庫行為。
*   **關鍵欄位**:
    *   `issue_type`: 定義領料目的 (生產/部門/報廢)。
    *   `department_id`: **成本中心**，費用歸屬的責任單位。
    *   `warehouse_id`: 扣帳倉庫。
    *   `source_ref_no`: 來源單號參照 (如工單號)。

### 3.3 庫存帳務體系 (Stock Ledger)
為了滿足即時查詢與歷史報表需求，採用三層式架構：

1.  **即時庫存 (stock_on_hand)**
    *   **用途**: 查詢「當下有多少貨」。
    *   **維度**: 倉庫 + 物料 + 批號。
    *   **特色**: 包含 `reserved_quantity` 欄位，支援訂單預留邏輯。

2.  **異動明細 (stock_transactions)**
    *   **用途**: 庫存流水帳 (Log)，所有增減行為的單一真理來源 (Source of Truth)。
    *   **特色**: 記錄 `source_doc_type` 與 `source_doc_id`，可追溯至原始單據 (如出貨單、收貨單)。

3.  **庫存期間 (inventory_periods)**
    *   **用途**: 定義庫存月結/進耗存報表的會計期間（起迄日、關帳狀態）。
    *   **特色**: 與 `fiscal_periods` 分離，支援庫存關帳流程獨立於財務關帳。

4.  **進耗存結餘表 (inventory_balances)**
    *   **用途**: 快速產出期初、期末、本期進出的月報表。
    *   **特色**: 透過每月批次作業自 `stock_transactions` 彙總更新，大幅提升報表查詢效能。

### 3.4 批號管理 (Batch / Lot Management)
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

*   **Issue Type (領料類型)**
    *   `PRODUCTION`: 生產領料 (發至 WIP)。
    *   `COST_CENTER`: 部門費用領用 (如文具、耗材)。
    *   `SCRAP`: 報廢/銷毀。
    *   `SAMPLE`: 樣品領用 (研發/業務)。
*   **Transaction Type (異動類型)**
    *   `GOODS_RECEIPT`: 採購收貨 (+)。
    *   `SHIPMENT`: 銷售出貨 (-)。
    *   `STOCK_ISSUE`: 內部領用 (-)。
    *   `STOCK_ISSUE_RETURN`: 領料退料 (+)。客戶退貨用 `CUSTOMER_RETURN`，採購退貨用 `VENDOR_RETURN`。
    *   `ADJUSTMENT`: 盤點調整 (+/-)。

## 5. 檔案路徑對照表

| 表格名稱 | SQL 定義檔路徑 | 說明 |
| :--- | :--- | :--- |
| **warehouses** | `docs/database/sql/schema_tables/WM/warehouses.sql` | 倉庫主檔 |
| **stock_issues** | `docs/database/sql/schema_tables/WM/stock_issues.sql` | 領料單表頭 |
| **stock_issue_items** | `docs/database/sql/schema_tables/WM/stock_issue_items.sql` | 領料單明細 |
| **stock_issue_returns** | `docs/database/sql/schema_tables/WM/stock_issue_returns.sql` | 退料單表頭 |
| **stock_issue_return_items** | `docs/database/sql/schema_tables/WM/stock_issue_return_items.sql` | 退料單明細 |
| **stock_on_hand** | `docs/database/sql/schema_tables/WM/stock_on_hand.sql` | 即時庫存量 |
| **stock_transactions** | `docs/database/sql/schema_tables/WM/stock_transactions.sql` | 庫存異動流水帳 |
| **inventory_periods** | `docs/database/sql/schema_tables/WM/inventory_periods.sql` | 庫存期間 |
| **inventory_balances** | `docs/database/sql/schema_tables/WM/inventory_balances.sql` | 進耗存結餘表 |

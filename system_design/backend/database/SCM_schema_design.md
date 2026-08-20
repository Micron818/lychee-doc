# SCM (Supply Chain Management) 模組資料庫設計文件

## 1. 模組概述
SCM 模組負責管理企業的供應鏈活動，目前設計核心為 **採購 (Purchasing)** 管理。從供應商資料維護、接收 MRP 的採購建議，到建立正式的請購單 (PR) 與採購單 (PO)，以及最終的 **收貨入庫 (Goods Receipt)**，形成完整的 P2P (Procure-to-Pay) 流程前端。

## 2. 實體關係圖 (ERD) 概念

以供應商與採購流程為主軸：
*   **供應商管理**: `suppliers` 為採購的對象。
*   **請購流程 (PR)**: `purchase_requisitions` (表頭) 與 `purchase_requisition_items` (表身)。此為**內部申請**。
*   **採購流程 (PO)**: `purchase_orders` (表頭) 與 `purchase_order_items` (表身)。此為**對外合約**。
*   **收貨流程 (GR)**: `goods_receipts` (表頭) 與 `goods_receipt_items` (表身)。確認**實際到貨**。
*   **跨模組整合**:
    *   **來源**: 請購明細透過 `source_mrp_result_id` 連結至 PP 模組的 MRP 結果。
    *   **轉換**: 採購明細透過 `source_pr_item_id` 連結至請購單；收貨明細透過 `purchase_order_item_id` 連結至採購單。
    *   **庫存**: 收貨明細連結至 WM 模組的 `warehouses`，觸發庫存增加。

## 3. 資料表清單與設計備忘

### 3.1 供應商主檔 (suppliers)
*   **用途**: 記錄供應商的基本資料、聯絡人與交易條件。
*   **關鍵欄位**:
    *   `code`: 供應商代號，全 Tenant 唯一。
    *   `tax_id`: 統一編號/稅號。
    *   `payment_terms`: 付款條件描述。
    *   `supplier_type_option_id`: 供應商類別 (如: 原料商, 耗材商, 外包商)。

### 3.2 請購單 (purchase_requisitions / items)
*   **用途**: 內部單位提出的購買申請單，確認「需求」與「預算」。
*   **關鍵欄位**:
    *   `requester_id`: 申請人。
    *   `source_mrp_result_id`: **核心設計**，連結回 MRP 運算結果，讓採購知道需求的原始觸發點。
    *   `suggested_supplier_id`: 建議供應商。

### 3.3 採購單 (purchase_orders / items)
*   **用途**: 對供應商發出的正式訂購合約。
*   **關鍵欄位**:
    *   `supplier_id`: 正式下單對象。
    *   `currency_option_id` & `exchange_rate`: 採購幣別與匯率快照。預設來自 BASIS `exchange_rates`；收貨複製本快照，不重查主檔。
    *   `unit_price` & `subtotal`: 雙方議定後的價格，為 AP (應付帳款) 的依據。
    *   `source_pr_item_id`: 連結回請購單明細。
    *   `expected_delivery_date`: 預計到貨日。

### 3.4 收貨單 (goods_receipts / items)
*   **用途**: 倉庫人員確認收到供應商貨物的紀錄。
*   **關鍵欄位**:
    *   `supplier_delivery_note`: 供應商送貨單號 (DO No.)。此欄位至關重要，因為財務在進行「三單匹配 (PO, GR, Invoice)」時，需要此單號來勾稽發票。
    *   `receipt_date`: 實際收貨日，決定了庫存帳齡的起始點與應付帳款的起算日 (若 Term 為月結)。
    *   `purchase_order_item_id`: **核心連結**，系統可據此檢查收貨量是否小於等於採購量 (Over-delivery check)。
    *   `batch_no` & `expiry_date`: 針對需批次管理的物料 (如化學品)，在此環節錄入批號與效期。

## 4. 關鍵選項值建議 (Reference Data)

*   **PR/PO Status (請購/採購狀態)**
    *   `Draft`: 草稿，可自由修改。
    *   `Pending Approval`: 送審中。
    *   `Approved`: 已核准，等待後續作業。
    *   `Converted`: 已轉單 (PR -> PO)。
    *   `Closed`: 結案 (全數收貨或強制結案)。
*   **GR Status (收貨狀態)**
    *   `Received`: 已收貨過帳 (不可修改)。
    *   `Cancelled`: 取消/作廢。

## 5. 檔案路徑對照表

| 表格名稱 | SQL 定義檔路徑 | 說明 |
| :--- | :--- | :--- |
| **suppliers** | `docs/database/sql/schema_tables/SCM/suppliers.sql` | 供應商主檔 |
| **purchase_requisitions** | `docs/database/sql/schema_tables/SCM/purchase_requisitions.sql` | 請購單表頭 |
| **purchase_requisition_items** | `docs/database/sql/schema_tables/SCM/purchase_requisition_items.sql` | 請購單明細 |
| **purchase_orders** | `docs/database/sql/schema_tables/SCM/purchase_orders.sql` | 採購單表頭 |
| **purchase_order_items** | `docs/database/sql/schema_tables/SCM/purchase_order_items.sql` | 採購單明細 |
| **goods_receipts** | `docs/database/sql/schema_tables/SCM/goods_receipts.sql` | 收貨單表頭 |
| **goods_receipt_items** | `docs/database/sql/schema_tables/SCM/goods_receipt_items.sql` | 收貨單明細 (入庫) |

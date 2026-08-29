# SD (Sales and Distribution) 模組資料庫設計文件

## 1. 模組概述
SD 模組負責管理企業的銷售流程，從報價、訂單接收、出貨到開立發票。目前的設計核心為 **銷售訂單 (Sales Orders)**，它串連了 CRM (客戶) 與 MM (庫存) 模組，將客戶需求轉化為內部的物流與生產指令。

## 2. 實體關係圖 (ERD) 概念

以 `sales_orders` (表頭) 與 `sales_order_items` (表身) 為主體：

*   **客戶來源**: 連結 `customers` (SD)，取得交易對象與預設商業條件。
*   **商品內容**: 連結 `materials` (MM)，確認銷售的品項與庫存單位。
*   **出貨執行**: 連結 `shipments` (出貨單)，將庫存扣帳。

## 3. 資料表清單與設計備忘

### 3.1.0 客戶資料 (customers)
*   **用途**: 記錄客戶的基本資料、聯絡方式與商業交易條件。
*   **關鍵欄位**:
    *   `code`: 客戶代號，全 Tenant 唯一，作為訂單與發票的識別碼。
    *   `tax_id`: 統一編號/稅號，稅務申報關鍵欄位。
    *   `tax_class_id`: 往來稅分類（FK FI `tax_classes`，`class_scope = PARTNER`），開單判定用。
    *   `currency_option_id`: 預設交易幣別，減少開立訂單時的輸入錯誤。
    *   客戶主檔**不加**付款條件欄；條件在 FI `business_partners.payment_term_id`，客戶頁只讀展示。
    *   `credit_limit`: 信用額度，用於銷售流程中的信用控管 (Credit Check)。
    *   `sales_person_id`: 業務負責人，用於權限劃分 (Row-Level Security) 與業績歸屬。
*   **設計決策**:
    *   **地址分離**: 分開設計 `address_billing` (發票地址) 與 `address_shipping` (送貨地址)，滿足常見的商業情境。
    *   **聯絡人**: 目前採單一主要聯絡人設計 (`contact_person` 等欄位直接在主表)，若未來需多位聯絡人，可再擴充子表 `customer_contacts`。

### 3.1.1 銷售訂單 (sales_orders / items)
*   **用途**: 記錄訂單的總體資訊與明細。
*   **關鍵欄位**:
    *   `customer_po_no`: 客戶採購單號，B2B 對帳關鍵。
    *   `currency_option_id` & `exchange_rate`: 記錄接單匯率快照，鎖定營收金額。預設來自 BASIS `exchange_rates`（`rate_date <= order_date`），允許覆寫；主檔變更不回溯已存訂單。
    *   `payment_term_id`: 付款條件（FK `fi_payment_terms`；保存必填）。選客戶時帶出 BP 條件。
    *   `shipping_address`: 獨立儲存送貨地址 (Snapshot)，不隨客戶主檔變動而改變歷史訂單。
    *   `expected_delivery_date`: 明細層級的預計交貨日，支援分批交貨。

### 3.2 出貨單 (shipments / items)
*   **用途**: 物流單位執行的出庫指令。
*   **關鍵欄位**:
    *   `sales_order_item_id`: 連結回訂單明細，追蹤交貨進度 (Fulfillment Rate)。
    *   `warehouse_id`: 實際扣帳倉庫。
    *   `tracking_number`: 物流單號，供客戶查詢貨態。

## 4. 關鍵選項值建議 (Reference Data)

*   **SO Status (訂單狀態)**
    *   `Draft`: 草稿。
    *   `Confirmed`: 已確認 (準備出貨)。
    *   `Shipped`: 已全數出貨。
    *   `Closed`: 結案 (已開票/收款)。
    *   `Cancelled`: 取消。
*   **Shipment Status (出貨狀態)**
    *   `Draft`: 草稿 (揀貨中)。
    *   `Shipped`: 已出貨 (扣帳完成)。
    *   `Delivered`: 客戶已簽收。

## 5. 檔案路徑對照表

| 表格名稱 | SQL 定義檔路徑 | 說明 |
| :--- | :--- | :--- |
| **customers** | `docs/database/sql/schema_tables/SD/customers.sql` | 客戶主檔 |
| **sales_orders** | `docs/database/sql/schema_tables/SD/sales_orders.sql` | 訂單表頭 |
| **sales_order_items** | `docs/database/sql/schema_tables/SD/sales_order_items.sql` | 訂單明細 |
| **shipments** | `docs/database/sql/schema_tables/SD/shipments.sql` | 出貨單表頭 |
| **shipment_items** | `docs/database/sql/schema_tables/SD/shipment_items.sql` | 出貨單明細 |

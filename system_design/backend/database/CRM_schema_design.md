# CRM (Customer Relationship Management) 模組資料庫設計文件

## 1. 模組概述
CRM 模組負責管理企業與客戶之間的互動資料。在目前的 ERP 架構中，核心功能是集中管理 **客戶主檔 (Customer Master Data)**，這是銷售 (SD) 與財務應收帳款 (AR) 流程的基石。

## 2. 實體關係圖 (ERD) 概念

以 `customers` 表為核心，關聯至系統共用的選項與人員資料：

*   **業務歸屬**: 透過 `sales_person_id` 連結至 `users` 表，定義客戶負責人。
*   **交易屬性**: 幣別仍用 `currency_option_id`（`option_values`）。付款條件在 FI `business_partners.payment_term_id`（`fi_payment_terms`），客戶主檔不寫條件。

## 3. 資料表清單與設計備忘

### 3.1 客戶資料 (customers)
*   **用途**: 記錄客戶的基本資料、聯絡方式與商業交易條件。
*   **關鍵欄位**:
    *   `code`: 客戶代號，全 Tenant 唯一，作為訂單與發票的識別碼。
    *   `tax_id`: 統一編號/稅號，稅務申報關鍵欄位。
    *   `currency_option_id`: 預設交易幣別，減少開立訂單時的輸入錯誤。
    *   付款條件不在客戶主檔；見 FI `business_partners.payment_term_id`。
    *   `credit_limit`: 信用額度，用於銷售流程中的信用控管 (Credit Check)。
    *   `sales_person_id`: 業務負責人，用於權限劃分 (Row-Level Security) 與業績歸屬。
*   **設計決策**:
    *   **地址分離**: 分開設計 `address_billing` (發票地址) 與 `address_shipping` (送貨地址)，滿足常見的商業情境。
    *   **聯絡人**: 目前採單一主要聯絡人設計 (`contact_person` 等欄位直接在主表)，若未來需多位聯絡人，可再擴充子表 `customer_contacts`。

## 4. 檔案路徑對照表

| 表格名稱 | SQL 定義檔路徑 | 說明 |
| :--- | :--- | :--- |
| **customers** | `docs/database/sql/schema_tables/CRM/customers.sql` | 客戶主檔 |


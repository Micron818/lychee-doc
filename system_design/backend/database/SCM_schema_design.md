# SCM (Supply Chain Management) 模組資料庫設計文件

> 欄位與路徑以 `sql/schema_tables` 及現行程式為準。  
> 原物料採購流程改造見 [chartExp/Purchase](../chartExp/Purchase/README.md)（目標流程 `02`、schema `03`、開發入口 `04`）。

## 1. 模組概述

SCM 負責供應商、請購、採購與委外訂單。P2P 前端與 **WM 收貨**、**FI 應付**銜接。

原物料（FO + MRP）與手工請購走兩條路徑，**不要合成一條 PR 必經鏈**：

```text
原物料:  MrpResult ──工作台──► Purchase Order（source_type=MRP）──► GR (WM) ──► AP
手工請購:  PR ──審核──► 待轉請購工作台──► PO（source_type=PURCHASE_REQUISITION）──► GR
空白開單:  列表新增──► PO（source_type=MANUAL，僅手鍵明細）
委外:     Outsource Order ──► 發料 / 收貨 (WM)
```

請購單 **只服務內部申請**（耗材、備件、非 MRP）。刪除 PR 上的 `source_type` / `mrp_run_id`；MRP 不再寫請購。

## 2. 實體關係圖 (ERD) 概念

*   **供應商**: `suppliers`。
*   **物料來源清單**: `material_suppliers`（廠 + 料 + 供應商），供工作台預填供應商與 PO 帶價。
*   **請購 (PR)**: `purchase_requisitions` / `purchase_requisition_items`。內部申請；無 MRP 來源列。
*   **採購 (PO)**: `purchase_orders` / `purchase_order_items`。對外合約；`supplier_id` 必填。
    `source_type`：`MRP` / `PURCHASE_REQUISITION` / `MANUAL`。僅 MRP 寫 `mrp_run_id`。
*   **委外**: `outsource_orders` / `items` / `components`。
*   **收貨 (GR)**: 表在 **WM**（`goods_receipts` / `goods_receipt_items`），不是 SCM schema。
*   **跨模組溯源（已落地）**: 統一 `order_peggings`（demand/supply 用單據類型 + **明細 id**）。  
    **沒有** `source_mrp_result_id`、`source_pr_item_id` 這類直連欄（舊文檔描述作廢，勿補回）。

Pegging 約定：

| 路徑 | demand | supply（均為明細 id） |
|------|--------|----------------------|
| 原物料轉 PO | `MRP_RESULT` | `PURCHASE_ORDER` |
| 手工 PR → PO | `PURCHASE_REQUISITION` | `PURCHASE_ORDER` |

收貨明細以 `source_doc_type` + `source_doc_item_id` 指向 PO / 委外等來源行，並連 `warehouses` 過帳庫存。

## 3. 資料表清單與設計備忘

### 3.1 供應商主檔 (`suppliers`)

記錄供應商基本資料、聯絡人與交易幣別。

*   **關鍵欄位**（與現行 SQL 一致）:
    *   `code`: 供應商代號，`(tenant_id, code)` 唯一。
    *   `tax_id`: 統一編號 / 稅號。
    *   `supplier_type`: 枚舉 `MATERIAL` / `CONSUMABLE` / `OUTSOURCE`（**不是** `supplier_type_option_id`）。
    *   `active_status`: 啟用狀態。
    *   `currency_option_id`: 預設交易幣別。
*   **沒有** `payment_terms` 文字欄。付款條件在 **PO 主檔** `payment_term_option_id`（option_values）。

### 3.2 物料供應商 (`material_suppliers`)

Source List + 簡版採購信息記錄。**不要**把預設供應商塞進 `materials` 或 `material_factories`。

*   業務鍵: `(tenant_id, factory_id, material_id, supplier_id)` 唯一。
*   同一 `(tenant, factory, material)` 最多一個 `is_default = true`（部分唯一索引）。
*   **關鍵欄位**: `is_default`、`purchase_unit_id`、`min_order_quantity`、`lead_time_days`（展示參考；MRP 提前期仍讀 `mrp_parameters`）、`last_price`、`currency_option_id`、`valid_from` / `valid_to`。
*   DDL 與解析規則見 [Purchase/03-schema設計.md](../chartExp/Purchase/03-schema设计.md)。

### 3.3 請購單 (`purchase_requisitions` / `purchase_requisition_items`)

內部請購。僅手工建立；MRP 不再落此表。

*   **表頭關鍵欄位**:
    *   `requester_id` / `department_id` / `factory_id`。
    *   **沒有** `source_type` / `mrp_run_id`（已廢除）。
    *   `status`: `DRAFT` / `APPROVED` / `PARTIAL` / `COMPLETED` / `CLOSED`。
*   **明細關鍵欄位**:
    *   `required_quantity` / `ordered_quantity`（已轉 PO 量）。
    *   `suggested_supplier_id`: 建議供應商（手工可填）。
    *   `required_date` / `latest_order_date`。
*   審核後的開量（`required − ordered`）可作為 MRP 預計入庫；**DRAFT 不計入**。

### 3.4 採購單 (`purchase_orders` / `purchase_order_items`)

對供應商的訂購合約。原物料由工作台按 `(factory_id, supplier_id)` 直接生成主檔 + 明細。

*   **表頭關鍵欄位**:
    *   `supplier_id`: **NOT NULL**，下單對象。
    *   `currency_option_id` & `exchange_rate`: 幣別與匯率快照。預設來自 BASIS `exchange_rates`；收貨複製本快照，不重查主檔。
    *   `payment_term_option_id`: 付款條件。
    *   `subtotal_amount` / `tax_amount` / `total_amount`。
    *   `source_type`: `MRP` | `PURCHASE_REQUISITION` | `MANUAL`。創建後不改。**不加**泛型 `source_id`。
    *   `mrp_run_id`: **僅** `source_type = MRP`；轉單當時的 Run 快照；`ON DELETE SET NULL`。
    *   `status`: `DRAFT` / `APPROVED` / `PARTIAL` / `COMPLETED` / `CLOSED`。
*   **明細關鍵欄位**:
    *   `unit_price` 及金額欄: 議定單價，AP 依據。工作台可帶來源清單 `last_price`，否則 0。
    *   `required_date` / `expected_delivery_date`（生成時必填，否則不算 MRP 供給）。
    *   `ordered_quantity` / `received_quantity` / `invoiced_quantity`。
    *   `is_unlimited_over_receipt` / `over_receipt_tolerance`。
    *   **沒有** `source_pr_item_id`；來源只走 `order_peggings`。

**DRAFT / APPROVED / PARTIAL** PO 開量進入 MRP 預計入庫（訂購 − 已收）。`CLOSED` / `COMPLETED` 排除。手工 DRAFT 同樣占需求。

### 3.5 委外訂單 (`outsource_orders` / `items` / `components`)

外包加工：表頭供應商 + 收回件明細 + 發料組件（`is_supplier_provided` 區分代料）。設計細節見 [委外加工系統設計](../chartExp/委外加工/委外加工系統設計.md)。

### 3.6 收貨單（WM，非 SCM 表）

P2P 的到貨過帳在 WM：`goods_receipts` / `goods_receipt_items`。

*   表頭: `delivery_note_no`（供應商送貨單號，三單匹配用）、`receipt_date`、`receipt_type`（含 `PURCHASE` / `OUTSOURCE` 等）、`status` = `DRAFT` / `POSTED` / `REVERSED`。
*   明細: `source_doc_type` + `source_doc_item_id` 指向採購/委外等來源行；`warehouse_id` 過帳庫存；`batch_no` / `expiry_date` 批次；幣別單價為來源快照。

## 4. 狀態（與程式枚舉對齊）

**請購 / 採購**（`PurchaseRequisitionStatus` / `PurchaseOrderStatus`）:

| 值 | 含義 |
|----|------|
| `DRAFT` | 草稿，可改。**PR 草稿不進 MRP 供給**；**PO 草稿進供給**（見 Purchase/02 §6.1） |
| `APPROVED` | 已核准 |
| `PARTIAL` | 部分轉單 / 部分收貨或發票 |
| `COMPLETED` | 數量已滿足 |
| `CLOSED` | 強制結案 |

沒有獨立的 `Pending Approval`、`Converted` 狀態值（PR 轉 PO 用明細 `ordered_quantity` + pegging，不是 header = CONVERTED）。

**收貨**（WM `GoodsReceiptStatus`）: `DRAFT` / `POSTED` / `REVERSED`（不是 Received / Cancelled）。

**PO `source_type`**: `MRP` / `PURCHASE_REQUISITION` / `MANUAL`。PR 不再有來源列。

## 5. 檔案路徑對照表

路徑相對於本檔所在目錄 `system_design/backend/database/`。

| 表格名稱 | SQL 定義檔 | 說明 |
| :--- | :--- | :--- |
| **suppliers** | `sql/schema_tables/SCM/suppliers.sql` | 供應商主檔（已落地） |
| **material_suppliers** | `sql/schema_tables/SCM/material_suppliers.sql` | 物料來源清單 |
| **purchase_requisitions** | `sql/schema_tables/SCM/purchase_requisitions.sql` | 請購表頭（無 MRP 來源列） |
| **purchase_requisition_items** | `sql/schema_tables/SCM/purchase_requisition_items.sql` | 請購明細 |
| **purchase_orders** | `sql/schema_tables/SCM/purchase_orders.sql` | 採購表頭（`source_type` + `mrp_run_id`） |
| **purchase_order_items** | `sql/schema_tables/SCM/purchase_order_items.sql` | 採購明細 |
| **outsource_orders** | `sql/schema_tables/SCM/outsource_orders.sql` | 委外表頭 |
| **outsource_order_items** | `sql/schema_tables/SCM/outsource_order_items.sql` | 委外收回明細 |
| **outsource_order_components** | `sql/schema_tables/SCM/outsource_order_components.sql` | 委外發料組件 |
| **goods_receipts** | `sql/schema_tables/WM/goods_receipts.sql` | 收貨表頭（WM） |
| **goods_receipt_items** | `sql/schema_tables/WM/goods_receipt_items.sql` | 收貨明細（WM） |
| **order_peggings** | 共通表（非 SCM 目錄） | 供需溯源 |

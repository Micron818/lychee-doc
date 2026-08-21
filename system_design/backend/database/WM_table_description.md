# WM (Warehouse Management) 模組資料表說明

## 1. 收貨作業 (Goods Receipt)

### 1.1 收貨單主表 (goods_receipts)
- **supplier_id**: 關聯供應商，採購收貨必填。
- **delivery_note_no**: 外部送貨單號，用於實務核對。
- **status**: `DRAFT` (編輯中), `POSTED` (已過帳/生效), `CANCELLED` (作廢)。

### 1.2 收貨單明細表 (goods_receipt_items)
- **source_doc_id / type**: 來源追蹤。支援 `PURCHASE_ORDER_ITEM`, `PRODUCTION_REPORT`, `CUSTOMER_RETURN_ITEM` 等。
- **batch_no**: 批號維度，預設為空字串。
- **is_foc**: 贈品標記，影響 AP 核銷邏輯。
- **transaction / base_unit**: 雙單位設計。`transaction` 為單據單位，`base` 為庫存結算基本單位。
- **expiry_date**: 批號有效期限，支援 FEFO 邏輯。
- **stock_type**: 庫存狀態。`UNRESTRICTED` (可用), `INSPECTION` (待檢), `BLOCKED` (凍結)。

---

## 2. 領料作業 (Stock Issue)

### 2.1 領料單主表 (stock_issues)
- **department_id**: 費用歸屬的成本中心。
- **issue_type**: 領料性質。`PRODUCTION` (生產), `COST_CENTER` (部門), `SCRAP` (報廢), `SAMPLE` (樣品)。
- **status**: `DRAFT`, `POSTED`, `CANCELLED`。

### 2.2 領料單明細表 (stock_issue_items)
- **source_doc_id / type**: 關聯來源，如 `PRODUCTION_ORDER_COMPONENT` 用於核銷工單預留量。
- **returned_quantity**: 已過賬退料基本單位合計。可退數量 = `base_quantity - returned_quantity`。

### 2.3 退料單 (stock_issue_returns / items)
內部領料的反向單，不是客戶退貨或採購退貨。
- **original_stock_issue_id**: 一張退料單只對應一張已過賬領料單。
- **return_type**: `PRODUCTION`, `COST_CENTER`, `SAMPLE`。
- **original_issue_item_id**: 必須參照原領料明細。
- **stock_type**: 退回庫存狀態。`UNRESTRICTED`, `INSPECTION`, `BLOCKED`。
- 流水類型為 `STOCK_ISSUE_RETURN`；領料沖銷仍寫 `STOCK_ISSUE`。

---

## 3. 庫存帳務與即時庫存

### 3.1 即時庫存表 (stock_on_hand)
以 `material` + `warehouse` + `batch_no` 為核心索引。
- **available_quantity**: 帳面可用數。
- **reserved_quantity**: 已鎖定但未出庫數 (如訂單/工單預留)。
- **blocked / qa_quantity**: 凍結與待檢數量，不計入可用數。
- **location_code**: 儲位代碼。

### 3.2 庫存異動流水帳 (stock_transactions)
所有庫存變動的 Source of Truth。
- **transaction_type**: 異動類型。`GOODS_RECEIPT`, `PRODUCTION_RECEIPT`, `VENDOR_RETURN`, `DELIVERY`, `CUSTOMER_RETURN`, `STOCK_ISSUE`, `STOCK_ISSUE_RETURN`, `ADJUSTMENT`, `STOCK_TRANSFER`, `BACKFLUSH`。冲销沿用原过账类型。
- **before / in / out / after_quantity**: 數量變動軌跡，確保帳務連續性。
- **unit_cost / total_amount**: 異動當下的成本與金額，用於庫存估值。
- **source_doc_id / type**: 追溯至觸發異動的原始單據。

# FI (Financial Accounting) 模組資料庫設計文件

## 1. 模組概述

FI 模組負責管理企業的財務會計核心，包含總帳 (General Ledger)、會計期間管理、會計分錄 (Journal Entry)、應收/應付子帳 (AR/AP)、收付款、固定資產 (Fixed Assets) 與成本計算 (Costing)。此模組接收來自各業務模組 (SCM, SD, MM, WM) 的交易資訊，產出財務報表。

**多公司設計原則**

| 層級 | 資料表 | 說明 |
| :--- | :--- | :--- |
| Tenant 級共享 | `gl_accounts`, `asset_categories`, `business_partners` | 科目表、資產類別、往來單位主檔跨公司共用 |
| Company 級 | `fiscal_periods`, 傳票、發票、收付款、固定資產、成本結算等 | 均含 `company_id`，與 `fiscal_periods.company_id` 對齊 |

**跨模組整合原則**

*   `business_partners` 作為 FI 往來單位統一入口，`source_id` 指向 SCM `suppliers` 或 SD `customers`；基礎資料由 SCM/SD 同步，財務屬性由 FI 維護。
*   發票/收付款明細保留 `source_doc_type` / `source_doc_id` / `source_line_id`，支援從業務單據到 GL 憑證的全程追溯。
*   單據表頭/明細均寫入 `partner_code` / `partner_name` 等快照欄位，歷史單據不受主檔變更影響。

## 2. 實體關係圖 (ERD) 概念

```
gl_accounts ─────────────────────────────────────────────────────┐
     │                                                           │
     ├── asset_categories ── fixed_assets ── asset_depreciations │
     ├── company_bank_accounts                                   │
     └── business_partners ── partner_bank_accounts              │
              │                                                  │
              ├── ap_invoices ── ap_invoice_lines                │
              ├── ap_credit_memos ── ap_credit_memo_lines        │
              ├── ar_invoices ── ar_invoice_lines                │
              ├── ar_credit_memos ── ar_credit_memo_lines        │
              └── payments ── payment_lines                      │
                                                                 │
fiscal_periods ── journal_entries ── journal_entry_lines ────────┘
                      ▲                    │
                      │                    └── department_id → departments (BASIS)
                      │
         (過帳關聯) ap/ar_invoices, payments,
                    asset_depreciations, cost_calculations

cost_calculations ── cost_calculation_items
                 ├── material_costs
                 └── cost_allocations
```

**子域摘要**

*   **科目管理**: `gl_accounts` 支援 `parent_id` 階層結構 (tenant 級)。
*   **稅碼子域**: `tax_classes`（物料/往來稅分類）+ `tax_codes` / `tax_code_rates` + `tax_determinations`（含 `country_code`）。開單判定寫入行上 `tax_code_id` + `tax_rate` 快照；稅行 GL 優先用稅碼覆蓋，否則回退 `INPUT_TAX` / `OUTPUT_TAX`。不可抵扣進項必須有 `input_gl_account_id`，禁止回退 `INPUT_TAX`。
*   **科目判定**: `valuation_classes` + `fi_account_determination`（company + posting_key + valuation_class → GL）；採購側 GR/IR 與 AP 發票、銷售側 AR 收入/銷項稅與發料 COGS/WIP 共用同一判定引擎。
    *   採購鍵：`INV_STOCK`, `GRIR`, `INPUT_TAX`, `EXPENSE`, `PRICE_VAR`, `CIP`（資本性採購借在建工程）
    *   **存貨判定 SSOT**: 執行期（GR 庫存／倉庫、GR/IR、發料）只認 `valuation_classes.is_inventoried`；`material_types.is_inventoried` 僅約束類型↔評估類映射必須同值。
    *   銷售/發料鍵：`REVENUE`（AR 行貸方）、`OUTPUT_TAX`（銷項）、`COGS`（銷售發料借方）、`WIP`（生產領料借方；貸方仍用 `INV_STOCK`）
*   **成本政策**: `fi_costing_policies`（公司默認 `cost_method`、差異結轉、製造費用吸收基準、關帳是否強制已過帳 Cost Run）。
*   **傳票結構**: Header-Line 結構；表頭彙總借貸金額供快速平衡校驗；明細含輔助核算維度 (部門、往來、來源行)。
*   **期間控制**: `fiscal_periods` 管理會計年度與月份（含 `company_id`），控制 FI 關帳。
*   **子帳管理 (Sub-Ledger)**: `ap_invoices` / `ap_credit_memos` / `ar_invoices` / `ar_credit_memos` 表頭 + 明細行，記錄未清餘額、稅額與到期日。應付貸項過帳核銷原票 `remaining` 並回減收貨占用；應收貸項過帳拆 applied/refundable 並回減交貨占用。
*   **收付核銷**: `payments` 表頭記錄資金進出與銀行帳戶快照；`payment_lines` 明細支援發票核銷、預收/預付抵扣、直接記帳 (手續費/匯兌損益)。
*   **固定資產 (FA)**: `asset_categories` → `fixed_assets` → `asset_depreciations`；折舊/取得/處分均透過 `journal_entry_id` 連結總帳 (`source_module = 'FA'`)。
*   **成本計算 (Costing)**: 日常以 `STANDARD_COST` 出庫；月末 `cost_calculations` → items/allocations → `ACTUAL_COST` 快照；過帳 `source_module = 'COSTING'`。`MOVING_AVERAGE` 預留未實現。

## 3. 資料表清單與設計備忘

### 3.1 會計科目 (gl_accounts)

*   **用途**: 定義會計科目表 (COA)，tenant 級共享。
*   **關鍵欄位**:
    *   `code` / `name`: 科目代碼與名稱。
    *   `account_type`: 科目類別 (`ASSET`, `LIABILITY`, `EQUITY`, `REVENUE`, `EXPENSE`, `CASH`)。
    *   `parent_id`: 上層科目，支援多層 COA 階層。
    *   `is_reconciliation`: 是否為統制科目；若為 true，連結 AR/AP 子帳，不允許直接手動過帳。
    *   `is_active`: 是否啟用。
*   **唯一约束**: `(tenant_id, code)`。

### 3.2 會計期間 (fiscal_periods)

*   **用途**: 定義會計年度與期數，用於控管過帳期間與 FI 關帳。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `fiscal_year` / `period_no`: 會計年度與期數。
    *   `start_date` / `end_date`: 期間起迄日。
    *   `is_closed` / `closed_at` / `closed_by`: 關帳狀態與操作紀錄。
*   **唯一约束**: `(tenant_id, company_id, fiscal_year, period_no)`。

### 3.3 往來單位 (business_partners)

*   **用途**: FI 模組統一的客戶/供應商主檔，橋接 SCM/SD 與 AR/AP 子帳。
*   **關鍵欄位**:
    *   `partner_type`: `CUSTOMER`, `SUPPLIER`。
    *   `source_id`: 關聯 SCM `suppliers.id` 或 SD `customers.id`。
    *   `partner_code` / `partner_name` / `tax_id`: 從 SCM/SD 同步的基礎資料副本（FI 只讀）。
    *   `gl_account_id`: 預設應收/應付統制科目（FI 維護）。
    *   `payment_term_id`: 財務核准的付款條件（FK `fi_payment_terms`）。
    *   `credit_limit`: 信用額度。
    *   `status`: `ACTIVE`, `INACTIVE`。
*   **設計決策**: 基礎資料與財務屬性分離——SCM/SD 負責主檔，FI 負責科目、付款條件、信用控管。
*   **唯一约束**: `(tenant_id, partner_type, source_id)`。

### 3.3.1 付款條件 (fi_payment_terms / fi_payment_term_lines)

*   **用途**: 獨立主檔，取代 ADM `PAYMENT_TERM` 選項。條件行展開為發票排程。
*   **頭關鍵欄位**:
    *   `code` / `name`: 短碼與名稱，`(tenant_id, code)` 唯一。
    *   `base_date_type`: `INVOICE_DATE` / `SOURCE_DATE`。
    *   `partner_scope`: `BOTH` / `CUSTOMER` / `SUPPLIER`。
    *   `is_active`: 是否啟用。
*   **行關鍵欄位**:
    *   `percent`: 占發票 `total_amount` 比例，合計必須 `100.00`。
    *   `calc_method`: `IMMEDIATE` / `NET_DAYS` / `EOM_PLUS_DAYS` / `FIXED_DAY`。
    *   `days` / `extra_months` / `fixed_day`: 到期日算法參數。
    *   `discount_percent` / `discount_days`: 現金折扣；截止日 = 基準日 + 折扣天數。
*   **設計決策**: 不解析選項名稱；缺條件拒絕開單/立帳；公司 `default_payment_term_id` 僅新建 BP 帶出。

### 3.3.2 發票付款排程 (ap_invoice_schedules / ar_invoice_schedules)

*   **用途**: 發票到期真相。表頭 `due_date` 派生自 `MAX(排程.due_date)`。
*   **關鍵欄位**: `percent` / `amount` / `due_date` / `due_date_overridden` / 折扣快照。
*   **唯一约束**: `(tenant_id, invoice_id, line_no)`。

### 3.4 公司銀行帳戶 (company_bank_accounts)

*   **用途**: 定義公司內部資金帳戶（銀行帳戶或現金/備用金），供收付款過帳使用。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `account_code` / `account_name`: 內部編碼與顯示名稱。
    *   `account_type`: `BANK` (銀行帳戶), `CASH` (現金/備用金)。
    *   `bank_name` / `bank_branch` / `account_no` / `account_holder`: 銀行資訊（`BANK` 類型必填）。
    *   `currency_option_id`: 帳戶幣別。
    *   `gl_account_id`: 對應銀行/現金 GL 科目（過帳子分類帳）。
    *   `is_default`: 是否為該公司該幣種的預設帳戶。
    *   `swift_code` / `bank_code`: 銀企直聯可選欄位。
    *   `status`: `ACTIVE`, `INACTIVE`。
*   **唯一约束**: `(tenant_id, company_id, account_code)`。

### 3.5 往來銀行帳戶 (partner_bank_accounts)

*   **用途**: 記錄客戶/供應商的收款/付款銀行帳戶。
*   **關鍵欄位**:
    *   `partner_id`: 關聯 `business_partners.id`。
    *   `bank_name` / `bank_branch` / `account_no` / `account_name`: 銀行帳戶資訊。
    *   `currency_option_id`: 帳戶幣別。
    *   `is_default`: 是否為預設收款帳戶。
    *   `status`: `ACTIVE`, `INACTIVE`。

### 3.6 會計傳票 (journal_entries)

*   **用途**: 財務交易的憑證表頭。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `journal_no`: 傳票編號；`(tenant_id, company_id, journal_no)` 唯一。
    *   `journal_date` / `document_date` / `post_date`: 傳票日期、單據日期、過帳日期。
    *   `fiscal_period_id`: 所屬會計期間。
    *   `currency_id` / `local_currency_id` / `exchange_rate`: 原幣、本幣與匯率快照。開單預設來自 BASIS `exchange_rates`；過帳後凍結，不隨主檔變更。
    *   `total_debit` / `total_credit` / `local_total_debit` / `local_total_credit`: 表頭彙總金額，供快速校驗借貸必相等。
    *   `journal_type`: `AUTO` (系統產生), `MANUAL` (手工錄入)。
    *   `source_module`: 來源模組 (`GL`, `AR`, `AP`, `FA`, `IN`, `CASH`, `COSTING`)。
    *   `source_doc_type` / `source_doc_id` / `reference_no`: 來源單據追溯。
    *   `reversal_entry_id`: 沖銷關聯（被沖銷或沖銷憑證 ID）。
    *   `status`: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `POSTED`, `VOIDED`, `REVERSED`。

### 3.7 傳票明細 (journal_entry_lines)

*   **用途**: 記錄借貸方金額與輔助核算維度。
*   **關鍵欄位**:
    *   `gl_account_id` / `account_code`: 科目 ID 與代碼快照。
    *   `debit_amount` / `credit_amount`: 原幣金額。
    *   `local_debit_amount` / `local_credit_amount`: 本幣金額。
    *   `department_id`: 成本中心歸屬（連結 BASIS `departments`）。
    *   `partner_type` / `partner_id` / `partner_code` / `partner_name`: 往來單位輔助核算。
    *   `source_line_id`: 來源單據明細行 ID（如 `ar_invoice_lines.id`）。
*   **唯一约束**: `(tenant_id, journal_entry_id, line_no)`。

### 3.8 應付帳款發票 (ap_invoices)

*   **用途**: 記錄來自供應商的發票，作為 AP 立帳依據。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `code`: 內部單據編號（如 AP-202606-0001）。
    *   `external_invoice_no`: 供應商稅務發票號。
    *   `invoice_date` / `due_date`: 開票日與到期日（帳齡分析）。`due_date` 為 `MAX(ap_invoice_schedules.due_date)`，禁止手改。
    *   `payment_term_id` / `base_date`: 付款條件與排程基準日。
    *   `partner_id` / `partner_code` / `partner_name`: 關聯 `business_partners` 及快照。
    *   `currency_option_id` / `exchange_rate`: 幣別與匯率。
    *   `subtotal_amount` / `tax_amount` / `total_amount`: 金額彙總。
    *   `paid_amount` / `credited_amount` / `applied_credit_amount` / `remaining_amount`: 已付、已过账未作废贷项总额、其中冲减未付金额、剩餘未付。`remaining = total − paid − applied_credit_amount`。`credited_amount` 不再進入 remaining 公式。
    *   `invoice_status`: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `POSTED`, `VOIDED`。
    *   `payment_status`: `UNPAID`, `PARTIAL`, `PAID`。
    *   `journal_entry_id`: 過帳憑證。
    *   審批/過帳/作廢：`approved_at/by`, `posted_at/by`, `voided_at/by`。
*   **唯一约束**:
    *   `(tenant_id, company_id, code)`
    *   `(tenant_id, company_id, partner_id, external_invoice_no)` — 同一供應商不可重複登錄相同稅務發票號。

### 3.8b 應付貸項 (ap_credit_memos)

*   **用途**: 獨立 FI 單據，一對一已過帳 AP 發票。數量與金額為正數，過帳時借應付、貸 GR/IR（及稅/價差），全額核銷該票剩餘並回減收貨 `invoiced_quantity`。
*   **關鍵欄位**:
    *   `original_ap_invoice_id`: 原應付發票（必須 `POSTED`）。
    *   `credit_date` / `external_credit_note_no`: 貸項日期與供應商貸項號（提交前須替換草稿占位符）。
    *   夥伴 / 幣別 / 匯率：從原票快照，貸項日不重估。
    *   `invoice_status`: 與 AP 相同的 `FiDocumentStatus`；VOID 僅允許 `POSTED → VOIDED`。
    *   `applied_amount` / `refundable_amount`：過帳時拆分的衝未付與待退款；`refunded_amount` / `refund_remaining_amount` / `refund_status` 由供應商退款回寫。
    *   `journal_entry_id`: `source_doc_type = AP_CREDIT_MEMO`。
*   **明細 `ap_credit_memo_lines`**: 來源為原 AP 行；只改數量 / 票面稅額 / 備註。已成卡行禁止納入。唯一约束 `(tenant_id, credit_memo_id, line_no)`、`(tenant_id, credit_memo_id, original_ap_invoice_line_id)`。
*   **唯一约束**:
    *   `(tenant_id, company_id, code)`
    *   `(tenant_id, company_id, partner_id, external_credit_note_no)`

### 3.9 應付發票明細 (ap_invoice_lines)

*   **用途**: 記錄 AP 發票行項目，支援三單匹配與稅務合規。
*   **關鍵欄位**:
    *   `description`: 發票票面貨物/服務名稱（支援無物料號的雜項費用）。
    *   `quantity` / `unit_price` / `line_amount`: 數量與單價。
    *   `tax_code_id` / `tax_rate` / `tax_amount` / `tax_amount_overridden` / `total_amount`: 稅碼與開單日稅率快照；票面可覆蓋稅額。
    *   `gl_account_id` / `department_id`: 費用/庫存科目與成本中心。
    *   `source_doc_type`: `RECEIPT`, `PURCHASE_ORDER`。
    *   `source_doc_id` / `source_doc_no` / `source_line_id` / `source_line_no`: 來源單據追溯。
    *   `material_id` / `material_code` / `material_name` / `uom_code`: 物料關聯（可選）與快照。
*   **唯一约束**: `(tenant_id, invoice_id, line_no)`。

### 3.10 應收帳款發票 (ar_invoices)

*   **用途**: 開立給客戶的發票，作為 AR 立帳依據。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `code`: 內部單據編號。
    *   `tax_invoice_no`: 稅務發票號。
    *   `invoice_date` / `due_date`: 開票日與到期日。`due_date` 為 `MAX(ar_invoice_schedules.due_date)`，禁止手改。
    *   `payment_term_id` / `base_date`: 付款條件與排程基準日。
    *   `partner_id` / `partner_code` / `partner_name`: 關聯 `business_partners` 及快照。
    *   `currency_option_id` / `exchange_rate`: 幣別與匯率。
    *   `subtotal_amount` / `tax_amount` / `total_amount`: 金額彙總。
    *   `received_amount` / `credited_amount` / `applied_credit_amount` / `remaining_amount`: 已收、已過帳貸項總額、實際衝減未收、剩餘未收。`remaining = total − received − applied_credit`。
    *   `invoice_status`: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `POSTED`, `VOIDED`。
    *   `receipt_status`: `UNRECEIVED`, `PARTIAL`, `RECEIVED`。
    *   `journal_entry_id`: 過帳憑證。
*   **唯一约束**: `(tenant_id, company_id, code)`。

### 3.10b 應收貸項 (ar_credit_memos)

*   **用途**: 獨立 FI 單據，一對一已過帳 AR 發票。數量與金額為正數，過帳時貸應收、借收入/銷項稅，拆 `applied` / `refundable` 並回減交貨 `invoiced_quantity`。
*   **關鍵欄位**:
    *   `original_ar_invoice_id`: 原應收發票（必須 `POSTED`）。
    *   `credit_date` / `tax_credit_note_no`: 貸項日期與稅務貸項號（提交前須替換草稿占位符）。
    *   夥伴 / 幣別 / 匯率：從原票快照，貸項日不重估。
    *   `invoice_status`: 與 AR 相同的 `FiDocumentStatus`；VOID 僅允許 `POSTED → VOIDED`。
    *   `applied_amount` / `refundable_amount`：過帳時拆分的衝未收與待退款；`refunded_amount` / `refund_remaining_amount` / `refund_status` 預留給客戶退款回寫。
    *   `journal_entry_id`: `source_doc_type = AR_CREDIT_MEMO`。
*   **明細 `ar_credit_memo_lines`**: 來源為原 AR 行；只改數量 / 票面稅額 / 備註。最後一筆貸完該 AR 行時金額取剩餘。唯一约束 `(tenant_id, credit_memo_id, line_no)`、`(tenant_id, credit_memo_id, original_ar_invoice_line_id)`。
*   **唯一约束**:
    *   `(tenant_id, company_id, code)`
    *   `(tenant_id, company_id, partner_id, tax_credit_note_no)`

### 3.11 應收發票明細 (ar_invoice_lines)

*   **用途**: 記錄 AR 發票行項目。
*   **關鍵欄位**: 結構與 `ap_invoice_lines` 類似。
    *   `source_doc_type`: `SALES_ORDER`, `SHIPMENT`。
    *   其餘：`description`, 數量/單價, `tax_code_id` / `tax_rate` / `tax_amount` / `tax_amount_overridden`, `gl_account_id`, `department_id`, 物料快照等。
*   **唯一约束**: `(tenant_id, invoice_id, line_no)`。

### 3.12 收付款單 (payments)

*   **用途**: 記錄實際的資金進出 (收款/付款)。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `payment_no`: 收付款編號。
    *   `payment_type`: `RECEIPT` (收款), `DISBURSEMENT` (付款)。
    *   `payment_purpose`: `STANDARD`（標準收付款）、`SUPPLIER_REFUND`（供應商退款，固定 `RECEIPT + SUPPLIER`）。
    *   `payment_date`: 收付日期。
    *   `partner_type` / `partner_id` / `partner_code` / `partner_name`: 往來對象。
    *   `partner_bank_account_id` + 銀行快照欄位 (`partner_bank_name`, `partner_account_no` 等): 對方帳戶，提交/過帳時寫入快照。
    *   `internal_bank_account_id` + 銀行快照欄位: 公司內部資金帳戶。
    *   `currency_option_id` / `exchange_rate` / `amount`: 幣別、匯率與交易金額。
    *   `unallocated_amount`: 未核銷餘額（預收/預付款場景）。
    *   `is_prepayment`: 是否為預收/預付款。
    *   `payment_method`: `BANK_TRANSFER`, `CHECK`, `CASH`。
    *   `reference_no`: 外部流水號/支票號/網銀交易號。
    *   `status`: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `POSTED`, `VOIDED`。
    *   `journal_entry_id`: 過帳憑證。
*   **唯一约束**: `(tenant_id, company_id, payment_no)`。

### 3.13 收付明細/核銷 (payment_lines)

*   **用途**: 記錄收付款單的核銷明細，取代舊版 `payment_allocations` 的純沖銷設計，支援更豐富的場景。
*   **設計決策**:
    *   一張收付款可核銷多張發票（部分付款/合併付款）。
    *   支援預收/預付抵扣 (`PREPAYMENT`)。
    *   支援直接記帳行 (`GL_ACCOUNT`)，如銀行手續費、匯兌損益。
*   **關鍵欄位**:
    *   `allocation_type`: `INVOICE` (核銷發票), `GL_ACCOUNT` (直接記帳), `PREPAYMENT` (核銷預付款), `AP_CREDIT_MEMO` (供應商退款核銷應付貸項)。
    *   `ar_invoice_id` / `ap_invoice_id`: 被核銷的發票（二選一）。
    *   `ap_credit_memo_id`: 供應商退款核銷的應付貸項。
    *   `ap_invoice_schedule_id` / `ar_invoice_schedule_id`: 可空；若填則必須與同行發票同屬一張票。
    *   `applied_payment_id`: 被抵扣的歷史預付款單 ID。
    *   `allocated_amount`: 本次核銷金額。
    *   `discount_amount`: 現金折扣金額（如提前付款折扣）。
    *   `gl_account_id` / `department_id`: 對應應收/應付科目，或直接記帳的費用科目。
    *   `journal_entry_id`: 折扣 / `GL_ACCOUNT` 核銷調整憑證，或供應商退款匯兌憑證（純 `INVOICE` 行為 NULL；銀行資金憑證在 `payments.journal_entry_id`）。
    *   退款核銷匯兌快照：`source_exchange_rate` / `source_base_amount` / `settlement_base_amount` / `exchange_difference_amount`。
*   **唯一约束**: `(tenant_id, payment_id, line_no)`。

### 3.14 資產類別 (asset_categories)

*   **用途**: 定義資產分類、預設折舊參數與會計科目配置（tenant 級主檔）。
*   **關鍵欄位**:
    *   `depreciation_method`: 折舊方法 (`STRAIGHT_LINE`, `DECLINING_BALANCE`)。
    *   `useful_life_months`: 耐用年限（月），支援按月中途購入。
    *   `depreciation_rate`: 餘額遞減法折舊率；直線法可為 NULL。
    *   `salvage_rate`: 類別預設殘值率。
    *   `asset_account_id`: 資產科目。
    *   `depreciation_account_id`: 折舊費用科目。
    *   `accumulated_depreciation_account_id`: 累計折舊科目。
    *   `disposal_gain_loss_account_id`: 資產處置損益科目（出售／報廢）。
    *   `is_active`: 是否啟用。
*   **唯一约束**: `(tenant_id, code)`。

### 3.15 固定資產 (fixed_assets)

*   **用途**: 記錄資產卡片資料。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `asset_category_id`: 關聯資產類別，決定預設折舊方法與會計科目。
    *   `acquisition_date` / `start_depreciation_date`: 取得日與開始折舊日。
    *   `original_value` / `salvage_value`: 取得成本與殘值。
    *   `current_value` / `accumulated_depreciation`: 帳面價值與累計折舊（由應用層與折舊 run 同步維護）。
    *   `depreciation_method` / `useful_life_months`: 卡片級覆寫；NULL 表示沿用 `asset_categories` 預設。
    *   `location` / `department_id` / `custodian_id`: 存放地點、歸屬部門與保管人。
    *   `status`: `ACTIVE`, `DISPOSED`, `SOLD`, `FULLY_DEPRECIATED`。
    *   `acquisition_journal_entry_id`: 資本化取得傳票。
    *   `ap_invoice_id` / `ap_invoice_line_id` / `split_no`: 自 AP 行手動生成時的來源追溯；同一行可依 `quantity` 拆成多卡（`split_no` 1..N），唯一約束 `(tenant_id, ap_invoice_line_id, split_no)`。
    *   `disposal_date` / `disposal_amount` / `disposal_gain_loss`: 處分資訊。
    *   `disposal_journal_entry_id` / `disposed_at` / `disposed_by`: 處分傳票與操作紀錄。
*   **唯一约束**: `(tenant_id, company_id, code)`。

### 3.16 資產折舊 (asset_depreciations)

*   **用途**: 記錄每一會計期間對單一資產提列的折舊。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `fixed_asset_id` / `fiscal_period_id`: 資產與會計期間。
    *   `depreciation_date`: 折舊日期（應落在 `fiscal_periods` 區間內）。
    *   `depreciation_amount`: 當期折舊金額。
    *   `accumulated_depreciation_after`: 本期計提後累計折舊（審計追溯）。
    *   `status`: `DRAFT`, `POSTED`, `VOIDED`。
    *   `journal_entry_id`: 自動產生的折舊傳票。
*   **唯一约束**: `(tenant_id, fixed_asset_id, fiscal_period_id)` — 防止同一資產同一期間重複計提。

### 3.17 成本結算作業 (cost_calculations)

*   **用途**: 記錄每個會計期間執行的成本結算 (Cost Run) 批次主檔。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `fiscal_period_id`: 結算的 FI 會計期間。
    *   `inventory_period_id`: 可選，關聯 WM `inventory_periods`（追溯用）；WM 重開門禁按公司+會計期檢查活躍 Cost Run，須財務先 `invalidate`。
    *   `run_no` / `run_date`: 批次編號與執行時間。
    *   `cost_method`: `STANDARD_COST`, `MOVING_AVERAGE`, `ACTUAL_COST`。
    *   `status`: `DRAFT`, `FINALIZED`, `POSTED`, `INVALIDATED`。
    *   `is_posted` / `journal_entry_id` / `posted_at` / `posted_by`: 過帳標記（`is_posted` 與 `status=POSTED` 同步）與 GL 憑證。
*   **唯一约束**: `(tenant_id, company_id, fiscal_period_id, run_no)`。

### 3.18 成本結算明細 (cost_calculation_items)

*   **用途**: 記錄該次 Cost Run 中，每個物料的成本計算過程與結果。
*   **關鍵欄位**:
    *   `cost_calculation_id` / `material_id`: 所屬 run 與物料。
    *   `opening_qty` / `receipt_qty` / `issue_qty` / `closing_qty`: 數量明細（與 WM 庫存異動對帳）。
    *   `opening_stock_value` / `receipt_value` / `issue_value` / `closing_stock_value`: 金額明細。
    *   `calculated_unit_cost`: 本期計算出的單位成本。
    *   `material_cost` / `labor_cost` / `overhead_cost`: 料/工/費結構。
    *   `variance_amount`: 標準成本與實際成本差異。
*   **唯一约束**: `(cost_calculation_id, material_id)`。

### 3.19 物料成本 (material_costs)

*   **用途**: 記錄各公司、各期間物料的單位成本。
*   **雙軌語義**:
    *   `STANDARD_COST`：日常收發貨/發料计价依據（可手工維護，`cost_calculation_id` 可為 NULL）。
    *   `ACTUAL_COST`：月末 Cost Run 快照，供分析與差異；**默認不參與出庫取價**。
    *   `MOVING_AVERAGE`：預留，本期不實現引擎。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `material_id` / `fiscal_period_id`: 物料與成本期間。
    *   `cost_calculation_id`: 來源 Cost Run；手工維護標準成本時可為 NULL。
    *   `cost_method`: `STANDARD_COST`, `MOVING_AVERAGE`, `ACTUAL_COST`。
    *   `unit_cost`: 總單位成本（料+工+費，由應用層保證一致性）。
    *   `material_cost` / `labor_cost` / `overhead_cost`: 成本結構分析。
    *   `is_active`: 是否為當前生效版本。
    *   `calculated_at`: 計算/更新時間。
*   **唯一约束**: `(tenant_id, company_id, material_id, fiscal_period_id, cost_method)`。

### 3.19a 成本政策 (fi_costing_policies)

*   **用途**: 公司級成本會計政策（一公司一行）。
*   **關鍵欄位**:
    *   `default_cost_method`: 日常取價方法（製造默認 `STANDARD_COST`）。
    *   `variance_settlement`: 首版 `FULL_TO_PL`。
    *   `oh_absorption_basis`: 首版 `LABOR_HOURS`。
    *   `require_posted_cost_run_on_close`: 關帳前是否強制已過帳 Cost Run。
    *   `require_standard_cost_on_stock_post`: 日常庫存過帳是否強制有效標準成本並拋評價分錄；`false` 為數量記帳（見 [08.1-未上线成本时库存过账.md](../chartExp/财务/08.1-未上线成本时库存过账.md)）。預設 `true`。

### 3.20 費用分攤 (cost_allocations)

*   **用途**: 記錄某次 Cost Run 中部門間的費用分攤 (Allocation)。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司。
    *   `cost_calculation_id`: 所屬 Cost Run（必填）。
    *   `fiscal_period_id`: 會計期間（冗餘，便於查詢）。
    *   `source_department_id`: 費用來源部門（可 NULL，表示公司級費用池）。
    *   `target_department_id`: 費用接收部門（必填）。
    *   `gl_account_id`: 被分攤的費用科目。
    *   `amount`: 分攤金額。
    *   `allocation_basis`: 分攤基礎 (`HEADCOUNT`, `FLOOR_AREA`, `MACHINE_HOURS`)。
    *   `basis_quantity` / `allocation_ratio`: 分攤基數與比例。

## 4. 關鍵枚舉值 (Application Constants)

FI 模組中下列欄位以 `varchar` 儲存，由應用層常數或 CHECK 約束維護：

### 4.1 科目類別 (gl_accounts.account_type)

*   `ASSET`, `LIABILITY`, `EQUITY`, `REVENUE`, `EXPENSE`, `CASH`

### 4.2 傳票類型 (journal_entries.journal_type)

*   `AUTO`, `MANUAL`

### 4.3 傳票狀態 (journal_entries.status)

*   `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `POSTED`, `VOIDED`, `REVERSED`

### 4.4 傳票來源模組 (journal_entries.source_module)

*   `GL`, `AR`, `AP`, `FA`, `IN`, `CASH`, `COSTING`

### 4.5 往來類型 (business_partners.partner_type / journal_entry_lines.partner_type / payments.partner_type)

*   `CUSTOMER`, `SUPPLIER`, `EMPLOYEE`（payments / journal_entry_lines 含 EMPLOYEE）

### 4.6 往來狀態 (business_partners.status)

*   `ACTIVE`, `INACTIVE`

### 4.7 銀行帳戶類型 (company_bank_accounts.account_type)

*   `BANK`, `CASH`

### 4.8 發票單據狀態 (ap_invoices / ar_invoices.invoice_status)

*   `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `POSTED`, `VOIDED`

### 4.9 AP 付款狀態 (ap_invoices.payment_status)

*   `UNPAID`, `PARTIAL`, `PAID`

### 4.10 AR 收款狀態 (ar_invoices.receipt_status)

*   `UNRECEIVED`, `PARTIAL`, `RECEIVED`

### 4.11 AP 明細來源 (ap_invoice_lines.source_doc_type)

*   `RECEIPT`, `PURCHASE_ORDER`

### 4.12 AR 明細來源 (ar_invoice_lines.source_doc_type)

*   `SALES_ORDER`, `SHIPMENT`

### 4.13 收付款類型 (payments.payment_type)

*   `RECEIPT`, `DISBURSEMENT`

### 4.14 付款方式 (payments.payment_method)

*   `BANK_TRANSFER`, `CHECK`, `CASH`

### 4.15 收付明細類型 (payment_lines.allocation_type)

*   `INVOICE`: 核銷發票。
*   `GL_ACCOUNT`: 直接記帳（手續費、匯兌損益等）。
*   `PREPAYMENT`: 核銷預收/預付款。
*   `AP_CREDIT_MEMO`: 供應商退款核銷應付貸項。

### 4.15b 收付款用途 (payments.payment_purpose)

*   `STANDARD`: 標準收款/付款。
*   `SUPPLIER_REFUND`: 供應商退款。

### 4.16 收付款狀態 (payments.status)

*   `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `POSTED`, `VOIDED`

### 4.17 折舊方法 (asset_categories / fixed_assets.depreciation_method)

*   `STRAIGHT_LINE`: 直線法。
*   `DECLINING_BALANCE`: 餘額遞減法（需配合 `depreciation_rate`）。

### 4.18 固定資產狀態 (fixed_assets.status)

*   `ACTIVE`, `DISPOSED`, `SOLD`, `FULLY_DEPRECIATED`

### 4.19 折舊計提狀態 (asset_depreciations.status)

*   `DRAFT`, `POSTED`, `VOIDED`

### 4.20 成本方法 (cost_calculations / material_costs.cost_method)

*   `STANDARD_COST`, `MOVING_AVERAGE`, `ACTUAL_COST`

### 4.21 成本結算狀態 (cost_calculations.status)

*   `DRAFT`, `FINALIZED`, `POSTED`, `INVALIDATED`

### 4.22 費用分攤基礎 (cost_allocations.allocation_basis)

*   `HEADCOUNT`, `FLOOR_AREA`, `MACHINE_HOURS`

## 5. 檔案路徑對照

| 資料表 | SQL 檔案路徑 |
| :--- | :--- |
| gl_accounts | `docs/database/sql/schema_tables/FI/gl_accounts.sql` |
| fiscal_periods | `docs/database/sql/schema_tables/FI/fiscal_periods.sql` |
| fi_payment_terms | `docs/database/sql/schema_tables/FI/fi_payment_terms.sql` |
| fi_payment_term_lines | `docs/database/sql/schema_tables/FI/fi_payment_term_lines.sql` |
| business_partners | `docs/database/sql/schema_tables/FI/business_partners.sql` |
| company_bank_accounts | `docs/database/sql/schema_tables/FI/company_bank_accounts.sql` |
| partner_bank_accounts | `docs/database/sql/schema_tables/FI/partner_bank_accounts.sql` |
| journal_entries | `docs/database/sql/schema_tables/FI/journal_entries.sql` |
| journal_entry_lines | `docs/database/sql/schema_tables/FI/journal_entry_lines.sql` |
| ap_invoices | `docs/database/sql/schema_tables/FI/ap_invoices.sql` |
| ap_credit_memos | `docs/database/sql/schema_tables/FI/ap_credit_memos.sql` |
| ap_credit_memo_lines | `docs/database/sql/schema_tables/FI/ap_credit_memo_lines.sql` |
| ap_invoice_schedules | `docs/database/sql/schema_tables/FI/ap_invoice_schedules.sql` |
| ap_invoice_lines | `docs/database/sql/schema_tables/FI/ap_invoice_lines.sql` |
| ar_invoices | `docs/database/sql/schema_tables/FI/ar_invoices.sql` |
| ar_credit_memos | `docs/database/sql/schema_tables/FI/ar_credit_memos.sql` |
| ar_credit_memo_lines | `docs/database/sql/schema_tables/FI/ar_credit_memo_lines.sql` |
| ar_invoice_schedules | `docs/database/sql/schema_tables/FI/ar_invoice_schedules.sql` |
| ar_invoice_lines | `docs/database/sql/schema_tables/FI/ar_invoice_lines.sql` |
| payments | `docs/database/sql/schema_tables/FI/payments.sql` |
| payment_lines | `docs/database/sql/schema_tables/FI/payment_lines.sql` |
| asset_categories | `docs/database/sql/schema_tables/FI/asset_categories.sql` |
| valuation_classes | `docs/database/sql/schema_tables/FI/valuation_classes.sql` |
| tax_classes | `docs/database/sql/schema_tables/FI/tax_classes.sql` |
| tax_codes | `docs/database/sql/schema_tables/FI/tax_codes.sql` |
| tax_code_rates | `docs/database/sql/schema_tables/FI/tax_code_rates.sql` |
| tax_determinations | `docs/database/sql/schema_tables/FI/tax_determinations.sql` |
| fi_account_determination | `docs/database/sql/schema_tables/FI/fi_account_determination.sql` |
| fixed_assets | `docs/database/sql/schema_tables/FI/fixed_assets.sql` |
| asset_depreciations | `docs/database/sql/schema_tables/FI/asset_depreciations.sql` |
| cost_calculations | `docs/database/sql/schema_tables/FI/cost_calculations.sql` |
| cost_calculation_items | `docs/database/sql/schema_tables/FI/cost_calculation_items.sql` |
| material_costs | `docs/database/sql/schema_tables/FI/material_costs.sql` |
| fi_costing_policies | `docs/database/sql/schema_tables/FI/fi_costing_policies.sql` |
| cost_allocations | `docs/database/sql/schema_tables/FI/cost_allocations.sql` |

## 6. SQL 部署順序

因外鍵依賴，建議按以下順序執行：

**主檔與期間**

1. `gl_accounts.sql`
2. `fiscal_periods.sql`
3. `fi_payment_terms.sql`
3a. `fi_payment_term_lines.sql`
3b. `business_partners.sql`
4. `partner_bank_accounts.sql`
5. `company_bank_accounts.sql`
5a. `tax_classes.sql`
5b. `tax_codes.sql`
5c. `tax_code_rates.sql`
5d. `tax_determinations.sql`

**總帳**

6. `journal_entries.sql`
7. `journal_entry_lines.sql`

**應收/應付**

8. `ap_invoices.sql`
8a. `ap_invoice_schedules.sql`
8b. `ap_credit_memos.sql`
8c. `ap_credit_memo_lines.sql`
9. `ap_invoice_lines.sql`
10. `ar_invoices.sql`
10a. `ar_invoice_schedules.sql`
10b. `ar_credit_memos.sql`
10c. `ar_credit_memo_lines.sql`
11. `ar_invoice_lines.sql`

**收付款**

12. `payments.sql`
13. `payment_lines.sql`

**固定資產**

14. `asset_categories.sql`
15. `fixed_assets.sql`
16. `asset_depreciations.sql`

**成本計算**

17. `cost_calculations.sql`
18. `cost_calculation_items.sql`
19. `material_costs.sql`
20. `fi_costing_policies.sql`（可与 material_costs 同批）
20. `cost_allocations.sql`

## 7. FI–WM 整合備忘

*   WM 以 `inventory_periods`（按 `factory_id`）控管庫存關帳；FI 以 `fiscal_periods`（按 `company_id`）控管財務關帳。
*   `cost_calculations.inventory_period_id` 可選關聯 WM 期間（追溯）。當 `inventory_periods` 重開時，系統按公司+會計期檢查是否仍有 `DRAFT`/`FINALIZED`/`POSTED` 的 Cost Run；有則拒絕重開，須財務先執行 `invalidate` 後方可 WM 重開，再強制重新跑成本結算後才能 FI 關帳。
*   詳細防呆流程見 `docs/chartExp/财务/01.控制库存与财务的关帐控制.md`。

## 8. AP 作業流程備忘

典型應付流程（詳見 `docs/chartExp/财务/03.实际作业流程发票-付款.md`）：

1. 收貨 → 2. 建立 AP 發票 (`ap_invoices` + `ap_invoice_lines`，過帳：借 費用/庫存，貸 應付帳款)
2. → 3. 付款審批 → 4. 建立付款單 (`payments`)
3. → 5. 付款核銷 (`payment_lines`，將付款與發票匹配，含現金折扣)
4. → 6. 過帳（借 應付帳款，貸 銀行存款，透過 `company_bank_accounts.gl_account_id` 定位銀行科目）

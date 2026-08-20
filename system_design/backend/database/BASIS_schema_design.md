# BASIS (System Basis) 模組資料庫設計文件

## 1. 模組概述
BASIS 模組主要定義企業的實體組織架構 (Organizational Structure)，如公司 (Company) 與工廠 (Factory)，以及跨模組共用的基礎主檔（匯率）。
註：系統基礎架構如多租戶 (Tenants)、使用者 (Users) 與通用選項 (Option Values) 由 **ADM 模組** 管理。幣別代碼屬 ADM `option_values`（`CURRENCY`）；公司本位幣與日匯率屬 BASIS。

## 2. 實體關係圖 (ERD) 概念

核心為 **公司 (Companies)** 與 **工廠 (Factories)**：

*   **公司 (Companies)**: 代表法律實體 (Legal Entity)，負責財務報表產出。
*   **工廠 (Factories)**: 代表生產或營運據點，歸屬於特定公司。
*   **匯率 (Exchange Rates)**: 公司級日匯率主檔，供 SD / SCM / WM / FI 開單時帶出預設匯率。單據表頭 `exchange_rate` 仍為快照，過帳後凍結。

```
companies.local_currency_id ──► option_values (CURRENCY)
        │
        └── exchange_rates.company_id
                ├── from_currency_id ──► option_values (CURRENCY)
                └── to_currency_id   ──► option_values (CURRENCY)  (= companies.local_currency_id)
```

## 3. 資料表清單與設計備忘

### 3.1 公司 (companies)
*   **用途**: 法律實體 (Legal Entity)。
*   **關鍵欄位**:
    *   `code`: 公司統編或代碼。
    *   `local_currency_id`: 本位幣（FK `option_values`）。現況預設 VND。

### 3.2 工廠 (factories)
*   **用途**: 生產或營運據點。
*   **關鍵欄位**:
    *   `company_id`: 所屬公司。

### 3.3 匯率 (exchange_rates)
*   **用途**: 維護公司每日「原幣 → 本位幣」會計匯率，作為各作業 `exchange_rate` 的預設來源。
*   **折算語意（必須與單據一致）**: 直接標價，`本幣金額 = 原幣金額 × rate`。USD→VND 存 `25450`，不存倒數。
*   **關鍵欄位**:
    *   `company_id`: 歸屬公司（匯率與本位幣均為公司級）。
    *   `from_currency_id` / `to_currency_id`: 原幣與本幣；`to_currency_id` 必須等於該公司 `local_currency_id`；同幣別不建檔（系統固定匯率 1）。
    *   `rate_date`: 生效日。查詢取 `rate_date <= 單據日` 的最近一筆。
    *   `rate_type`: `STANDARD`（開單預設，第一期使用）；`CLOSING`（期末重估，預留）。
    *   `rate`: `numeric(18,6)`，必須 > 0。
*   **唯一約束**: `(tenant_id, company_id, from_currency_id, to_currency_id, rate_type, rate_date)`。
*   **設計決策**:
    *   單據不 FK 本表；歷史金額以單據快照為準，主檔變更不回溯。
    *   下游轉單（GR←PO、AP←GR）複製來源快照，不重查主檔。
    *   開單允許覆寫帶出的匯率。外幣找不到匯率時不得靜默為 1。
    *   只存單向（原幣→本幣），不存反向匯率。

## 4. 檔案路徑對照

| 資料表 | SQL 檔案路徑 |
| :--- | :--- |
| companies | `system_design/backend/database/sql/schema_tables/BASIS/companies.sql` |
| factories | `system_design/backend/database/sql/schema_tables/BASIS/factories.sql` |
| exchange_rates | `system_design/backend/database/sql/schema_tables/BASIS/exchange_rates.sql` |

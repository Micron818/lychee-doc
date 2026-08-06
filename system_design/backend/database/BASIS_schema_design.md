# BASIS (System Basis) 模組資料庫設計文件

## 1. 模組概述
BASIS 模組主要定義企業的實體組織架構 (Organizational Structure)，如公司 (Company) 與工廠 (Factory)。
註：系統基礎架構如多租戶 (Tenants)、使用者 (Users) 與通用選項 (Option Values) 由 **ADM 模組** 管理。

## 2. 實體關係圖 (ERD) 概念

核心為 **公司 (Companies)** 與 **工廠 (Factories)**：

*   **公司 (Companies)**: 代表法律實體 (Legal Entity)，負責財務報表產出。
*   **工廠 (Factories)**: 代表生產或營運據點，歸屬於特定公司。

## 3. 資料表清單與設計備忘

### 3.1 公司 (companies)
*   **用途**: 法律實體 (Legal Entity)。
*   **關鍵欄位**:
    *   `code`: 公司統編或代碼。
    *   `currency_id`: 本位幣別。

### 3.2 工廠 (factories)
*   **用途**: 生產或營運據點。
*   **關鍵欄位**:
    *   `company_id`: 所屬公司。

## 4. 檔案路徑對照

| 資料表 | SQL 檔案路徑 |
| :--- | :--- |
| companies | `docs/database/sql/schema_tables/BASIS/companies.sql` |
| factories | `docs/database/sql/schema_tables/BASIS/factories.sql` |

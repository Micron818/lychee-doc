# ADM (Administration) 模組資料庫設計文件

## 1. 模組概述
ADM 模組為 ERP 系統的基礎骨幹，負責管理多租戶 (Multi-tenancy)、組織架構、使用者權限以及全系統共用的參數設定。

## 2. 資料表清單與設計備忘

### 2.1 組織架構 - 部門 (departments)
*   **用途**: 定義企業的組織結構樹，同時作為「行政單位」與「成本中心 (Cost Center)」的基礎。
*   **關鍵欄位**:
    *   `parent_id`: 支援無限層級的樹狀結構 (如: 總經理室 -> 研發處 -> 軟體部)。
    *   `manager_id`: 部門主管，連結至 `users` 表。用於未來的簽核流程 (Approval Workflow) 路由判斷。
*   **設計決策**:
    *   **成本中心邏輯**: 本系統採「簡易模式」，直接以部門作為成本歸屬對象。當 WM 模組進行領料時，直接關聯此表。

### 2.2 使用者與權限 (users, roles, permissions)
*   (既有架構) `users` 為系統登入主體，`roles` 與 `permissions` 透過 RBAC 模型控制功能存取。

### 2.3 系統參數 (options)
*   (既有架構) `option_categories` 與 `option_values` 提供全系統通用的下拉選單管理 (如幣別、狀態、單位)。

## 3. 檔案路徑對照表

| 表格名稱 | SQL 定義檔路徑 | 說明 |
| :--- | :--- | :--- |
| **departments** | `docs/database/sql/schema_tables/ADM/departments.sql` | 部門主檔 |
| **users** | `docs/database/sql/schema_tables/ADM/users.sql` | 使用者主檔 |


# ERP 權限管理系統 - 部署說明

## 文件說明

### 1. 主要文件
- **`database/sql/erp_permission_sql_scripts.sql`** - 資料庫表結構和約束定義
- **`database/sql/erp_permission_init_data.sql`** - 初始化數據插入腳本
- **`database/sql/reset_database_schema.sql`** - 重置資料庫架構腳本
- **`database/sql/reset_database_data.sql`** - 重置數據腳本
- **`database/docs/erp_permission_design.md`** - 系統設計文檔

### 2. 部署順序

#### 步驟 1：創建資料庫表結構
```bash
psql -d your_database -f database/sql/erp_permission_sql_scripts.sql
```

#### 步驟 2：插入初始化數據
```bash
psql -d your_database -f database/sql/erp_permission_init_data.sql
```

## 初始化數據內容

### 1. 選項分類和選項值
- 租戶狀態：active, inactive, suspended
- 公司狀態：active, inactive
- 用戶狀態：active, inactive, suspended
- 角色狀態：active, inactive
- 菜單狀態：active, inactive
- 權限操作：read, create, update, delete, export, import, approve
- 權限狀態：active, inactive
- 數據權限範圍：all, company, self, custom
- 委派狀態：active, expired, revoked

### 2. 默認租戶和公司
- 租戶：默認租戶 (default)
- 公司：總公司 (headquarters)

### 3. 默認用戶和角色
- 用戶：admin (系統管理員)
- 角色：系統管理員 (system_admin)、一般用戶 (user)

### 4. 系統菜單
- 系統管理
  - 用戶管理
  - 角色管理
  - 菜單管理
  - 權限管理

### 5. 系統權限
- 每個菜單都包含：read, create, update, delete 權限
- 系統管理員擁有所有權限

## 驗證部署

執行初始化數據腳本後，會自動顯示各表的記錄數量：

```
table_name        | count
------------------|-------
Tenants           | 1
Companies         | 1
Users             | 1
Roles             | 2
Menus             | 5
Permissions       | 17
Role Permissions  | 17
User Roles        | 1
Option Categories | 9
Option Values     | 25
```

## 默認登入信息

- **用戶名**：admin
- **郵箱**：admin@default.local
- **角色**：系統管理員
- **權限**：所有系統權限

## 注意事項

1. **執行順序**：必須先執行表結構腳本，再執行初始化數據腳本
2. **外鍵依賴**：初始化數據的插入順序已考慮外鍵依賴關係
3. **選項ID**：初始化數據中的選項ID是基於插入順序的，請勿隨意修改
4. **多租戶**：默認數據使用 tenant_id = 1，如需多租戶請自行調整

## 自定義配置

如需自定義初始化數據，請修改 `database/sql/erp_permission_init_data.sql` 文件中的相應 INSERT 語句。

## 重置操作

### 1. 重置數據 (保留表結構)
```bash
psql -d your_database -f database/sql/reset_database_data.sql
```
- 清空所有業務數據
- 保留表結構和約束
- 重置序列值
- 適用於測試環境重置

### 2. 重置架構 (完全重建)
```bash
# 步驟 1：刪除所有表和約束
psql -d your_database -f database/sql/reset_database_schema.sql

# 步驟 2：重新創建表結構
psql -d your_database -f database/sql/erp_permission_sql_scripts.sql

# 步驟 3：插入初始化數據
psql -d your_database -f database/sql/erp_permission_init_data.sql
```
- 完全刪除所有表和約束
- 重新創建完整的資料庫架構
- 適用於架構變更或完全重建

## 故障排除

### 常見錯誤
1. **外鍵約束錯誤**：確保按順序執行腳本
2. **重複鍵錯誤**：檢查是否已執行過初始化腳本
3. **權限錯誤**：確保資料庫用戶有足夠權限
4. **序列錯誤**：使用重置腳本重新初始化序列

### 快速重置
如需快速重置到初始狀態：
```bash
# 重置數據並重新初始化
psql -d your_database -f database/sql/reset_database_data.sql
psql -d your_database -f database/sql/erp_permission_init_data.sql
```

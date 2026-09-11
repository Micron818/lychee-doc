# ERP權限管理模組 - 設計說明 (多租戶版本 - PostgreSQL)

## 概述

本設計文檔描述了ERP系統權限管理模組的資料庫架構，採用多租戶架構，支持角色分層授權和細化權限控制。

> **SQL建表腳本**：請參考 `erp_permission_sql_scripts.sql` 文件。

## 表格說明

### 核心表格
1. **tenants** - 租戶基本資料
2. **companies** - 公司組織架構
3. **users** - 用戶基本資料
4. **roles** - 角色定義
5. **menus** - 系統菜單/功能
6. **permissions** - 具體權限定義

### 關聯表格
7. **user_roles** - 用戶角色關聯
8. **role_permissions** - 角色權限關聯
9. **data_permissions** - 數據級權限控制

### 擴展表格
10. **role_hierarchy** - 角色層級繼承
11. **option_categories** - 選項分類管理
12. **option_values** - 選項值管理
13. **role_permission_delegations** - 角色權限委派

## 表格設計要點

### 1. 租戶表 (tenants)
- **用途**：管理多租戶架構的租戶信息
- **關鍵字段**：`code`（租戶代碼）、`domain`（域名）、`status_option_id`（狀態選項ID）
- **約束**：租戶代碼和域名必須唯一，狀態通過選項表管理
- **狀態**：通過 option_values 表管理狀態選項

### 2. 公司表 (companies)
- **用途**：管理企業組織架構，支持多層級公司結構
- **關鍵字段**：`tenant_id`（租戶ID）、`code`（公司代碼）、`parent_id`（母公司ID）、`status_option_id`（狀態選項ID）
- **約束**：同一租戶內公司代碼唯一，稅號全局唯一，狀態通過選項表管理
- **層級結構**：支持母公司、子公司關係，通過 `path` 字段記錄層級路徑

### 3. 用戶表 (users)
- **用途**：存儲用戶基本信息（認證通過Keycloak處理）
- **關鍵字段**：`tenant_id`（租戶ID）、`username`（用戶名）、`email`（郵箱）、`status_option_id`（狀態選項ID）
- **約束**：同一租戶內用戶名和郵箱唯一，狀態通過選項表管理
- **關聯**：關聯到公司表，支持用戶歸屬管理
- **認證**：用戶認證通過Keycloak處理，不存儲密碼信息

### 4. 角色表 (roles)
- **用途**：定義系統角色和權限層級
- **關鍵字段**：`tenant_id`（租戶ID）、`code`（角色代碼）、`level`（權限層級）、`status_option_id`（狀態選項ID）
- **約束**：同一租戶內角色代碼唯一，狀態通過選項表管理
- **特性**：支持系統預設角色和自定義角色

### 5. 菜單表 (menus)
- **用途**：管理系統菜單結構和功能模組
- **關鍵字段**：`tenant_id`（租戶ID）、`code`（菜單代碼）、`parent_id`（父菜單ID）、`status_option_id`（狀態選項ID）
- **約束**：同一租戶內菜單代碼唯一，狀態通過選項表管理
- **特性**：支持層級結構，通過 `is_visible` 控制是否顯示在菜單中

### 6. 權限表 (permissions)
- **用途**：定義具體的操作權限，採用 resource:action 格式
- **關鍵字段**：`tenant_id`（租戶ID）、`menu_id`（菜單ID）、`action_option_id`（操作選項ID）、`status_option_id`（狀態選項ID）
- **約束**：同一菜單的同一操作唯一，操作和狀態通過選項表管理
- **權限格式**：通過 `CONCAT(menu.code, ':', action.code)` 動態生成，如 `user_management:create`
- **極簡設計**：移除所有冗餘欄位，權限代碼和顯示名稱都通過 JOIN 查詢動態生成

### 7. 用戶角色關聯表 (user_roles)
- **用途**：管理用戶與角色的關聯關係
- **關鍵字段**：`user_id`（用戶ID）、`role_id`（角色ID）、`expires_at`（過期時間）
- **約束**：同一用戶在同一租戶內不能重複分配相同角色
- **特性**：支持角色過期和臨時授權

### 8. 角色權限關聯表 (role_permissions)
- **用途**：管理角色與權限的關聯關係
- **關鍵字段**：`role_id`（角色ID）、`permission_id`（權限ID）
- **約束**：同一角色不能重複分配相同權限
- **特性**：記錄權限分配者和分配時間

### 9. 數據權限表 (data_permissions)
- **用途**：控制角色權限對特定數據的訪問範圍
- **關鍵字段**：`role_permission_id`（角色權限關聯ID）、`scope_option_id`（範圍選項ID）
- **約束**：直接引用 role_permissions 表，範圍通過選項表管理
- **特性**：使用JSON字段存儲複雜的權限條件，專注於數據權限控制

### 10. 角色層級表 (role_hierarchy)
- **用途**：定義角色之間的完全繼承關係
- **關鍵字段**：`parent_role_id`（父角色ID）、`child_role_id`（子角色ID）
- **約束**：防止循環繼承
- **特性**：子角色完全繼承父角色的所有權限

### 11. 選項分類表 (option_categories)
- **用途**：管理系統中各種選項的分類
- **關鍵字段**：`name`（分類名稱）、`code`（分類代碼）、`is_system`（是否系統分類）、`is_active`（是否啟用）
- **約束**：同一租戶內分類代碼唯一
- **特性**：支持系統分類和自定義分類，使用布爾值控制啟用狀態

### 12. 選項值表 (option_values)
- **用途**：存儲各種選項的具體值
- **關鍵字段**：`category_id`（分類ID）、`code`（選項代碼）、`name`（顯示名稱）、`is_active`（是否啟用）
- **約束**：同一分類內選項代碼唯一
- **特性**：支持排序、默認值、系統選項等，使用布爾值控制啟用狀態

### 13. 角色權限委派表 (role_permission_delegations)
- **用途**：管理角色權限的臨時委派
- **關鍵字段**：`delegator_id`（委派者ID）、`delegatee_id`（被委派者ID）、`role_permission_id`（角色權限ID）、`status_option_id`（狀態選項ID）
- **約束**：基於 role_permissions 表，狀態通過選項表管理
- **特性**：支持角色權限的臨時轉移和過期管理

## 設計特點

### 多租戶架構
- 所有表格都包含 `tenant_id` 字段實現租戶隔離
- 租戶級別的數據完全隔離，確保安全性
- 支持租戶級別的權限配置和角色定義

### 角色分層授權
- 通過 `roles.level` 實現角色層級
- 通過 `role_hierarchy` 實現角色繼承
- 支持角色委派機制
- 租戶級別的角色管理

### 細化權限控制
- 菜單級權限：`menus` + `permissions`
- 操作級權限：`permissions.action`（read、create、update、delete等）
- 權限格式：採用 `menu_code:action` 格式，如 `user_management:create`
- 數據級權限：`data_permissions`（基於角色權限關聯的數據權限控制，支持JSON條件配置）

### 公司組織架構
- 支持公司層級結構（母公司、子公司）
- 公司與用戶的關聯管理
- 支持公司級別的權限控制

### 統一選項管理
- 集中管理所有系統選項（狀態、操作、範圍等）
- 支持選項分類和排序
- 提供統一的選項查詢和驗證機制
- 支持系統選項和自定義選項

### 直接關聯選項ID設計
- 所有實體表直接關聯 option_values.id，避免複雜的 JOIN 查詢
- 提供外鍵約束保證數據完整性
- 簡化查詢邏輯，提高查詢性能
- 統一的設計模式，便於維護和擴展

### 簡化設計原則
- 移除重複欄位，避免數據冗餘
- 權限表移除所有冗餘欄位，權限代碼通過 `CONCAT(menu.code, ':', action.code)` 動態生成
- 選項表使用布爾值控制啟用狀態，簡化狀態管理
- 統一異動記錄欄位：所有表格都包含 `created_at`, `updated_at`, `created_by`, `updated_by`
- 減少維護成本，提高數據一致性，實現真正的極簡設計

### 完整的約束設計
- 所有表格都有完整的唯一鍵約束
- 租戶級別的唯一性保證
- 複合唯一鍵確保數據完整性
- 防止重複數據和衝突

## 多租戶實現要點

### 數據隔離
- 所有查詢都必須包含 `tenant_id` 條件
- 使用數據庫層面的約束確保租戶隔離
- 應用層面的租戶上下文管理

### 權限隔離
- 每個租戶有獨立的角色和權限定義
- 租戶間無法互相訪問權限數據
- 支持租戶級別的權限模板

### 性能優化
- 所有租戶相關字段都建立索引
- 複合索引優化多租戶查詢性能
- 考慮分區策略（按租戶分區）

### 安全性
- 租戶ID必須在應用層面驗證
- 防止跨租戶數據訪問
- 完整的審計日誌記錄

## PostgreSQL 設計特點

### 標準語法使用
- 使用 `BIGSERIAL` 進行主鍵自增
- 使用 `CHECK` 約束確保數據一致性
- 避免使用自定義枚舉類型，便於遷移

### JSON 數據類型
- 使用標準 JSON 數據類型
- 支持複雜的權限條件存儲
- 便於未來遷移到其他支持JSON的資料庫

### 時間戳處理
- 使用標準 TIMESTAMP 類型
- 時區處理由應用層負責
- 保持遷移靈活性

### 數據類型選擇
- 使用 VARCHAR 存儲IP地址
- 使用標準的整數和字符串類型
- 避免PostgreSQL特有的複雜類型

## 部署指南

### 執行順序
1. 創建租戶表
2. 創建公司表
3. 創建用戶表
4. 創建角色表
5. 創建菜單表
6. 創建權限表
7. 創建關聯表
8. 創建擴展表

### 性能優化建議

**複合索引優化**
- 多租戶查詢優化索引
- 權限查詢優化索引
- 活躍用戶和角色索引
- 菜單可見性查詢優化索引

**JSON 索引**
- 為JSON字段創建GIN索引
- 權限條件查詢優化
- 日誌詳情查詢優化

**分區策略**
- 按租戶分區權限日誌表
- 支持水平擴展
- 提高查詢性能

### 未來遷移考慮

**遷移到其他資料庫時的調整**：

1. **主鍵自增**
   - MySQL: `BIGSERIAL` → `BIGINT AUTO_INCREMENT`
   - SQL Server: `BIGSERIAL` → `BIGINT IDENTITY(1,1)`
   - Oracle: `BIGSERIAL` → `NUMBER` + `SEQUENCE`

2. **數據類型調整**
   - JSON → 目標資料庫的JSON類型或TEXT
   - TEXT → 目標資料庫的大文本類型
   - TIMESTAMP → 目標資料庫的時間戳類型

3. **約束調整**
   - CHECK約束語法可能需要調整
   - 外鍵約束語法基本通用

## 權限控制設計

### 權限格式說明
採用 `resource:action` 格式設計權限：

**基本操作類型**：
- `read` - 查看/讀取
- `create` - 創建/新增
- `update` - 更新/修改
- `delete` - 刪除
- `export` - 導出
- `import` - 導入
- `approve` - 審批

**權限示例**：
```sql
-- 用戶管理權限
'user_management:read'    -- 查看用戶列表
'user_management:create'  -- 創建新用戶
'user_management:update'  -- 更新用戶信息
'user_management:delete'  -- 刪除用戶
'user_management:export'  -- 導出用戶數據

-- 角色管理權限
'role_management:read'    -- 查看角色列表
'role_management:create'  -- 創建新角色
'role_management:update'  -- 更新角色信息
'role_management:delete'  -- 刪除角色
```

### 權限檢查邏輯
```sql
-- 檢查用戶是否有特定權限
SELECT COUNT(*) > 0 as has_permission
FROM permissions p
JOIN role_permissions rp ON p.id = rp.permission_id
JOIN user_roles ur ON rp.role_id = ur.role_id
WHERE ur.user_id = ?
  AND ur.tenant_id = ?
  AND ur.is_active = true
  AND p.code = ?  -- 如 'user_management:create'
  AND p.status = 'active';
```

## 使用建議

1. **開發階段**：使用SQL腳本創建開發環境
2. **測試階段**：使用分區策略優化性能測試
3. **生產部署**：根據數據量選擇合適的分區策略
4. **監控維護**：定期檢查權限日誌和性能指標

## 相關文件

- `erp_permission_sql_scripts.sql` - 完整的PostgreSQL建表腳本
- 應用層權限檢查邏輯設計文檔
- 前端權限控制集成指南

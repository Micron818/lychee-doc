-- =====================================================
-- ERP 權限管理系統 - 重置數據
-- =====================================================
-- 說明：此文件用於清空所有業務數據，保留表結構
-- 警告：此操作會刪除所有業務數據！
-- 使用場景：測試環境重置、數據清理、重新初始化

-- =====================================================
-- 禁用外鍵檢查 (PostgreSQL 使用 TRUNCATE CASCADE)
-- =====================================================

-- =====================================================
-- 清空所有表數據 (按依賴順序)
-- =====================================================

-- 清空委派表
TRUNCATE TABLE role_permission_delegations CASCADE;

-- 清空選項值表
TRUNCATE TABLE option_values CASCADE;

-- 清空選項分類表
TRUNCATE TABLE option_categories CASCADE;

-- 清空角色層級表
TRUNCATE TABLE role_hierarchy CASCADE;

-- 清空數據權限表
TRUNCATE TABLE data_permissions CASCADE;

-- 清空角色權限關聯表
TRUNCATE TABLE role_permissions CASCADE;

-- 清空用戶角色關聯表
TRUNCATE TABLE user_roles CASCADE;

-- 清空權限表
TRUNCATE TABLE permissions CASCADE;

-- 清空菜單表
TRUNCATE TABLE menus CASCADE;

-- 清空角色表
TRUNCATE TABLE roles CASCADE;

-- 清空用戶表
TRUNCATE TABLE users CASCADE;

-- 清空公司表
TRUNCATE TABLE companies CASCADE;

-- 清空租戶表
TRUNCATE TABLE tenants CASCADE;

-- =====================================================
-- 重置序列值
-- =====================================================
-- 重置所有序列的起始值為 1
ALTER SEQUENCE IF EXISTS tenants_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS companies_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS users_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS roles_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS menus_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS permissions_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS user_roles_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS role_permissions_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS data_permissions_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS role_hierarchy_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS option_categories_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS option_values_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS role_permission_delegations_id_seq RESTART WITH 1;

-- =====================================================
-- 數據重置完成確認
-- =====================================================
SELECT 'Database data reset completed successfully!' as status;

-- 顯示各表的記錄數量 (應該都是 0)
SELECT 'Tenants' as table_name, COUNT(*) as count FROM tenants
UNION ALL
SELECT 'Companies', COUNT(*) FROM companies
UNION ALL
SELECT 'Users', COUNT(*) FROM users
UNION ALL
SELECT 'Roles', COUNT(*) FROM roles
UNION ALL
SELECT 'Menus', COUNT(*) FROM menus
UNION ALL
SELECT 'Permissions', COUNT(*) FROM permissions
UNION ALL
SELECT 'Role Permissions', COUNT(*) FROM role_permissions
UNION ALL
SELECT 'User Roles', COUNT(*) FROM user_roles
UNION ALL
SELECT 'Data Permissions', COUNT(*) FROM data_permissions
UNION ALL
SELECT 'Role Hierarchy', COUNT(*) FROM role_hierarchy
UNION ALL
SELECT 'Option Categories', COUNT(*) FROM option_categories
UNION ALL
SELECT 'Option Values', COUNT(*) FROM option_values
UNION ALL
SELECT 'Role Permission Delegations', COUNT(*) FROM role_permission_delegations;

-- =====================================================
-- 後續操作建議
-- =====================================================
-- 數據重置完成後，可以執行以下操作：
-- 1. 執行 database/sql/erp_permission_init_data.sql 重新插入初始化數據
-- 2. 或者根據需要插入自定義的測試數據

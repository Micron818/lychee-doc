-- =====================================================
-- ERP 權限管理系統 - 重置資料庫架構
-- =====================================================
-- 說明：此文件用於完全重置資料庫架構，刪除所有表和約束
-- 警告：此操作會刪除所有數據和表結構！
-- 使用場景：開發環境重建、架構變更、完全重置

-- =====================================================
-- 刪除所有表 (按依賴順序)
-- =====================================================

-- 刪除委派表
DROP TABLE IF EXISTS role_permission_delegations CASCADE;

-- 刪除選項值表
DROP TABLE IF EXISTS option_values CASCADE;

-- 刪除選項分類表
DROP TABLE IF EXISTS option_categories CASCADE;

-- 刪除角色層級表
DROP TABLE IF EXISTS role_hierarchy CASCADE;

-- 刪除數據權限表
DROP TABLE IF EXISTS data_permissions CASCADE;

-- 刪除角色權限關聯表
DROP TABLE IF EXISTS role_permissions CASCADE;

-- 刪除用戶角色關聯表
DROP TABLE IF EXISTS user_roles CASCADE;

-- 刪除權限表
DROP TABLE IF EXISTS permissions CASCADE;

-- 刪除菜單表
DROP TABLE IF EXISTS menus CASCADE;

-- 刪除角色表
DROP TABLE IF EXISTS roles CASCADE;

-- 刪除用戶表
DROP TABLE IF EXISTS users CASCADE;

-- 刪除公司表
DROP TABLE IF EXISTS companies CASCADE;

-- 刪除租戶表
DROP TABLE IF EXISTS tenants CASCADE;

-- =====================================================
-- 刪除所有序列 (如果存在)
-- =====================================================
DROP SEQUENCE IF EXISTS tenants_id_seq CASCADE;
DROP SEQUENCE IF EXISTS companies_id_seq CASCADE;
DROP SEQUENCE IF EXISTS users_id_seq CASCADE;
DROP SEQUENCE IF EXISTS roles_id_seq CASCADE;
DROP SEQUENCE IF EXISTS menus_id_seq CASCADE;
DROP SEQUENCE IF EXISTS permissions_id_seq CASCADE;
DROP SEQUENCE IF EXISTS user_roles_id_seq CASCADE;
DROP SEQUENCE IF EXISTS role_permissions_id_seq CASCADE;
DROP SEQUENCE IF EXISTS data_permissions_id_seq CASCADE;
DROP SEQUENCE IF EXISTS role_hierarchy_id_seq CASCADE;
DROP SEQUENCE IF EXISTS option_categories_id_seq CASCADE;
DROP SEQUENCE IF EXISTS option_values_id_seq CASCADE;
DROP SEQUENCE IF EXISTS role_permission_delegations_id_seq CASCADE;

-- =====================================================
-- 重置完成確認
-- =====================================================
SELECT 'Database schema reset completed successfully!' as status;

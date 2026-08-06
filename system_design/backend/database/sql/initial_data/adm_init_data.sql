-- =====================================================
-- ERP 權限管理系統 - 初始化數據
-- =====================================================
-- 說明：此文件包含系統的初始化數據
-- 執行順序：必須在 erp_permission_sql_scripts.sql 之後執行
-- 注意：所有 INSERT 語句都已取消註釋，可直接執行

-- =====================================================
-- 1. 插入默認租戶 (必須最先執行，其他表都依賴它)
-- =====================================================
INSERT INTO tenants (name, code, domain, description) VALUES
('LYCHEE-ERP', 'lychee-erp', 'default.local', '系統默認租戶');

-- =====================================================
-- 2. 插入選項分類
-- =====================================================
INSERT INTO option_categories (tenant_id, name, code, is_system, description) VALUES
(1, '租戶狀態', 'tenant_status', true, '租戶的狀態選項'),
(1, '公司狀態', 'company_status', true, '公司的狀態選項'),
(1, '用戶狀態', 'user_status', true, '用戶的狀態選項'),
(1, '角色狀態', 'role_status', true, '角色的狀態選項'),
(1, '菜單狀態', 'menu_status', true, '菜單的狀態選項'),
(1, '權限操作', 'PERMISSION_ACTION', true, '權限的操作類型'),
(1, '權限狀態', 'PERMISSION_STATUS', true, '權限的狀態選項'),
(1, '數據權限範圍', 'data_scope', true, '數據權限的範圍選項'),
(1, '委派狀態', 'delegation_status', true, '權限委派的狀態選項');

-- =====================================================
-- 3. 插入選項值
-- =====================================================

-- 租戶狀態選項
INSERT INTO option_values (tenant_id, category_id, code, name, sort_order, is_system) VALUES
(1, 1, 'active', 'Active', 1, true),
(1, 1, 'inactive', 'Inactive', 2, true),
(1, 1, 'suspended', 'Suspended', 3, true);

-- 公司狀態選項
INSERT INTO option_values (tenant_id, category_id, code, name, sort_order, is_system) VALUES
(1, 2, 'active', 'Active', 1, true),
(1, 2, 'inactive', 'Inactive', 2, true);

-- 用戶狀態選項
INSERT INTO option_values (tenant_id, category_id, code, name, sort_order, is_system) VALUES
(1, 3, 'active', 'Active', 1, true),
(1, 3, 'inactive', 'Inactive', 2, true),
(1, 3, 'suspended', 'Suspended', 3, true);

-- 角色狀態選項
INSERT INTO option_values (tenant_id, category_id, code, name, sort_order, is_system) VALUES
(1, 4, 'active', 'Active', 1, true),
(1, 4, 'inactive', 'Inactive', 2, true);

-- 菜單狀態選項
INSERT INTO option_values (tenant_id, category_id, code, name, sort_order, is_system) VALUES
(1, 5, 'active', 'Active', 1, true),
(1, 5, 'inactive', 'Inactive', 2, true);

-- 權限操作選項
INSERT INTO option_values (tenant_id, category_id, code, name, sort_order, is_system) VALUES
(1, 6, 'read', 'Read', 1, true),
(1, 6, 'create', 'Create', 2, true),
(1, 6, 'update', 'Update', 3, true),
(1, 6, 'delete', 'Delete', 4, true),
(1, 6, 'export', 'Export', 5, true),
(1, 6, 'import', 'Import', 6, true),
(1, 6, 'approve', 'Approve', 7, true);

-- 權限狀態選項
INSERT INTO option_values (tenant_id, category_id, code, name, sort_order, is_system) VALUES
(1, 7, 'active', 'Active', 1, true),
(1, 7, 'inactive', 'Inactive', 2, true);

-- 數據權限範圍選項
INSERT INTO option_values (tenant_id, category_id, code, name, sort_order, is_system) VALUES
(1, 8, 'all', 'All', 1, true),
(1, 8, 'company', 'Company', 2, true),
(1, 8, 'self', 'Self', 3, true),
(1, 8, 'custom', 'Custom', 4, true);

-- 委派狀態選項
INSERT INTO option_values (tenant_id, category_id, code, name, sort_order, is_system) VALUES
(1, 9, 'active', 'Active', 1, true),
(1, 9, 'expired', 'Expired', 2, true),
(1, 9, 'revoked', 'Revoked', 3, true);

-- =====================================================
-- 3. 插入默認公司
-- =====================================================
INSERT INTO companies (tenant_id, name, code, level, path, description) VALUES
(1, '總公司', 'headquarters', 1, '/1', '系統默認公司');

-- =====================================================
-- 4. 插入默認用戶 (系統管理員)
-- =====================================================
INSERT INTO users (tenant_id, idp_user_id,username, email, full_name, company_id) VALUES
(1, 'd2e662a9-617b-4326-a21c-d9e8a9022b98','admin', 'admin@default.local', '系統管理員', 1);

-- =====================================================
-- 5. 插入系統角色
-- =====================================================
INSERT INTO roles (tenant_id, name, code, level, is_system) VALUES
(1, '系統管理員', 'ADMIN', 100, true),
(1, '一般用戶', 'USER', 10, true);

-- =====================================================
-- 6. 插入系統菜單
-- =====================================================
INSERT INTO menus (tenant_id, name, code, parent_id, level, path, icon, route, sort_order, is_visible) VALUES
(1, '系統管理', 'system', NULL, 1, '/1', 'setting', '/system', 1, true),
(1, '用戶管理', 'user_management', 1, 2, '/1/2', 'user', '/system/user', 1, true),
(1, '角色管理', 'role_management', 1, 2, '/1/3', 'team', '/system/role', 2, true),
(1, '菜單管理', 'menu_management', 1, 2, '/1/4', 'menu', '/system/menu', 3, true),
(1, '權限管理', 'permission_management', 1, 2, '/1/5', 'key', '/system/permission', 4, true);

-- =====================================================
-- 7. 插入系統權限
-- =====================================================
-- 權限代碼可通過 CONCAT(m.code, ':', ov.code) 動態生成
INSERT INTO permissions (tenant_id, menu_id, action_option_id, is_system) VALUES
(1, 1, 15, true),  -- system:read (menu_id=1, action_option_id=15(read))
(1, 2, 15, true),  -- user_management:read (menu_id=2, action_option_id=15(read))
(1, 2, 16, true),  -- user_management:create (menu_id=2, action_option_id=16(create))
(1, 2, 17, true),  -- user_management:update (menu_id=2, action_option_id=17(update))
(1, 2, 18, true),  -- user_management:delete (menu_id=2, action_option_id=18(delete))
(1, 3, 15, true),  -- role_management:read (menu_id=3, action_option_id=15(read))
(1, 3, 16, true),  -- role_management:create (menu_id=3, action_option_id=16(create))
(1, 3, 17, true),  -- role_management:update (menu_id=3, action_option_id=17(update))
(1, 3, 18, true),  -- role_management:delete (menu_id=3, action_option_id=18(delete))
(1, 4, 15, true),  -- menu_management:read (menu_id=4, action_option_id=15(read))
(1, 4, 16, true),  -- menu_management:create (menu_id=4, action_option_id=16(create))
(1, 4, 17, true),  -- menu_management:update (menu_id=4, action_option_id=17(update))
(1, 4, 18, true),  -- menu_management:delete (menu_id=4, action_option_id=18(delete))
(1, 5, 15, true),  -- permission_management:read (menu_id=5, action_option_id=15(read))
(1, 5, 16, true),  -- permission_management:create (menu_id=5, action_option_id=16(create))
(1, 5, 17, true),  -- permission_management:update (menu_id=5, action_option_id=17(update))
(1, 5, 18, true);  -- permission_management:delete (menu_id=5, action_option_id=18(delete))

-- =====================================================
-- 8. 插入角色權限關聯 (系統管理員擁有所有權限)
-- =====================================================
INSERT INTO role_permissions (tenant_id, role_id, permission_id, granted_by) VALUES
(1, 1, 1, 1),   -- 系統管理員 -> 系統管理查看
(1, 1, 2, 1),   -- 系統管理員 -> 用戶管理查看
(1, 1, 3, 1),   -- 系統管理員 -> 用戶管理創建
(1, 1, 4, 1),   -- 系統管理員 -> 用戶管理更新
(1, 1, 5, 1),   -- 系統管理員 -> 用戶管理刪除
(1, 1, 6, 1),   -- 系統管理員 -> 角色管理查看
(1, 1, 7, 1),   -- 系統管理員 -> 角色管理創建
(1, 1, 8, 1),   -- 系統管理員 -> 角色管理更新
(1, 1, 9, 1),   -- 系統管理員 -> 角色管理刪除
(1, 1, 10, 1),  -- 系統管理員 -> 菜單管理查看
(1, 1, 11, 1),  -- 系統管理員 -> 菜單管理創建
(1, 1, 12, 1),  -- 系統管理員 -> 菜單管理更新
(1, 1, 13, 1),  -- 系統管理員 -> 菜單管理刪除
(1, 1, 14, 1),  -- 系統管理員 -> 權限管理查看
(1, 1, 15, 1),  -- 系統管理員 -> 權限管理創建
(1, 1, 16, 1),  -- 系統管理員 -> 權限管理更新
(1, 1, 17, 1);  -- 系統管理員 -> 權限管理刪除

-- =====================================================
-- 9. 插入用戶角色關聯
-- =====================================================
INSERT INTO user_roles (tenant_id, user_id, role_id, assigned_by) VALUES
(1, 1, 1, 1);  -- 系統管理員用戶 -> 系統管理員角色

-- =====================================================
-- 初始化數據插入完成
-- =====================================================

-- 驗證數據插入結果
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
SELECT 'Option Categories', COUNT(*) FROM option_categories
UNION ALL
SELECT 'Option Values', COUNT(*) FROM option_values;

-- =====================================================
-- 更新循環依賴字段 (解決外鍵約束問題)
-- =====================================================

-- 更新租戶狀態 (在選項數據插入後)
UPDATE tenants SET status_option_id = 1 WHERE id = 1;  -- 設置為 'active' 狀態

-- 更新公司狀態
UPDATE companies SET status_option_id = 2 WHERE id = 1;  -- 設置為 'active' 狀態

-- 更新用戶狀態
UPDATE users SET status_option_id = 6 WHERE id = 1;  -- 設置為 'active' 狀態

-- 更新角色狀態
UPDATE roles SET status_option_id = 10 WHERE id IN (1, 2);  -- 設置為 'active' 狀態

-- 更新菜單狀態
UPDATE menus SET status_option_id = 12 WHERE id IN (1, 2, 3, 4, 5);  -- 設置為 'active' 狀態

-- 更新權限狀態
UPDATE permissions SET status_option_id = 13 WHERE id BETWEEN 1 AND 18;  -- 設置為 'active' 狀態

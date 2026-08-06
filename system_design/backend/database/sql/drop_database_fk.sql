-- =====================================================
-- DROP FOREIGN KEY CONSTRAINTS (reverse order)
-- PostgreSQL syntax
-- =====================================================

-- 12. 審計字段外鍵 (逆序)
ALTER TABLE role_permission_delegations DROP CONSTRAINT IF EXISTS fk_role_permission_delegations_updated_by;
ALTER TABLE role_permission_delegations DROP CONSTRAINT IF EXISTS fk_role_permission_delegations_created_by;

ALTER TABLE option_values DROP CONSTRAINT IF EXISTS fk_option_values_updated_by;
ALTER TABLE option_values DROP CONSTRAINT IF EXISTS fk_option_values_created_by;

ALTER TABLE option_categories DROP CONSTRAINT IF EXISTS fk_option_categories_updated_by;
ALTER TABLE option_categories DROP CONSTRAINT IF EXISTS fk_option_categories_created_by;

ALTER TABLE role_hierarchy DROP CONSTRAINT IF EXISTS fk_role_hierarchy_updated_by;
ALTER TABLE role_hierarchy DROP CONSTRAINT IF EXISTS fk_role_hierarchy_created_by;

ALTER TABLE data_permissions DROP CONSTRAINT IF EXISTS fk_data_permissions_updated_by;
ALTER TABLE data_permissions DROP CONSTRAINT IF EXISTS fk_data_permissions_created_by;

ALTER TABLE role_permissions DROP CONSTRAINT IF EXISTS fk_role_permissions_updated_by;
ALTER TABLE role_permissions DROP CONSTRAINT IF EXISTS fk_role_permissions_created_by;

ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS fk_user_roles_updated_by;
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS fk_user_roles_created_by;

ALTER TABLE permissions DROP CONSTRAINT IF EXISTS fk_permissions_updated_by;
ALTER TABLE permissions DROP CONSTRAINT IF EXISTS fk_permissions_created_by;

ALTER TABLE menus DROP CONSTRAINT IF EXISTS fk_menus_updated_by;
ALTER TABLE menus DROP CONSTRAINT IF EXISTS fk_menus_created_by;

ALTER TABLE roles DROP CONSTRAINT IF EXISTS fk_roles_updated_by;
ALTER TABLE roles DROP CONSTRAINT IF EXISTS fk_roles_created_by;

ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_updated_by;
ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_created_by;

ALTER TABLE companies DROP CONSTRAINT IF EXISTS fk_companies_updated_by;
ALTER TABLE companies DROP CONSTRAINT IF EXISTS fk_companies_created_by;
ALTER TABLE companies DROP CONSTRAINT IF EXISTS fk_companies_manager;

ALTER TABLE tenants DROP CONSTRAINT IF EXISTS fk_tenants_updated_by;
ALTER TABLE tenants DROP CONSTRAINT IF EXISTS fk_tenants_created_by;
ALTER TABLE tenants DROP CONSTRAINT IF EXISTS fk_tenants_status_option;

-- 11. 角色權限委派表
ALTER TABLE role_permission_delegations DROP CONSTRAINT IF EXISTS fk_role_permission_delegations_status_option;
ALTER TABLE role_permission_delegations DROP CONSTRAINT IF EXISTS fk_role_permission_delegations_role_permission;
ALTER TABLE role_permission_delegations DROP CONSTRAINT IF EXISTS fk_role_permission_delegations_delegatee;
ALTER TABLE role_permission_delegations DROP CONSTRAINT IF EXISTS fk_role_permission_delegations_delegator;
ALTER TABLE role_permission_delegations DROP CONSTRAINT IF EXISTS fk_role_permission_delegations_tenant;

-- 10. 角色層級表
ALTER TABLE role_hierarchy DROP CONSTRAINT IF EXISTS fk_role_hierarchy_child;
ALTER TABLE role_hierarchy DROP CONSTRAINT IF EXISTS fk_role_hierarchy_parent;
ALTER TABLE role_hierarchy DROP CONSTRAINT IF EXISTS fk_role_hierarchy_tenant;

-- 9. 數據權限表
ALTER TABLE data_permissions DROP CONSTRAINT IF EXISTS fk_data_permissions_scope_option;
ALTER TABLE data_permissions DROP CONSTRAINT IF EXISTS fk_data_permissions_role_permission;
ALTER TABLE data_permissions DROP CONSTRAINT IF EXISTS fk_data_permissions_tenant;

-- 8. 角色權限關聯表
ALTER TABLE role_permissions DROP CONSTRAINT IF EXISTS fk_role_permissions_granted_by;
ALTER TABLE role_permissions DROP CONSTRAINT IF EXISTS fk_role_permissions_permission;
ALTER TABLE role_permissions DROP CONSTRAINT IF EXISTS fk_role_permissions_role;
ALTER TABLE role_permissions DROP CONSTRAINT IF EXISTS fk_role_permissions_tenant;

-- 7. 用戶角色關聯表
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS fk_user_roles_assigned_by;
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS fk_user_roles_role;
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS fk_user_roles_user;
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS fk_user_roles_tenant;

-- 6. 權限表
ALTER TABLE permissions DROP CONSTRAINT IF EXISTS fk_permissions_status_option;
ALTER TABLE permissions DROP CONSTRAINT IF EXISTS fk_permissions_action_option;
ALTER TABLE permissions DROP CONSTRAINT IF EXISTS fk_permissions_menu;
ALTER TABLE permissions DROP CONSTRAINT IF EXISTS fk_permissions_tenant;

-- 5. 菜單表
ALTER TABLE menus DROP CONSTRAINT IF EXISTS fk_menus_status_option;
ALTER TABLE menus DROP CONSTRAINT IF EXISTS fk_menus_parent;
ALTER TABLE menus DROP CONSTRAINT IF EXISTS fk_menus_tenant;

-- 4. 角色表
ALTER TABLE roles DROP CONSTRAINT IF EXISTS fk_roles_status_option;
ALTER TABLE roles DROP CONSTRAINT IF EXISTS fk_roles_tenant;

-- 3. 用戶表
ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_status_option;
ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_company;
ALTER TABLE users DROP CONSTRAINT IF EXISTS fk_users_tenant;

-- 2. 公司表
ALTER TABLE companies DROP CONSTRAINT IF EXISTS fk_companies_status_option;
ALTER TABLE companies DROP CONSTRAINT IF EXISTS fk_companies_parent;
ALTER TABLE companies DROP CONSTRAINT IF EXISTS fk_companies_tenant;

-- 1. 選項表
ALTER TABLE option_values DROP CONSTRAINT IF EXISTS fk_option_values_category;
ALTER TABLE option_values DROP CONSTRAINT IF EXISTS fk_option_values_tenant;

ALTER TABLE option_categories DROP CONSTRAINT IF EXISTS fk_default_value;
ALTER TABLE option_categories DROP CONSTRAINT IF EXISTS fk_option_categories_tenant;
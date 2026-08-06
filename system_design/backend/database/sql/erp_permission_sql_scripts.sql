-- =====================================================
-- ERP權限管理模組 - PostgreSQL 建表腳本
-- 多租戶版本
-- =====================================================

-- 設計原則：使用標準PostgreSQL語法，避免特有對象，便於未來遷移

-- =====================================================
-- 1. 租戶表 (tenants)
-- =====================================================
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    domain VARCHAR(100) NOT NULL,
    description TEXT,
    status_option_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_tenant_code UNIQUE (code),
    CONSTRAINT uk_tenant_domain UNIQUE (domain)
);

-- 創建索引
CREATE INDEX idx_tenants_status_option ON tenants (status_option_id);

-- =====================================================
-- 2. 選項分類表 (option_categories) - 依賴 tenants
-- =====================================================
CREATE TABLE option_categories (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    default_value_id int8 NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_option_category_tenant_code UNIQUE (tenant_id, code)
);

-- 創建索引
CREATE INDEX idx_option_categories_tenant ON option_categories (tenant_id);
CREATE INDEX idx_option_categories_code ON option_categories (code);
CREATE INDEX idx_option_categories_is_active ON option_categories (is_active);

-- =====================================================
-- 3. 選項值表 (option_values) - 依賴 tenants, option_categories
-- =====================================================
CREATE TABLE option_values (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_system BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_option_value_tenant_category_code UNIQUE (tenant_id, category_id, code)
);

-- 創建索引
CREATE INDEX idx_option_values_tenant ON option_values (tenant_id);
CREATE INDEX idx_option_values_category ON option_values (category_id);
CREATE INDEX idx_option_values_code ON option_values (code);
CREATE INDEX idx_option_values_is_active ON option_values (is_active);

-- =====================================================
-- 4. 公司表 (companies) - 依賴 tenants, option_values
-- =====================================================
CREATE TABLE companies (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    tax_id VARCHAR(50),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    parent_id BIGINT,
    level INTEGER DEFAULT 1,
    path VARCHAR(500),
    manager_id BIGINT,
    description TEXT,
    status_option_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_company_tenant_code UNIQUE (tenant_id, code),
    CONSTRAINT uk_company_tax_id UNIQUE (tax_id)
);

-- 創建索引
CREATE INDEX idx_companies_tenant ON companies (tenant_id);
CREATE INDEX idx_companies_parent ON companies (parent_id);
CREATE INDEX idx_companies_path ON companies (path);
CREATE INDEX idx_companies_manager ON companies (manager_id);
CREATE INDEX idx_companies_status_option ON companies (status_option_id);

-- =====================================================
-- 5. 用戶表 (users) - 依賴 tenants, companies, option_values
-- =====================================================
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    idp_user_id VARCHAR(255),
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    company_id BIGINT,
    position VARCHAR(100),
    status_option_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_user_tenant_username UNIQUE (tenant_id, username),
    CONSTRAINT uk_user_tenant_email UNIQUE (tenant_id, email)
);

-- 創建索引
CREATE INDEX idx_users_tenant ON users (tenant_id);
CREATE INDEX idx_users_company ON users (company_id);
CREATE INDEX idx_users_status_option ON users (status_option_id);
CREATE INDEX idx_users_idp_user_id_tenant_id ON users(tenant_id,idp_user_id);
-- =====================================================
-- 6. 角色表 (roles) - 依賴 tenants, option_values
-- =====================================================
CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    level INTEGER DEFAULT 1,
    is_system BOOLEAN DEFAULT FALSE,
    status_option_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_role_tenant_code UNIQUE (tenant_id, code)
);

-- 創建索引
CREATE INDEX idx_roles_tenant ON roles (tenant_id);
CREATE INDEX idx_roles_level ON roles (level);
CREATE INDEX idx_roles_status_option ON roles (status_option_id);

-- =====================================================
-- 7. 菜單表 (menus) - 依賴 tenants, option_values
-- =====================================================
CREATE TABLE menus (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    parent_id BIGINT,
    level INTEGER DEFAULT 1,
    path VARCHAR(500),
    icon VARCHAR(100),
    route VARCHAR(200),
    sort_order INTEGER DEFAULT 0,
    is_visible BOOLEAN DEFAULT TRUE,
    status_option_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_menu_tenant_code UNIQUE (tenant_id, code)
);

-- 創建索引
CREATE INDEX idx_menus_tenant ON menus (tenant_id);
CREATE INDEX idx_menus_parent ON menus (parent_id);
CREATE INDEX idx_menus_path ON menus (path);
CREATE INDEX idx_menus_sort ON menus (sort_order);
CREATE INDEX idx_menus_visible ON menus (is_visible);
CREATE INDEX idx_menus_status_option ON menus (status_option_id);

-- =====================================================
-- 8. 權限表 (permissions) - 依賴 tenants, menus, option_values
-- =====================================================
CREATE TABLE permissions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    menu_id BIGINT NOT NULL,
    action_option_id BIGINT NOT NULL,
    is_system BOOLEAN DEFAULT FALSE,
    status_option_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_permission_menu_action UNIQUE (tenant_id, menu_id, action_option_id)
);

-- 創建索引
CREATE INDEX idx_permissions_tenant ON permissions (tenant_id);
CREATE INDEX idx_permissions_menu ON permissions (menu_id);
CREATE INDEX idx_permissions_action_option ON permissions (action_option_id);
CREATE INDEX idx_permissions_status_option ON permissions (status_option_id);
CREATE INDEX idx_permissions_menu_action ON permissions (menu_id, action_option_id);

-- =====================================================
-- 9. 用戶角色關聯表 (user_roles) - 依賴 tenants, users, roles
-- =====================================================
CREATE TABLE user_roles (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    assigned_by BIGINT,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_user_role_tenant UNIQUE (tenant_id, user_id, role_id)
);

-- 創建索引
CREATE INDEX idx_user_roles_tenant ON user_roles (tenant_id);
CREATE INDEX idx_user_roles_user ON user_roles (user_id);
CREATE INDEX idx_user_roles_role ON user_roles (role_id);
CREATE INDEX idx_user_roles_assigned_by ON user_roles (assigned_by);

-- =====================================================
-- 10. 角色權限關聯表 (role_permissions) - 依賴 tenants, roles, permissions, users
-- =====================================================
CREATE TABLE role_permissions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    granted_by BIGINT,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_role_permission_tenant UNIQUE (tenant_id, role_id, permission_id)
);

-- 創建索引
CREATE INDEX idx_role_permissions_tenant ON role_permissions (tenant_id);
CREATE INDEX idx_role_permissions_role ON role_permissions (role_id);
CREATE INDEX idx_role_permissions_permission ON role_permissions (permission_id);
CREATE INDEX idx_role_permissions_granted_by ON role_permissions (granted_by);

-- =====================================================
-- 11. 數據權限表 (data_permissions) - 依賴 tenants, role_permissions, option_values
-- =====================================================
CREATE TABLE data_permissions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    role_permission_id BIGINT NOT NULL,
    scope_option_id BIGINT,
    conditions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_data_permission_role_permission UNIQUE (tenant_id, role_permission_id)
);

-- 創建索引
CREATE INDEX idx_data_permissions_tenant ON data_permissions (tenant_id);
CREATE INDEX idx_data_permissions_role_permission ON data_permissions (role_permission_id);
CREATE INDEX idx_data_permissions_scope_option ON data_permissions (scope_option_id);

-- =====================================================
-- 12. 角色層級表 (role_hierarchy) - 依賴 tenants, roles
-- =====================================================
CREATE TABLE role_hierarchy (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    parent_role_id BIGINT NOT NULL,
    child_role_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_role_hierarchy_tenant UNIQUE (tenant_id, parent_role_id, child_role_id)
);

-- 創建索引
CREATE INDEX idx_role_hierarchy_tenant ON role_hierarchy (tenant_id);
CREATE INDEX idx_role_hierarchy_parent ON role_hierarchy (parent_role_id);
CREATE INDEX idx_role_hierarchy_child ON role_hierarchy (child_role_id);

-- =====================================================
-- 13. 角色權限委派表 (role_permission_delegations) - 依賴所有其他表
-- =====================================================
CREATE TABLE role_permission_delegations (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL,
    delegator_id BIGINT NOT NULL,
    delegatee_id BIGINT NOT NULL,
    role_permission_id BIGINT NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    reason TEXT,
    status_option_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_role_permission_delegation UNIQUE (tenant_id, delegator_id, delegatee_id, role_permission_id, start_date)
);

-- 創建索引
CREATE INDEX idx_role_permission_delegations_tenant ON role_permission_delegations (tenant_id);
CREATE INDEX idx_role_permission_delegations_delegator ON role_permission_delegations (delegator_id);
CREATE INDEX idx_role_permission_delegations_delegatee ON role_permission_delegations (delegatee_id);
CREATE INDEX idx_role_permission_delegations_role_permission ON role_permission_delegations (role_permission_id);
CREATE INDEX idx_role_permission_delegations_dates ON role_permission_delegations (start_date, end_date);
CREATE INDEX idx_role_permission_delegations_status_option ON role_permission_delegations (status_option_id);
CREATE INDEX idx_role_permission_delegations_active ON role_permission_delegations (delegatee_id, tenant_id, status_option_id, start_date, end_date);

-- =====================================================
-- 添加外鍵約束 (所有表創建完成後統一添加)
-- =====================================================

-- 1. 選項表的外鍵約束
ALTER TABLE option_categories 
ADD CONSTRAINT fk_option_categories_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id);
ALTER TABLE option_categories ADD CONSTRAINT fk_default_value FOREIGN KEY (default_value_id) REFERENCES option_values(id);

ALTER TABLE option_values 
ADD CONSTRAINT fk_option_values_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_option_values_category FOREIGN KEY (category_id) REFERENCES option_categories(id);

-- 2. 公司表的外鍵約束
ALTER TABLE companies 
ADD CONSTRAINT fk_companies_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_companies_parent FOREIGN KEY (parent_id) REFERENCES companies(id),
ADD CONSTRAINT fk_companies_status_option FOREIGN KEY (status_option_id) REFERENCES option_values(id);

-- 3. 用戶表的外鍵約束
ALTER TABLE users 
ADD CONSTRAINT fk_users_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_users_company FOREIGN KEY (company_id) REFERENCES companies(id),
ADD CONSTRAINT fk_users_status_option FOREIGN KEY (status_option_id) REFERENCES option_values(id);

-- 4. 角色表的外鍵約束
ALTER TABLE roles 
ADD CONSTRAINT fk_roles_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_roles_status_option FOREIGN KEY (status_option_id) REFERENCES option_values(id);

-- 5. 菜單表的外鍵約束
ALTER TABLE menus 
ADD CONSTRAINT fk_menus_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_menus_parent FOREIGN KEY (parent_id) REFERENCES menus(id),
ADD CONSTRAINT fk_menus_status_option FOREIGN KEY (status_option_id) REFERENCES option_values(id);

-- 6. 權限表的外鍵約束
ALTER TABLE permissions 
ADD CONSTRAINT fk_permissions_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_permissions_menu FOREIGN KEY (menu_id) REFERENCES menus(id),
ADD CONSTRAINT fk_permissions_action_option FOREIGN KEY (action_option_id) REFERENCES option_values(id),
ADD CONSTRAINT fk_permissions_status_option FOREIGN KEY (status_option_id) REFERENCES option_values(id);

-- 7. 用戶角色關聯表的外鍵約束
ALTER TABLE user_roles 
ADD CONSTRAINT fk_user_roles_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id),
ADD CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id),
ADD CONSTRAINT fk_user_roles_assigned_by FOREIGN KEY (assigned_by) REFERENCES users(id);

-- 8. 角色權限關聯表的外鍵約束
ALTER TABLE role_permissions 
ADD CONSTRAINT fk_role_permissions_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES roles(id),
ADD CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES permissions(id),
ADD CONSTRAINT fk_role_permissions_granted_by FOREIGN KEY (granted_by) REFERENCES users(id);

-- 9. 數據權限表的外鍵約束
ALTER TABLE data_permissions 
ADD CONSTRAINT fk_data_permissions_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_data_permissions_role_permission FOREIGN KEY (role_permission_id) REFERENCES role_permissions(id),
ADD CONSTRAINT fk_data_permissions_scope_option FOREIGN KEY (scope_option_id) REFERENCES option_values(id);

-- 10. 角色層級表的外鍵約束
ALTER TABLE role_hierarchy 
ADD CONSTRAINT fk_role_hierarchy_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_role_hierarchy_parent FOREIGN KEY (parent_role_id) REFERENCES roles(id),
ADD CONSTRAINT fk_role_hierarchy_child FOREIGN KEY (child_role_id) REFERENCES roles(id);

-- 11. 角色權限委派表的外鍵約束
ALTER TABLE role_permission_delegations 
ADD CONSTRAINT fk_role_permission_delegations_tenant FOREIGN KEY (tenant_id) REFERENCES tenants(id),
ADD CONSTRAINT fk_role_permission_delegations_delegator FOREIGN KEY (delegator_id) REFERENCES users(id),
ADD CONSTRAINT fk_role_permission_delegations_delegatee FOREIGN KEY (delegatee_id) REFERENCES users(id),
ADD CONSTRAINT fk_role_permission_delegations_role_permission FOREIGN KEY (role_permission_id) REFERENCES role_permissions(id),
ADD CONSTRAINT fk_role_permission_delegations_status_option FOREIGN KEY (status_option_id) REFERENCES option_values(id);

-- 12. 審計字段的外鍵約束 (循環依賴，需要最後添加)
ALTER TABLE tenants 
ADD CONSTRAINT fk_tenants_status_option FOREIGN KEY (status_option_id) REFERENCES option_values(id),
ADD CONSTRAINT fk_tenants_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_tenants_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE companies 
ADD CONSTRAINT fk_companies_manager FOREIGN KEY (manager_id) REFERENCES users(id),
ADD CONSTRAINT fk_companies_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_companies_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE users 
ADD CONSTRAINT fk_users_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_users_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE roles 
ADD CONSTRAINT fk_roles_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_roles_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE menus 
ADD CONSTRAINT fk_menus_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_menus_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE permissions 
ADD CONSTRAINT fk_permissions_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_permissions_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE user_roles 
ADD CONSTRAINT fk_user_roles_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_user_roles_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE role_permissions 
ADD CONSTRAINT fk_role_permissions_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_role_permissions_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE data_permissions 
ADD CONSTRAINT fk_data_permissions_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_data_permissions_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE role_hierarchy 
ADD CONSTRAINT fk_role_hierarchy_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_role_hierarchy_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE option_categories 
ADD CONSTRAINT fk_option_categories_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_option_categories_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE option_values 
ADD CONSTRAINT fk_option_values_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_option_values_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE role_permission_delegations 
ADD CONSTRAINT fk_role_permission_delegations_created_by FOREIGN KEY (created_by) REFERENCES users(id),
ADD CONSTRAINT fk_role_permission_delegations_updated_by FOREIGN KEY (updated_by) REFERENCES users(id);

-- =====================================================
-- 性能優化索引
-- =====================================================

-- 複合索引
CREATE INDEX CONCURRENTLY idx_menus_tenant_visible_status 
    ON menus (tenant_id, is_visible, status_option_id) 
    WHERE is_visible = true;

-- JSONB 索引
CREATE INDEX CONCURRENTLY idx_data_permissions_conditions_gin 
    ON data_permissions USING GIN (conditions);

-- =====================================================
-- 初始化數據說明
-- =====================================================
-- 初始化數據已移至單獨文件：database/sql/erp_permission_init_data.sql
-- 執行順序：
-- 1. 先執行本文件 (database/sql/erp_permission_sql_scripts.sql) 創建表結構
-- 2. 再執行 database/sql/erp_permission_init_data.sql 插入初始化數據

-- =====================================================
-- 腳本執行完成
-- =====================================================

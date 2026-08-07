-- Menu + read permission for Purchase Cost Analysis (方案1)
-- Idempotent: safe to re-run. Adjust tenant_id / role assignment as needed.
-- Parent: prefer existing costing folder (`menu.fi.costing`); fallback to FI root `/fi`.

DO $$
DECLARE
    v_tenant_id   bigint := 1;
    v_parent_id   bigint;
    v_menu_id     bigint;
    v_read_opt_id bigint;
    v_status_id   bigint;
    v_perm_id     bigint;
    v_admin_role  bigint;
BEGIN
    SELECT id INTO v_parent_id
    FROM lychee_erp.menus
    WHERE tenant_id = v_tenant_id AND locale = 'menu.fi.costing'
    LIMIT 1;

    IF v_parent_id IS NULL THEN
        SELECT id INTO v_parent_id
        FROM lychee_erp.menus
        WHERE tenant_id = v_tenant_id AND path = '/fi'
        LIMIT 1;
    END IF;

    -- Action category id=6 (read/create/update/delete...); menu/permission status commonly use option id of active
    SELECT id INTO v_read_opt_id
    FROM lychee_erp.option_values
    WHERE category_id = 6 AND code = 'read'
    LIMIT 1;

    SELECT id INTO v_status_id
    FROM lychee_erp.option_values
    WHERE category_id = 1 AND code = 'active'
    ORDER BY id DESC
    LIMIT 1;

    IF v_read_opt_id IS NULL THEN
        RAISE EXCEPTION 'option_values.code=read not found';
    END IF;

    SELECT id INTO v_menu_id
    FROM lychee_erp.menus
    WHERE tenant_id = v_tenant_id AND path = '/fi/purchase-cost-analysis'
    LIMIT 1;

    IF v_menu_id IS NULL THEN
        INSERT INTO lychee_erp.menus (
            tenant_id, name, parent_id, path, icon, sort_order, is_visible,
            status_option_id, created_at, updated_at, created_by, updated_by,
            locale, access_key
        ) VALUES (
            v_tenant_id,
            'Purchase Cost Analysis',
            v_parent_id,
            '/fi/purchase-cost-analysis',
            NULL,
            90,
            true,
            v_status_id,
            NOW(),
            NOW(),
            1,
            1,
            'menu.fi.purchaseCostAnalysis',
            'FI_PCA'
        )
        RETURNING id INTO v_menu_id;
    END IF;

    SELECT id INTO v_perm_id
    FROM lychee_erp.permissions
    WHERE tenant_id = v_tenant_id
      AND menu_id = v_menu_id
      AND action_option_id = v_read_opt_id
    LIMIT 1;

    IF v_perm_id IS NULL THEN
        INSERT INTO lychee_erp.permissions (
            tenant_id, menu_id, action_option_id, is_system, status_option_id,
            created_at, updated_at, created_by, updated_by
        ) VALUES (
            v_tenant_id, v_menu_id, v_read_opt_id, true, v_status_id,
            NOW(), NOW(), 1, 1
        )
        RETURNING id INTO v_perm_id;
    END IF;

    -- Grant to Administrator role (seed code = 'Admin')
    SELECT id INTO v_admin_role
    FROM lychee_erp.roles
    WHERE tenant_id = v_tenant_id AND code = 'Admin'
    LIMIT 1;

    IF v_admin_role IS NOT NULL AND v_perm_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM lychee_erp.role_permissions
           WHERE tenant_id = v_tenant_id
             AND role_id = v_admin_role
             AND permission_id = v_perm_id
       ) THEN
        INSERT INTO lychee_erp.role_permissions (
            tenant_id, role_id, permission_id, granted_by, granted_at,
            created_at, updated_at, created_by, updated_by
        ) VALUES (
            v_tenant_id, v_admin_role, v_perm_id, 1, NOW(),
            NOW(), NOW(), 1, 1
        );
    END IF;
END $$;

-- =====================================================
-- FI 财务会计模块 - 清空所有表数据
-- =====================================================
-- 说明：清空 FI 模块全部 20 张业务表的数据，保留表结构
-- 警告：此操作会删除 FI 模块所有业务数据，不可恢复！
-- 使用场景：测试环境重置、重复导入初始化数据前清理
--
-- 执行前提：
--   1. FI 表结构已创建（0629-002-fi-create-tables.sql）
--   2. 无其他非 FI 模块表引用 FI 表数据（当前 schema 设计下 FI 表仅内部互引）
--
-- 后续操作：清空后可执行 fi_init_data 下的初始化脚本，例如 gl_accounts.sql
-- =====================================================

-- 一次性 TRUNCATE 全部 FI 表（含循环 FK，如 journal_entries ↔ invoices/payments）
-- RESTART IDENTITY：同步重置各表 bigserial 序列至初始值
TRUNCATE TABLE
    -- 收付款明细
    lychee_erp.payment_lines,
    -- 发票明细
    lychee_erp.ap_invoice_lines,
    lychee_erp.ar_invoice_lines,
    -- 收付款 / 发票
    lychee_erp.payments,
    lychee_erp.ap_invoices,
    lychee_erp.ar_invoices,
    -- 传票明细
    lychee_erp.journal_entry_lines,
    -- 固定资产折旧
    lychee_erp.asset_depreciations,
    -- 成本结算
    lychee_erp.cost_calculation_items,
    lychee_erp.material_costs,
    lychee_erp.cost_calculations,
    lychee_erp.cost_allocations,
    lychee_erp.fi_costing_policies,
    -- 固定资产
    lychee_erp.fixed_assets,
    lychee_erp.asset_categories,
    lychee_erp.fi_account_determination,
    lychee_erp.material_type_valuation_classes,
    lychee_erp.valuation_classes,
    -- 传票（含 reversal_entry_id 自引用）
    lychee_erp.journal_entries,
    -- 银行账户 / 往来单位
    lychee_erp.partner_bank_accounts,
    lychee_erp.company_bank_accounts,
    lychee_erp.business_partners,
    -- 会计期间 / 科目（gl_accounts 含 parent_id 自引用）
    lychee_erp.fiscal_periods,
    lychee_erp.gl_accounts
RESTART IDENTITY CASCADE;

-- =====================================================
-- 验证：各表记录数应为 0
-- =====================================================

SELECT 'payment_lines' AS table_name, COUNT(*) AS count FROM lychee_erp.payment_lines
UNION ALL SELECT 'ap_invoice_lines', COUNT(*) FROM lychee_erp.ap_invoice_lines
UNION ALL SELECT 'ar_invoice_lines', COUNT(*) FROM lychee_erp.ar_invoice_lines
UNION ALL SELECT 'payments', COUNT(*) FROM lychee_erp.payments
UNION ALL SELECT 'ap_invoices', COUNT(*) FROM lychee_erp.ap_invoices
UNION ALL SELECT 'ar_invoices', COUNT(*) FROM lychee_erp.ar_invoices
UNION ALL SELECT 'journal_entry_lines', COUNT(*) FROM lychee_erp.journal_entry_lines
UNION ALL SELECT 'asset_depreciations', COUNT(*) FROM lychee_erp.asset_depreciations
UNION ALL SELECT 'cost_calculation_items', COUNT(*) FROM lychee_erp.cost_calculation_items
UNION ALL SELECT 'material_costs', COUNT(*) FROM lychee_erp.material_costs
UNION ALL SELECT 'cost_calculations', COUNT(*) FROM lychee_erp.cost_calculations
UNION ALL SELECT 'cost_allocations', COUNT(*) FROM lychee_erp.cost_allocations
UNION ALL SELECT 'fi_costing_policies', COUNT(*) FROM lychee_erp.fi_costing_policies
UNION ALL SELECT 'fixed_assets', COUNT(*) FROM lychee_erp.fixed_assets
UNION ALL SELECT 'asset_categories', COUNT(*) FROM lychee_erp.asset_categories
UNION ALL SELECT 'journal_entries', COUNT(*) FROM lychee_erp.journal_entries
UNION ALL SELECT 'partner_bank_accounts', COUNT(*) FROM lychee_erp.partner_bank_accounts
UNION ALL SELECT 'company_bank_accounts', COUNT(*) FROM lychee_erp.company_bank_accounts
UNION ALL SELECT 'business_partners', COUNT(*) FROM lychee_erp.business_partners
UNION ALL SELECT 'fiscal_periods', COUNT(*) FROM lychee_erp.fiscal_periods
UNION ALL SELECT 'gl_accounts', COUNT(*) FROM lychee_erp.gl_accounts
ORDER BY table_name;

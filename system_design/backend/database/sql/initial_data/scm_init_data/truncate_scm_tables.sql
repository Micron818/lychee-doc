-- =====================================================
-- SCM 供应链管理模块 - 清空所有表数据
-- =====================================================
-- 说明：清空 SCM 模块全部 8 张业务表的数据，保留表结构
-- 警告：此操作会删除 SCM 模块所有业务数据，不可恢复！
-- 使用场景：测试环境重置、重复导入初始化数据前清理
--
-- 执行前提：
--   1. SCM 表结构已创建
--   2. WM 模块 goods_receipts / warehouses 引用 suppliers，
--      使用 CASCADE 时会连带清空上述 WM 表（及其下游明细表）
--      若需保留 WM 数据，须先执行 wm_init_data/truncate_wm_tables.sql
--   3. FI 模块 business_partners.source_id 逻辑关联 suppliers（无 FK），
--      清空后可能残留孤立往来单位记录，建议同步执行 truncate_fi_tables.sql
--
-- 后续操作：清空后可执行 scm_init_data 下的初始化脚本
-- =====================================================

-- 一次性 TRUNCATE 全部 SCM 表
-- RESTART IDENTITY：同步重置各表 bigserial 序列至初始值
-- CASCADE：处理 suppliers 被 WM goods_receipts / warehouses 引用的跨模块 FK
TRUNCATE TABLE
    -- 委外 / 采购明细
    lychee_erp.outsource_order_components,
    lychee_erp.outsource_order_items,
    lychee_erp.purchase_order_items,
    lychee_erp.purchase_requisition_items,
    -- 委外 / 采购 / 请购单表头
    lychee_erp.outsource_orders,
    lychee_erp.purchase_orders,
    lychee_erp.purchase_requisitions,
    -- 供应商主数据
    lychee_erp.suppliers
RESTART IDENTITY CASCADE;

-- =====================================================
-- 验证：各表记录数应为 0
-- =====================================================

SELECT 'outsource_order_components' AS table_name, COUNT(*) AS count FROM lychee_erp.outsource_order_components
UNION ALL SELECT 'outsource_order_items', COUNT(*) FROM lychee_erp.outsource_order_items
UNION ALL SELECT 'purchase_order_items', COUNT(*) FROM lychee_erp.purchase_order_items
UNION ALL SELECT 'purchase_requisition_items', COUNT(*) FROM lychee_erp.purchase_requisition_items
UNION ALL SELECT 'outsource_orders', COUNT(*) FROM lychee_erp.outsource_orders
UNION ALL SELECT 'purchase_orders', COUNT(*) FROM lychee_erp.purchase_orders
UNION ALL SELECT 'purchase_requisitions', COUNT(*) FROM lychee_erp.purchase_requisitions
UNION ALL SELECT 'suppliers', COUNT(*) FROM lychee_erp.suppliers
ORDER BY table_name;

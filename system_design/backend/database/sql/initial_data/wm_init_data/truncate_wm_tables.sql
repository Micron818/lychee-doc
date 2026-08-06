-- =====================================================
-- WM 仓储管理模块 - 清空所有表数据
-- =====================================================
-- 说明：清空 WM 模块全部 15 张业务表的数据，保留表结构
-- 警告：此操作会删除 WM 模块所有业务数据，不可恢复！
-- 使用场景：测试环境重置、重复导入初始化数据前清理
--
-- 执行前提：
--   1. WM 表结构已创建
--   2. 若 FI 模块 cost_calculations 有数据引用 inventory_periods，
--      须先执行 fi_init_data/truncate_fi_tables.sql，否则本脚本会失败
--      （使用 CASCADE 时会连带清空 FI 的 cost_calculations / material_costs 等）
--
-- 后续操作：清空后可执行 wm_init_data 下的初始化脚本
-- =====================================================

-- 一次性 TRUNCATE 全部 WM 表
-- RESTART IDENTITY：同步重置各表 bigserial 序列至初始值
-- CASCADE：处理 inventory_periods 被 FI cost_calculations 引用的跨模块 FK
TRUNCATE TABLE
    -- 退料明细（引用 stock_issue_items）
    lychee_erp.stock_return_items,
    -- 出入库 / 调拨 / 盘点明细
    lychee_erp.stock_issue_items,
    lychee_erp.goods_receipt_items,
    lychee_erp.stock_transfer_items,
    lychee_erp.physical_inventory_items,
    -- 库存流水 / 余额
    lychee_erp.stock_transactions,
    lychee_erp.inventory_balances,
    lychee_erp.stock_on_hand,
    -- 盘点单
    lychee_erp.physical_inventories,
    -- 单据表头
    lychee_erp.stock_returns,
    lychee_erp.stock_issues,
    lychee_erp.goods_receipts,
    lychee_erp.stock_transfers,
    -- 库存期间 / 仓库主数据
    lychee_erp.inventory_periods,
    lychee_erp.warehouses
RESTART IDENTITY CASCADE;

-- =====================================================
-- 验证：各表记录数应为 0
-- =====================================================

SELECT 'stock_return_items' AS table_name, COUNT(*) AS count FROM lychee_erp.stock_return_items
UNION ALL SELECT 'stock_issue_items', COUNT(*) FROM lychee_erp.stock_issue_items
UNION ALL SELECT 'goods_receipt_items', COUNT(*) FROM lychee_erp.goods_receipt_items
UNION ALL SELECT 'stock_transfer_items', COUNT(*) FROM lychee_erp.stock_transfer_items
UNION ALL SELECT 'physical_inventory_items', COUNT(*) FROM lychee_erp.physical_inventory_items
UNION ALL SELECT 'stock_transactions', COUNT(*) FROM lychee_erp.stock_transactions
UNION ALL SELECT 'inventory_balances', COUNT(*) FROM lychee_erp.inventory_balances
UNION ALL SELECT 'stock_on_hand', COUNT(*) FROM lychee_erp.stock_on_hand
UNION ALL SELECT 'physical_inventories', COUNT(*) FROM lychee_erp.physical_inventories
UNION ALL SELECT 'stock_returns', COUNT(*) FROM lychee_erp.stock_returns
UNION ALL SELECT 'stock_issues', COUNT(*) FROM lychee_erp.stock_issues
UNION ALL SELECT 'goods_receipts', COUNT(*) FROM lychee_erp.goods_receipts
UNION ALL SELECT 'stock_transfers', COUNT(*) FROM lychee_erp.stock_transfers
UNION ALL SELECT 'inventory_periods', COUNT(*) FROM lychee_erp.inventory_periods
UNION ALL SELECT 'warehouses', COUNT(*) FROM lychee_erp.warehouses
ORDER BY table_name;

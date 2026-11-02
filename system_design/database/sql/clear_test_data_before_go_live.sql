-- =====================================================
-- 上线前清除测试业务数据
-- =====================================================
-- 保留：
--   基础资料：组织、用户权限、物料与产品型号、客商、仓库、
--             选项、税、科目、付款条件、会计期间、库存期间、汇率、
--             MRP 参数与排程、质检方案、员工与职务、单据编号规则
--   用量 BOM：bill_of_materials、bom_items
--   实盘资料：physical_inventories、physical_inventory_items 整表保留。
--             状态与数量已手工回退，本脚本不再改盘点单。
--
-- 清除：销售、采购、委外、生产、MRP 运算结果、库存收发与现存量、
--       库存流水、财务凭证与发票付款、成本运算、固定资产卡片、
--       考勤薪资请假、检验单、操作日志、导入导出任务、需求追溯
--
-- 不使用 CASCADE。若执行失败，说明有保留表引用了被清除的表，
-- 先核对新的外键，不要直接加上 CASCADE。
--
-- 执行前先备份数据库。本脚本在一个事务内完成，核对文末查询后再提交。
-- 库存期间保持原状。
-- =====================================================

BEGIN;

TRUNCATE TABLE
    -- 需求追溯与运行日志
    lychee_erp.order_peggings,
    lychee_erp.operation_logs,
    lychee_erp.export_jobs,
    lychee_erp.import_jobs,

    -- 财务业务
    lychee_erp.payment_lines,
    lychee_erp.payments,
    lychee_erp.ap_credit_memo_lines,
    lychee_erp.ap_credit_memos,
    lychee_erp.ar_credit_memo_lines,
    lychee_erp.ar_credit_memos,
    lychee_erp.ap_invoice_schedules,
    lychee_erp.ar_invoice_schedules,
    lychee_erp.ap_invoice_lines,
    lychee_erp.ar_invoice_lines,
    lychee_erp.ap_invoices,
    lychee_erp.ar_invoices,
    lychee_erp.asset_depreciations,
    lychee_erp.fixed_assets,
    lychee_erp.cost_allocations,
    lychee_erp.cost_calculation_items,
    lychee_erp.material_costs,
    lychee_erp.cost_calculations,
    lychee_erp.journal_entry_lines,
    lychee_erp.journal_entries,

    -- 仓储业务（不含盘点单、库存期间、仓库）
    lychee_erp.stock_transactions,
    lychee_erp.stock_on_hand,
    lychee_erp.inventory_balances,
    lychee_erp.customer_return_items,
    lychee_erp.customer_returns,
    lychee_erp.purchase_return_items,
    lychee_erp.purchase_returns,
    lychee_erp.stock_issue_return_items,
    lychee_erp.stock_issue_returns,
    lychee_erp.stock_issue_items,
    lychee_erp.stock_issues,
    lychee_erp.stock_transfer_items,
    lychee_erp.stock_transfers,
    lychee_erp.goods_receipt_items,
    lychee_erp.goods_receipts,

    -- 销售
    lychee_erp.delivery_items,
    lychee_erp.deliveries,
    lychee_erp.sales_order_items,
    lychee_erp.sales_orders,
    lychee_erp.sales_forecast_items,
    lychee_erp.sales_forecasts,

    -- 采购与委外
    lychee_erp.outsource_order_components,
    lychee_erp.outsource_order_items,
    lychee_erp.outsource_orders,
    lychee_erp.purchase_order_items,
    lychee_erp.purchase_orders,
    lychee_erp.purchase_requisition_items,
    lychee_erp.purchase_requisitions,

    -- 生产与 MRP 结果（不含 BOM、MRP 参数、MRP 排程）
    lychee_erp.production_backflush_exceptions,
    lychee_erp.production_report_components,
    lychee_erp.production_reports,
    lychee_erp.production_order_components,
    lychee_erp.production_orders,
    lychee_erp.factory_order_items,
    lychee_erp.factory_orders,
    lychee_erp.planned_orders,
    lychee_erp.mrp_results,
    lychee_erp.mrp_runs,

    -- 质量检验单（不含检验方案与检验特性）
    lychee_erp.inspection_results,
    lychee_erp.inspection_orders,

    -- 人事事务（不含员工、职务）
    lychee_erp.payslip_items,
    lychee_erp.payslips,
    lychee_erp.attendance_records,
    lychee_erp.leave_requests,
    lychee_erp.payroll_periods
RESTART IDENTITY;

-- 清除已删除单据的号码流水。保留实盘单号与供应商编号，避免重新取号撞号。
DELETE FROM lychee_erp.sys_doc_sequence
WHERE split_part(seq_key, ':', 1) IN (
    'SALES_ORDER',
    'SALES_FORECAST',
    'PURCHASE_REQUISITION',
    'PLANNED_ORDER',
    'FACTORY_ORDER',
    'MRP_RUN',
    'PRODUCTION_ORDER',
    'PURCHASE_ORDER',
    'OUTSOURCE_ORDER',
    'GOODS_RECEIPT',
    'GOODS_RECEIPT_BATCH',
    'STOCK_ISSUE',
    'STOCK_ISSUE_RETURN',
    'PURCHASE_RETURN',
    'CUSTOMER_RETURN',
    'PRODUCTION_REPORT',
    'STOCK_TRANSFER',
    'DELIVERY',
    'JOURNAL_ENTRY',
    'AP_INVOICE',
    'AP_CREDIT_MEMO',
    'AR_INVOICE',
    'AR_CREDIT_MEMO',
    'PAYMENT',
    'SUPPLIER_REFUND',
    'CUSTOMER_REFUND',
    'FIXED_ASSET',
    'COST_CALCULATION'
);

-- =====================================================
-- 核对：业务表应为 0；基础资料、BOM、实盘应仍有数据
-- =====================================================

SELECT 'stock_on_hand' AS table_name, COUNT(*) AS row_count FROM lychee_erp.stock_on_hand
UNION ALL SELECT 'stock_transactions', COUNT(*) FROM lychee_erp.stock_transactions
UNION ALL SELECT 'sales_orders', COUNT(*) FROM lychee_erp.sales_orders
UNION ALL SELECT 'purchase_orders', COUNT(*) FROM lychee_erp.purchase_orders
UNION ALL SELECT 'production_orders', COUNT(*) FROM lychee_erp.production_orders
UNION ALL SELECT 'journal_entries', COUNT(*) FROM lychee_erp.journal_entries
UNION ALL SELECT 'materials', COUNT(*) FROM lychee_erp.materials
UNION ALL SELECT 'bill_of_materials', COUNT(*) FROM lychee_erp.bill_of_materials
UNION ALL SELECT 'bom_items', COUNT(*) FROM lychee_erp.bom_items
UNION ALL SELECT 'physical_inventories', COUNT(*) FROM lychee_erp.physical_inventories
UNION ALL SELECT 'physical_inventory_items', COUNT(*) FROM lychee_erp.physical_inventory_items
ORDER BY table_name;

SELECT status,
       COUNT(*) AS document_count
FROM lychee_erp.physical_inventories
GROUP BY status
ORDER BY status;

SELECT COALESCE(SUM(counted_quantity), 0) AS counted_quantity,
       COALESCE(SUM(book_quantity), 0) AS book_quantity
FROM lychee_erp.physical_inventory_items;

-- 核对无误后提交；若要放弃本次清除，改为 ROLLBACK
COMMIT;

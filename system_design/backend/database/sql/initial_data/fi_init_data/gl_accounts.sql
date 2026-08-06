-- =====================================================
-- FI 财务会计模块 - 会计科目表示例资料
-- =====================================================
-- 说明：制造业（鞋业）常用科目表，tenant 级共享
-- 执行前提：已执行 adm_init_data.sql（tenant_id=1, user_id=1 须存在）
-- 执行顺序：须在 gl_accounts 表已创建之后执行
-- 科目编码参考中国企业会计准则常用编号，并覆盖 AR/AP/FA/COSTING 模块所需科目
-- =====================================================

-- 如需重复导入，请先确认无下游 FK 引用，再取消下行注释
-- DELETE FROM lychee_erp.gl_accounts WHERE tenant_id = 1;

-- =====================================================
-- 1. 一级科目（无 parent_id）
-- =====================================================

INSERT INTO lychee_erp.gl_accounts
    (tenant_id, code, name, account_type, parent_id, is_reconciliation, is_active, description, created_at, updated_at, created_by, updated_by)
VALUES
    (1, '1000', '流动资产',       'ASSET',     NULL, false, true, '流动资产统制科目',       NOW(), NOW(), 1, 1),
    (1, '1600', '非流动资产',     'ASSET',     NULL, false, true, '非流动资产统制科目',     NOW(), NOW(), 1, 1),
    (1, '2000', '流动负债',       'LIABILITY', NULL, false, true, '流动负债统制科目',       NOW(), NOW(), 1, 1),
    (1, '3000', '所有者权益',     'EQUITY',    NULL, false, true, '所有者权益统制科目',     NOW(), NOW(), 1, 1),
    (1, '4000', '营业收入',       'REVENUE',   NULL, false, true, '营业收入统制科目',       NOW(), NOW(), 1, 1),
    (1, '5000', '营业成本及生产', 'EXPENSE',   NULL, false, true, '成本及制造费用统制科目', NOW(), NOW(), 1, 1),
    (1, '6000', '期间费用',       'EXPENSE',   NULL, false, true, '销售/管理/财务费用统制', NOW(), NOW(), 1, 1);

-- =====================================================
-- 2. 二级科目
-- =====================================================

INSERT INTO lychee_erp.gl_accounts
    (tenant_id, code, name, account_type, parent_id, is_reconciliation, is_active, description, created_at, updated_at, created_by, updated_by)
VALUES
    -- 流动资产
    (1, '1001', '库存现金',   'CASH',  (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, '出纳现金',                     NOW(), NOW(), 1, 1),
    (1, '1002', '银行存款',   'CASH',  (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, '银行及现金等价物',             NOW(), NOW(), 1, 1),
    (1, '1121', '应收票据',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, '客户商业汇票',                 NOW(), NOW(), 1, 1),
    (1, '1122', '应收账款',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), true,  true, 'AR 统制科目，关联客户子帐',    NOW(), NOW(), 1, 1),
    (1, '1123', '预付账款',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, '预付供应商款项',               NOW(), NOW(), 1, 1),
    (1, '1401', '原材料',     'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, '皮革、橡胶、布料等原材料',     NOW(), NOW(), 1, 1),
    (1, '1403', '在产品',     'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, 'WIP 在产品',                   NOW(), NOW(), 1, 1),
    (1, '1405', '库存商品',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, '成品鞋库存',                   NOW(), NOW(), 1, 1),
    (1, '1411', '周转材料',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, '低值易耗品、包装物',           NOW(), NOW(), 1, 1),
    (1, '1471', '存货跌价准备', 'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, '存货备抵科目（贷方余额）',   NOW(), NOW(), 1, 1),
    -- 非流动资产
    (1, '1601', '固定资产',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1600'), false, true, '机器设备、厂房等',             NOW(), NOW(), 1, 1),
    (1, '1602', '累计折旧',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1600'), false, true, '固定资产备抵科目（贷方余额）', NOW(), NOW(), 1, 1),
    (1, '1604', '在建工程',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1600'), false, true, 'CIP 资本化前归集',             NOW(), NOW(), 1, 1),
    -- 流动负债
    (1, '2202', '应付账款',   'LIABILITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '2000'), true,  true, 'AP 统制科目，关联供应商子帐', NOW(), NOW(), 1, 1),
    (1, '2203', '预收账款',   'LIABILITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '2000'), false, true, '客户预收款',                   NOW(), NOW(), 1, 1),
    (1, '2221', '应交税费',   'LIABILITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '2000'), false, true, '增值税等应交税费',             NOW(), NOW(), 1, 1),
    (1, '2241', '其他应付款', 'LIABILITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '2000'), false, true, '押金、代扣款等',               NOW(), NOW(), 1, 1),
    -- 所有者权益
    (1, '3001', '实收资本',   'EQUITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '3000'), false, true, '股东投入资本',                 NOW(), NOW(), 1, 1),
    (1, '3103', '盈余公积',   'EQUITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '3000'), false, true, '法定/任意盈余公积',            NOW(), NOW(), 1, 1),
    (1, '3104', '未分配利润', 'EQUITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '3000'), false, true, '滚存未分配利润',               NOW(), NOW(), 1, 1),
    -- 营业收入
    (1, '6001', '主营业务收入', 'REVENUE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '4000'), false, true, '鞋品销售收入',               NOW(), NOW(), 1, 1),
    (1, '6051', '其他业务收入', 'REVENUE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '4000'), false, true, '废料出售、劳务收入等',       NOW(), NOW(), 1, 1),
    (1, '6115', '资产处置损益', 'REVENUE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '4000'), false, true, '固定资产出售/报废净损益（FA disposal_gain_loss）', NOW(), NOW(), 1, 1),
    (1, '6301', '营业外收入',   'REVENUE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '4000'), false, true, '政府补助等（非资产处置）',       NOW(), NOW(), 1, 1),
    -- 营业成本及生产
    (1, '6401', '主营业务成本',     'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5000'), false, true, 'COGS 销货成本',              NOW(), NOW(), 1, 1),
    (1, '6402', '其他业务成本',     'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5000'), false, true, '其他业务对应成本',           NOW(), NOW(), 1, 1),
    (1, '5101', '生产成本',         'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5000'), false, true, '直接材料/人工/吸收制造费用', NOW(), NOW(), 1, 1),
    (1, '5102', '制造费用',         'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5000'), false, true, '间接制造费用池',             NOW(), NOW(), 1, 1),
    (1, '5103', '制造费用-已吸收',  'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5000'), false, true, 'Overhead Applied 过渡科目',  NOW(), NOW(), 1, 1),
    (1, '5104', '制造费用差异',     'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5000'), false, true, '少/多吸收制造费用差异',      NOW(), NOW(), 1, 1),
    -- 期间费用
    (1, '6601', '销售费用',   'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '6000'), false, true, '市场推广、运费等',             NOW(), NOW(), 1, 1),
    (1, '6602', '管理费用',   'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '6000'), false, true, '行政及管理费用',               NOW(), NOW(), 1, 1),
    (1, '6603', '财务费用',   'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '6000'), false, true, '利息、汇兑损益、手续费',       NOW(), NOW(), 1, 1),
    (1, '6711', '营业外支出', 'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '6000'), false, true, '罚款、捐赠等（非资产处置）',             NOW(), NOW(), 1, 1),
    (1, '6801', '所得税费用', 'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '6000'), false, true, '当期所得税',                   NOW(), NOW(), 1, 1);

-- =====================================================
-- 3. 三级科目（明细科目）
-- =====================================================

INSERT INTO lychee_erp.gl_accounts
    (tenant_id, code, name, account_type, parent_id, is_reconciliation, is_active, description, created_at, updated_at, created_by, updated_by)
VALUES
    -- 银行存款明细（供 company_bank_accounts 绑定）
    (1, '100201', '汇丰银行-香港账户',     'CASH', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1002'), false, true, '美金基本户',           NOW(), NOW(), 1, 1),
    (1, '100202', '越南技商银行-越盾户', 'CASH', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1002'), false, true, '越南本地运营账户',       NOW(), NOW(), 1, 1),
    (1, '100203', '备用金',              'CASH', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1002'), false, true, '各部门零用金',           NOW(), NOW(), 1, 1),
    -- 固定资产明细（供 asset_categories 绑定）
    (1, '160101', '固定资产-机器设备',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1601'), false, true, '制鞋生产线设备',         NOW(), NOW(), 1, 1),
    (1, '160102', '固定资产-运输工具',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1601'), false, true, '商务车辆',               NOW(), NOW(), 1, 1),
    (1, '160103', '固定资产-办公设备',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1601'), false, true, '电脑、家具等',           NOW(), NOW(), 1, 1),
    (1, '160201', '累计折旧-机器设备',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1602'), false, true, '机器设备累计折旧',       NOW(), NOW(), 1, 1),
    (1, '160202', '累计折旧-运输工具',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1602'), false, true, '运输工具累计折旧',       NOW(), NOW(), 1, 1),
    (1, '160203', '累计折旧-办公设备',   'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1602'), false, true, '办公设备累计折旧',       NOW(), NOW(), 1, 1),
    -- 应交税费明细
    (1, '222101', '应交增值税-销项',     'LIABILITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '2221'), false, true, '销项税额',               NOW(), NOW(), 1, 1),
    (1, '222102', '应交增值税-进项',     'LIABILITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '2221'), false, true, '进项税额（借方余额时）', NOW(), NOW(), 1, 1),
    (1, '220201', '应付暂估',           'LIABILITY', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '2202'), false, true, 'GR/IR 收货暂估清算科目', NOW(), NOW(), 1, 1),
    (1, '140701', '材料成本差异',       'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, '采购发票与收货暂估价格差异', NOW(), NOW(), 1, 1),
    (1, '140702', '存货成本调整',       'ASSET', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '1000'), false, true, 'Cost Run 结存标准/实际差异重估（不按评估类拆分）', NOW(), NOW(), 1, 1),
    -- 制造费用明细（供 cost_allocations 分摊）
    (1, '510201', '制造费用-折旧',       'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5102'), false, true, '生产部门设备折旧',       NOW(), NOW(), 1, 1),
    (1, '510202', '制造费用-水电费',     'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5102'), false, true, '生产车间水电',             NOW(), NOW(), 1, 1),
    (1, '510203', '制造费用-厂务部',     'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5102'), false, true, '厂务共同费用池',         NOW(), NOW(), 1, 1),
    (1, '510204', '制造费用-生产一部',   'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5102'), false, true, '分摊目标：生产一部',     NOW(), NOW(), 1, 1),
    (1, '510205', '制造费用-生产二部',   'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '5102'), false, true, '分摊目标：生产二部',     NOW(), NOW(), 1, 1),
    -- 管理/销售费用明细
    (1, '660201', '管理费用-折旧',       'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '6602'), false, true, '管理部门资产折旧',       NOW(), NOW(), 1, 1),
    (1, '660202', '管理费用-薪酬',       'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '6602'), false, true, '管理人员工资',           NOW(), NOW(), 1, 1),
    (1, '660301', '财务费用-手续费',     'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '6603'), false, true, '银行转账手续费',         NOW(), NOW(), 1, 1),
    (1, '660302', '财务费用-汇兑损益',   'EXPENSE', (SELECT id FROM lychee_erp.gl_accounts WHERE tenant_id = 1 AND code = '6603'), false, true, '外币折算差异',           NOW(), NOW(), 1, 1);

-- =====================================================
-- 4. 验证
-- =====================================================

SELECT account_type, COUNT(*) AS count
FROM lychee_erp.gl_accounts
WHERE tenant_id = 1
GROUP BY account_type
ORDER BY account_type;

SELECT code, name, account_type, is_reconciliation, is_active
FROM lychee_erp.gl_accounts
WHERE tenant_id = 1
ORDER BY code;

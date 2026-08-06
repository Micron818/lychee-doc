-- =====================================================
-- valuation_classes + material_type mapping + account determination
-- 执行前提：gl_accounts、material_types 已导入；0710-001 表结构已创建
-- =====================================================

-- 1. Valuation classes
INSERT INTO lychee_erp.valuation_classes
	(tenant_id, code, name, is_inventoried, is_active, description, created_at, updated_at, created_by, updated_by)
SELECT 1, v.code, v.name, v.is_inventoried, true, v.description, NOW(), NOW(), 1, 1
FROM (VALUES
	('VC-ROH',   '原材料',     true,  '原材料存货'),
	('VC-HALB',  '半成品',     true,  '半成品/在产品'),
	('VC-FERT',  '成品',       true,  '库存商品'),
	('VC-PACK',  '包装物',     true,  '包装材料'),
	('VC-HIBE',  '辅料及低耗', true,  '辅料/消耗品/工具'),
	('VC-EXP',   '费用性采购', false, '不入库存的费用采购'),
	('VC-ASSET', '资本性采购', false, '设备/固定资产采购')
) AS v(code, name, is_inventoried, description)
WHERE NOT EXISTS (
	SELECT 1 FROM lychee_erp.valuation_classes vc WHERE vc.tenant_id = 1 AND vc.code = v.code
);

-- 2. Material type → valuation class defaults
INSERT INTO lychee_erp.material_type_valuation_classes
	(tenant_id, material_type_id, valuation_class_id, is_default, created_at, updated_at, created_by, updated_by)
SELECT 1, mt.id, vc.id, true, NOW(), NOW(), 1, 1
FROM (VALUES
	('RM', 'VC-ROH'),
	('SF', 'VC-HALB'),
	('FG', 'VC-FERT'),
	('PACK', 'VC-PACK'),
	('HIBE', 'VC-HIBE'),
	('ASSET', 'VC-ASSET')
) AS m(type_code, vc_code)
JOIN lychee_erp.material_types mt ON mt.tenant_id = 1 AND mt.code = m.type_code
JOIN lychee_erp.valuation_classes vc ON vc.tenant_id = 1 AND vc.code = m.vc_code
WHERE NOT EXISTS (
	SELECT 1 FROM lychee_erp.material_type_valuation_classes x
	WHERE x.tenant_id = 1 AND x.material_type_id = mt.id AND x.valuation_class_id = vc.id
);

-- 3. Account determination (tenant-level defaults, company_id NULL)
INSERT INTO lychee_erp.fi_account_determination
	(tenant_id, company_id, posting_key, valuation_class_id, gl_account_id, is_active, created_at, updated_at, created_by, updated_by)
SELECT 1, NULL, d.posting_key, vc.id, ga.id, true, NOW(), NOW(), 1, 1
FROM (VALUES
	('INV_STOCK', 'VC-ROH',   '1401'),
	('INV_STOCK', 'VC-HALB',  '1403'),
	('INV_STOCK', 'VC-FERT',  '1405'),
	('INV_STOCK', 'VC-PACK',  '1411'),
	('INV_STOCK', 'VC-HIBE',  '1411'),
	('EXPENSE',   'VC-EXP',   '6602'),
	('CIP',       'VC-ASSET', '1604')
) AS d(posting_key, vc_code, gl_code)
JOIN lychee_erp.valuation_classes vc ON vc.tenant_id = 1 AND vc.code = d.vc_code
JOIN lychee_erp.gl_accounts ga ON ga.tenant_id = 1 AND ga.code = d.gl_code
WHERE NOT EXISTS (
	SELECT 1 FROM lychee_erp.fi_account_determination x
	WHERE x.tenant_id = 1 AND x.company_id IS NULL
	  AND x.posting_key = d.posting_key AND x.valuation_class_id = vc.id
);

INSERT INTO lychee_erp.fi_account_determination
	(tenant_id, company_id, posting_key, valuation_class_id, gl_account_id, is_active, created_at, updated_at, created_by, updated_by)
SELECT 1, NULL, d.posting_key, vc.id, ga.id, true, NOW(), NOW(), 1, 1
FROM (VALUES
	('REVENUE', 'VC-ROH',  '6001'),
	('REVENUE', 'VC-HALB', '6001'),
	('REVENUE', 'VC-FERT', '6001'),
	('REVENUE', 'VC-PACK', '6001'),
	('REVENUE', 'VC-HIBE', '6001'),
	('REVENUE', 'VC-EXP',  '6001'),
	('REVENUE', 'VC-ASSET','6001')
) AS d(posting_key, vc_code, gl_code)
JOIN lychee_erp.valuation_classes vc ON vc.tenant_id = 1 AND vc.code = d.vc_code
JOIN lychee_erp.gl_accounts ga ON ga.tenant_id = 1 AND ga.code = d.gl_code
WHERE NOT EXISTS (
	SELECT 1 FROM lychee_erp.fi_account_determination x
	WHERE x.tenant_id = 1 AND x.company_id IS NULL
	  AND x.posting_key = d.posting_key AND x.valuation_class_id = vc.id
);

-- Wildcard keys (no valuation class)
INSERT INTO lychee_erp.fi_account_determination
	(tenant_id, company_id, posting_key, valuation_class_id, gl_account_id, is_active, created_at, updated_at, created_by, updated_by)
SELECT 1, NULL, d.posting_key, NULL, ga.id, true, NOW(), NOW(), 1, 1
FROM (VALUES
	('GRIR',          '220201'),
	('INPUT_TAX',     '222102'),
	('OUTPUT_TAX',    '222101'),
	('PRICE_VAR',     '140701'),
	('INV_STOCK',     '140702'),
	('EXCHANGE_DIFF', '660302'),
	('COGS',          '6401'),
	('WIP',           '5101'),
	('CIP',           '1604'),
	('REVENUE',       '6001')
) AS d(posting_key, gl_code)
JOIN lychee_erp.gl_accounts ga ON ga.tenant_id = 1 AND ga.code = d.gl_code
WHERE NOT EXISTS (
	SELECT 1 FROM lychee_erp.fi_account_determination x
	WHERE x.tenant_id = 1 AND x.company_id IS NULL
	  AND x.posting_key = d.posting_key AND x.valuation_class_id IS NULL
);

-- 4. Backfill materials.valuation_class_id from type default
UPDATE lychee_erp.materials m
SET valuation_class_id = mtvc.valuation_class_id
FROM lychee_erp.material_type_valuation_classes mtvc
WHERE m.tenant_id = mtvc.tenant_id
  AND m.material_type_id = mtvc.material_type_id
  AND mtvc.is_default = true
  AND m.valuation_class_id IS NULL;

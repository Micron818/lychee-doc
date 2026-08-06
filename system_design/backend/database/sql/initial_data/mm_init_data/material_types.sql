-- =====================================================
-- 物料类型初始化数据
-- =====================================================

ALTER SEQUENCE lychee_erp.material_types_id_seq RESTART ;

TRUNCATE TABLE lychee_erp.material_types CASCADE;

INSERT INTO lychee_erp.material_types (tenant_id, code, name, is_inventoried, is_purchased, is_sold, is_manufactured, status_option_id, created_by, updated_by,updated_at,created_at) VALUES
(1, 'TYPE-001', '原材料', true, true, false, false, 1, 1, 1, now(), now()),
(1, 'TYPE-002', '半成品', true, false, false, true, 1, 1, 1, now(), now()),
(1, 'TYPE-003', '成品', true, false, true, true, 1, 1, 1, now(), now()),
(1, 'TYPE-004', '辅料', true, true, false, false, 1, 1, 1, now(), now()),
(1, 'TYPE-005', '包装材料', true, true, false, false, 1, 1, 1, now(), now()),
(1, 'TYPE-006', '消耗品', true, true, false, false, 1, 1, 1, now(), now()),
(1, 'TYPE-007', '工具', true, true, false, false, 1, 1, 1, now(), now()),
(1, 'TYPE-008', '设备', false, true, false, false, 1, 1, 1, now(), now());

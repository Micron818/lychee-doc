-- =====================================================
-- 物料单位初始化数据
-- =====================================================

ALTER SEQUENCE lychee_erp.material_units_id_seq RESTART ;

TRUNCATE TABLE lychee_erp.material_units CASCADE;

INSERT INTO lychee_erp.material_units (tenant_id, code, name, description, status_option_id, created_by, updated_by,updated_at,created_at) VALUES
(1, 'UNIT-001', '双', '鞋类基本单位', 1, 1, 1, now(), now()),
(1, 'UNIT-002', '只', '单只鞋的单位', 1, 1, 1, now(), now()),
(1, 'UNIT-003', '双/箱', '每箱装鞋数量', 1, 1, 1, now(), now()),
(1, 'UNIT-004', '米', '长度单位，用于布料、皮革等', 1, 1, 1, now(), now()),
(1, 'UNIT-005', '码', '长度单位，用于布料', 1, 1, 1, now(), now()),
(1, 'UNIT-006', '公斤', '重量单位，用于橡胶、化工原料等', 1, 1, 1, now(), now()),
(1, 'UNIT-007', '克', '重量单位，用于小量材料', 1, 1, 1, now(), now()),
(1, 'UNIT-008', '平方米', '面积单位，用于皮革、布料等', 1, 1, 1, now(), now()),
(1, 'UNIT-009', '张', '用于皮革、纸板等', 1, 1, 1, now(), now()),
(1, 'UNIT-010', '卷', '用于线、带等', 1, 1, 1, now(), now()),
(1, 'UNIT-011', '个', '通用计数单位', 1, 1, 1, now(), now()),
(1, 'UNIT-012', '套', '成套材料单位', 1, 1, 1, now(), now());

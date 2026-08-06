-- =====================================================
-- 产品型号初始化数据
-- =====================================================

ALTER SEQUENCE lychee_erp.product_models_id_seq RESTART ;

TRUNCATE TABLE lychee_erp.product_models CASCADE;

INSERT INTO lychee_erp.product_models (tenant_id, code, name, description, status_option_id, created_by, updated_by,updated_at,created_at  ) VALUES
(1, 'MODEL-001', '运动鞋-001', '经典款运动鞋', 1, 1, 1, now(), now()),
(1, 'MODEL-002', '运动鞋-002', '轻量款运动鞋', 1, 1, 1, now(), now()),
(1, 'MODEL-003', '休闲鞋-001', '日常休闲鞋', 1, 1, 1, now(), now()),
(1, 'MODEL-004', '休闲鞋-002', '时尚休闲鞋', 1, 1, 1, now(), now()),
(1, 'MODEL-005', '皮鞋-001', '商务正装皮鞋', 1, 1, 1, now(), now()),
(1, 'MODEL-006', '皮鞋-002', '休闲皮鞋', 1, 1, 1, now(), now()),
(1, 'MODEL-007', '凉鞋-001', '夏季凉鞋', 1, 1, 1, now(), now()),
(1, 'MODEL-008', '凉鞋-002', '沙滩凉鞋', 1, 1, 1, now(), now()),
(1, 'MODEL-009', '靴子-001', '短靴', 1, 1, 1, now(), now()),
(1, 'MODEL-010', '靴子-002', '长靴', 1, 1, 1, now(), now());

-- =====================================================
-- 产品尺码初始化数据
-- =====================================================

ALTER SEQUENCE lychee_erp.product_sizes_id_seq RESTART ;

TRUNCATE TABLE lychee_erp.product_sizes CASCADE;

INSERT INTO lychee_erp.product_sizes (tenant_id, code, name, sequence, status_option_id, created_by, updated_by,updated_at,created_at) VALUES
(1, 'SIZE-001', '35', 1, 1, 1, 1, now(), now()),
(1, 'SIZE-002', '36', 2, 1, 1, 1, now(), now()),
(1, 'SIZE-003', '37', 3, 1, 1, 1, now(), now()),
(1, 'SIZE-004', '38', 4, 1, 1, 1, now(), now()),
(1, 'SIZE-005', '39', 5, 1, 1, 1, now(), now()),
(1, 'SIZE-006', '40', 6, 1, 1, 1, now(), now()),
(1, 'SIZE-007', '41', 7, 1, 1, 1, now(), now()),
(1, 'SIZE-008', '42', 8, 1, 1, 1, now(), now()),
(1, 'SIZE-009', '43', 9, 1, 1, 1, now(), now()),
(1, 'SIZE-010', '44', 10, 1, 1, 1, now(), now()),
(1, 'SIZE-011', '45', 11, 1, 1, 1, now(), now()),
(1, 'SIZE-012', '46', 12, 1, 1, 1, now(), now());

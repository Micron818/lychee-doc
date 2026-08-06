-- =====================================================
-- 颜色资料初始化数据
-- =====================================================
ALTER SEQUENCE lychee_erp.colors_id_seq RESTART ;

TRUNCATE TABLE lychee_erp.colors CASCADE;

INSERT INTO lychee_erp.colors (tenant_id, code, name, hex_code, status_option_id, created_by, updated_by,updated_at,created_at) VALUES
(1, 'COLOR-001', '黑色', '#000000', 1, 1, 1, now(), now()),
(1, 'COLOR-002', '白色', '#FFFFFF', 1, 1, 1, now(), now()),
(1, 'COLOR-003', '红色', '#FF0000', 1, 1, 1, now(), now()),
(1, 'COLOR-004', '蓝色', '#0000FF', 1, 1, 1, now(), now()),
(1, 'COLOR-005', '绿色', '#008000', 1, 1, 1, now(), now()),
(1, 'COLOR-006', '黄色', '#FFFF00', 1, 1, 1, now(), now()),
(1, 'COLOR-007', '棕色', '#A52A2A', 1, 1, 1, now(), now()),
(1, 'COLOR-008', '灰色', '#808080', 1, 1, 1, now(), now()),
(1, 'COLOR-009', '米色', '#F5F5DC', 1, 1, 1, now(), now()),
(1, 'COLOR-010', '粉色', '#FFC0CB', 1, 1, 1, now(), now()),
(1, 'COLOR-011', '紫色', '#800080', 1, 1, 1, now(), now()),
(1, 'COLOR-012', '橙色', '#FFA500', 1, 1, 1, now(), now());

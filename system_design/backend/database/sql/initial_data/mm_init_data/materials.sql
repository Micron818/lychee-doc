-- =====================================================
-- 物料初始化数据
-- =====================================================
-- 注意：此文件依赖以下表的初始化数据：
-- - material_categories (id: 1-17)
-- - material_types (id: 1-8)
-- - product_models (id: 1-10)
-- - colors (id: 1-12)
-- - product_sizes (id: 1-12)
-- - material_units (id: 1-12)

ALTER SEQUENCE lychee_erp.materials_id_seq RESTART ;

TRUNCATE TABLE lychee_erp.materials CASCADE;

INSERT INTO lychee_erp.materials (tenant_id, material_category_id, material_type_id, product_model_id, color_id, product_size_id, code, name, specification, base_unit_id, purchase_unit_id, sales_unit_id, status_option_id, created_by, updated_by,updated_at,created_at) VALUES
-- 成品鞋
(1, 5, 3, 1, 1, 6, 'MAT-001', '运动鞋-001-黑色-40', '经典款运动鞋，黑色，40码', 1, 1, 1, 1, 1, 1, now(), now()),
(1, 5, 3, 1, 2, 6, 'MAT-002', '运动鞋-001-白色-40', '经典款运动鞋，白色，40码', 1, 1, 1, 1, 1, 1, now(), now()),
(1, 5, 3, 1, 1, 7, 'MAT-003', '运动鞋-001-黑色-41', '经典款运动鞋，黑色，41码', 1, 1, 1, 1, 1, 1, now(), now()),
(1, 5, 3, 2, 3, 6, 'MAT-004', '运动鞋-002-红色-40', '轻量款运动鞋，红色，40码', 1, 1, 1, 1, 1, 1, now(), now()),
(1, 5, 3, 3, 1, 5, 'MAT-005', '休闲鞋-001-黑色-39', '日常休闲鞋，黑色，39码', 1, 1, 1, 1, 1, 1, now(), now()),
-- 原材料 - 皮革
(1, 6, 1, NULL, NULL, NULL, 'MAT-006', '真牛皮革', '头层牛皮，厚度2.0-2.5mm', 8, 8, 8, 1, 1, 1, now(), now()),
(1, 6, 1, NULL, NULL, NULL, 'MAT-007', 'PU合成革', 'PU材质，厚度1.5-2.0mm', 8, 8, 8, 1, 1, 1, now(), now()),
(1, 6, 1, NULL, NULL, NULL, 'MAT-008', '人造革', 'PVC材质，厚度1.0-1.5mm', 8, 8, 8, 1, 1, 1, now(), now()),
-- 原材料 - 布料
(1, 7, 1, NULL, NULL, NULL, 'MAT-009', '帆布', '12盎司帆布，宽度150cm', 4, 4, 4, 1, 1, 1, now(), now()),
(1, 7, 1, NULL, NULL, NULL, 'MAT-010', '网布', '透气网布，宽度150cm', 4, 4, 4, 1, 1, 1, now(), now()),
(1, 7, 1, NULL, NULL, NULL, 'MAT-011', '针织布', '弹性针织布，宽度150cm', 4, 4, 4, 1, 1, 1, now(), now()),
-- 原材料 - 鞋底材料
(1, 10, 1, NULL, NULL, NULL, 'MAT-012', '天然橡胶', '天然橡胶，硬度60-65度', 6, 6, 6, 1, 1, 1, now(), now()),
(1, 10, 1, NULL, NULL, NULL, 'MAT-013', '合成橡胶', '合成橡胶，硬度60-65度', 6, 6, 6, 1, 1, 1, now(), now()),
(1, 11, 1, NULL, NULL, NULL, 'MAT-014', 'EVA发泡材料', 'EVA发泡，密度0.15-0.20g/cm³', 6, 6, 6, 1, 1, 1, now(), now()),
(1, 12, 1, NULL, NULL, NULL, 'MAT-015', 'TPR材料', 'TPR热塑性橡胶，硬度55-60度', 6, 6, 6, 1, 1, 1, now(), now()),
-- 辅料 - 线材
(1, 14, 4, NULL, NULL, NULL, 'MAT-016', '尼龙线', '尼龙缝纫线，规格40/2', 10, 10, 10, 1, 1, 1, now(), now()),
(1, 14, 4, NULL, NULL, NULL, 'MAT-017', '鞋带', '圆头鞋带，长度120cm', 11, 11, 11, 1, 1, 1, now(), now()),
-- 辅料 - 胶水
(1, 15, 4, NULL, NULL, NULL, 'MAT-018', 'PU胶', '聚氨酯胶水，5公斤装', 6, 6, 6, 1, 1, 1, now(), now()),
(1, 15, 4, NULL, NULL, NULL, 'MAT-019', '氯丁胶', '氯丁橡胶胶水，5公斤装', 6, 6, 6, 1, 1, 1, now(), now()),
-- 辅料 - 五金件
(1, 16, 4, NULL, NULL, NULL, 'MAT-020', '鞋扣', '金属鞋扣，规格20mm', 11, 11, 11, 1, 1, 1, now(), now()),
(1, 16, 4, NULL, NULL, NULL, 'MAT-021', '拉链', '金属拉链，长度30cm', 11, 11, 11, 1, 1, 1, now(), now()),
-- 包装材料
(1, 17, 5, NULL, NULL, NULL, 'MAT-022', '鞋盒', '标准鞋盒，尺寸32x22x12cm', 11, 11, 11, 1, 1, 1, now(), now()),
(1, 18, 5, NULL, NULL, NULL, 'MAT-023', '产品标签', '不干胶标签，尺寸5x3cm', 11, 11, 11, 1, 1, 1, now(), now()),
(1, 19, 5, NULL, NULL, NULL, 'MAT-024', '包装袋', 'PE塑料袋，尺寸40x30cm', 11, 11, 11, 1, 1, 1, now(), now());

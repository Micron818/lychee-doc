-- =====================================================
-- ERP 物料管理模块 - 初始化数据主文件
-- =====================================================
-- 说明：此文件按外键依赖顺序执行 MM 模块的所有初始化数据
-- 执行顺序：必须在 adm_init_data.sql 和 basis_init_data.sql 之后执行
-- 注意：使用 PostgreSQL 的 \i 命令执行外部 SQL 文件

-- =====================================================
-- 执行顺序说明：
-- 1. colors - 颜色资料（无依赖）
-- 2. material_units - 物料单位（无依赖）
-- 3. material_types - 物料类型（无依赖）
-- 4. material_categories - 物料分类（无依赖，parent_id 可自引用）
-- 5. product_sizes - 产品尺码（无依赖）
-- 6. product_models - 产品型号（无依赖）
-- 7. materials - 物料（依赖：material_categories, material_types, product_models, colors, product_sizes, material_units）
-- 8. material_unit_conversions - 物料单位换算（依赖：materials, material_units）
-- =====================================================

\cd C:/WorkSpace/WorkSpace/lychee/lychee-backend/docs/database/sql/initial_data

\i mm_init_data/colors.sql
\i mm_init_data/material_units.sql
\i mm_init_data/material_types.sql
\i mm_init_data/material_categories.sql
\i mm_init_data/product_sizes.sql
\i mm_init_data/product_models.sql
\i mm_init_data/materials.sql
\i mm_init_data/material_unit_conversions.sql

-- =====================================================
-- 验证数据插入结果
-- =====================================================

SELECT 'Colors' as table_name, COUNT(*) as count FROM lychee_erp.colors
UNION ALL
SELECT 'Material Units', COUNT(*) FROM lychee_erp.material_units
UNION ALL
SELECT 'Material Types', COUNT(*) FROM lychee_erp.material_types
UNION ALL
SELECT 'Material Categories', COUNT(*) FROM lychee_erp.material_categories
UNION ALL
SELECT 'Product Sizes', COUNT(*) FROM lychee_erp.product_sizes
UNION ALL
SELECT 'Product Models', COUNT(*) FROM lychee_erp.product_models
UNION ALL
SELECT 'Materials', COUNT(*) FROM lychee_erp.materials
UNION ALL
SELECT 'Material Unit Conversions', COUNT(*) FROM lychee_erp.material_unit_conversions;

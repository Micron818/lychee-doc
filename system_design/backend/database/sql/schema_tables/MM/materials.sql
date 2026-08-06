 

DROP TABLE IF EXISTS lychee_erp.materials CASCADE
;

CREATE TABLE lychee_erp.materials
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	material_category_id bigint NOT NULL,
	material_type_id bigint NULL,
	valuation_class_id bigint NULL,
	product_model_id bigint NULL,
	color_id bigint NULL,
	product_size_id bigint NULL,
	name varchar(200) NOT NULL,
	specification text NULL,
	base_unit_id bigint NOT NULL,
	purchase_unit_id bigint NULL,
	sales_unit_id bigint NULL,
	status_option_id bigint NULL,
	is_unlimited_over_receipt boolean NOT NULL   DEFAULT true,
	over_receipt_tolerance numeric(18,6) NULL,
	low_level_code integer NOT NULL DEFAULT 0,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT materials_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT uk_materials_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_materials_color ON lychee_erp.materials (color_id ASC)
;

CREATE INDEX idx_materials_product_model ON lychee_erp.materials (product_model_id ASC)
;

CREATE INDEX idx_materials_category ON lychee_erp.materials (material_category_id ASC)
;

CREATE INDEX idx_materials_status_option ON lychee_erp.materials (status_option_id ASC)
;

CREATE INDEX idx_materials_base_unit ON lychee_erp.materials (base_unit_id ASC)
;

CREATE INDEX idx_materials_product_size ON lychee_erp.materials (product_size_id ASC)
;

CREATE INDEX idx_materials_type ON lychee_erp.materials (material_type_id ASC)
;

CREATE INDEX idx_materials_valuation_class ON lychee_erp.materials (valuation_class_id ASC)
;

CREATE INDEX idx_materials_llc ON lychee_erp.materials (tenant_id ASC, low_level_code ASC)
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_category
	FOREIGN KEY (material_category_id) REFERENCES lychee_erp.material_categories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_type
	FOREIGN KEY (material_type_id) REFERENCES lychee_erp.material_types (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_valuation_class
	FOREIGN KEY (valuation_class_id) REFERENCES lychee_erp.valuation_classes (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_product_model
	FOREIGN KEY (product_model_id) REFERENCES lychee_erp.product_models (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_color
	FOREIGN KEY (color_id) REFERENCES lychee_erp.colors (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_product_size
	FOREIGN KEY (product_size_id) REFERENCES lychee_erp.product_sizes (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_base_unit
	FOREIGN KEY (base_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_purchase_unit
	FOREIGN KEY (purchase_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_sales_unit
	FOREIGN KEY (sales_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.materials ADD CONSTRAINT fk_materials_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
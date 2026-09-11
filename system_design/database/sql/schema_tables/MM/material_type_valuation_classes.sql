DROP TABLE IF EXISTS lychee_erp.material_type_valuation_classes CASCADE;

CREATE TABLE lychee_erp.material_type_valuation_classes
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	material_type_id bigint NOT NULL,
	valuation_class_id bigint NOT NULL,
	is_default boolean NOT NULL DEFAULT false,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.material_type_valuation_classes ADD CONSTRAINT material_type_valuation_classes_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.material_type_valuation_classes
	ADD CONSTRAINT uk_material_type_valuation_classes UNIQUE (tenant_id, material_type_id, valuation_class_id);

CREATE UNIQUE INDEX uk_material_type_valuation_classes_default
	ON lychee_erp.material_type_valuation_classes (tenant_id, material_type_id)
	WHERE is_default = true;

CREATE INDEX idx_mtvc_material_type ON lychee_erp.material_type_valuation_classes (material_type_id ASC);
CREATE INDEX idx_mtvc_valuation_class ON lychee_erp.material_type_valuation_classes (valuation_class_id ASC);

ALTER TABLE lychee_erp.material_type_valuation_classes ADD CONSTRAINT fk_mtvc_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_type_valuation_classes ADD CONSTRAINT fk_mtvc_material_type
	FOREIGN KEY (material_type_id) REFERENCES lychee_erp.material_types (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_type_valuation_classes ADD CONSTRAINT fk_mtvc_valuation_class
	FOREIGN KEY (valuation_class_id) REFERENCES lychee_erp.valuation_classes (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_type_valuation_classes ADD CONSTRAINT fk_mtvc_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_type_valuation_classes ADD CONSTRAINT fk_mtvc_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON TABLE lychee_erp.material_type_valuation_classes IS '物料类型允许的评估类及默认评估类';

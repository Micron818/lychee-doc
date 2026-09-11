 

DROP TABLE IF EXISTS lychee_erp.material_unit_conversions CASCADE
;

CREATE TABLE lychee_erp.material_unit_conversions
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	material_id bigint NOT NULL,
	unit_id bigint NOT NULL,
	to_base_unit_id bigint NOT NULL,
	conversion_rate numeric(18,6) NOT NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.material_unit_conversions ADD CONSTRAINT material_unit_conversions_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.material_unit_conversions ADD CONSTRAINT uk_material_unit_conversions UNIQUE (tenant_id,material_id,unit_id)
;

CREATE INDEX idx_unit_conversions_material ON lychee_erp.material_unit_conversions (material_id ASC)
;

ALTER TABLE lychee_erp.material_unit_conversions ADD CONSTRAINT fk_unit_conversions_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_unit_conversions ADD CONSTRAINT fk_unit_conversions_unit
	FOREIGN KEY (unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_unit_conversions ADD CONSTRAINT fk_unit_conversions_to_base
	FOREIGN KEY (to_base_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

 
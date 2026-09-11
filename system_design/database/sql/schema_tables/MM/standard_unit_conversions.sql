 

DROP TABLE IF EXISTS lychee_erp.standard_unit_conversions CASCADE
;

CREATE TABLE lychee_erp.standard_unit_conversions
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
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

ALTER TABLE lychee_erp.standard_unit_conversions ADD CONSTRAINT pk_standard_unit_conversions
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.standard_unit_conversions ADD CONSTRAINT uk_standard_unit_conversions UNIQUE (tenant_id,unit_id)
;

CREATE INDEX IXFK_standard_unit_conversions_material_units ON lychee_erp.standard_unit_conversions (unit_id ASC)
;

CREATE INDEX IXFK_standard_unit_conversions_material_units_02 ON lychee_erp.standard_unit_conversions (to_base_unit_id ASC)
;

ALTER TABLE lychee_erp.standard_unit_conversions ADD CONSTRAINT fk_standard_unit_conversions_material_units
	FOREIGN KEY (unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.standard_unit_conversions ADD CONSTRAINT fk_standard_unit_conversions_material_units_02
	FOREIGN KEY (to_base_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

 
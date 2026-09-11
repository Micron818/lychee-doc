 

DROP TABLE IF EXISTS lychee_erp.material_factories CASCADE
;

CREATE TABLE lychee_erp.material_factories
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	material_id bigint NOT NULL,
	receiving_warehouse_id bigint NULL,
	issue_warehouse_id bigint NULL,
	is_batch_mandatory boolean NOT NULL   DEFAULT false,
	is_backflush boolean NOT NULL   DEFAULT false,
	under_issue_tolerance numeric(18,6) NOT NULL   DEFAULT 0,
	under_delivery_tolerance numeric(18,6) NOT NULL   DEFAULT 0,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.material_factories ADD CONSTRAINT pk_material_factories
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.material_factories ADD CONSTRAINT uk_material_factories UNIQUE (tenant_id,factory_id,material_id)
;

CREATE INDEX ixfk_material_factories_materials ON lychee_erp.material_factories (material_id ASC)
;

ALTER TABLE lychee_erp.material_factories ADD CONSTRAINT fk_material_factories_materials
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

 
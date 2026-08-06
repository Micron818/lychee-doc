 

DROP TABLE IF EXISTS lychee_erp.mrp_parameters CASCADE
;

CREATE TABLE lychee_erp.mrp_parameters
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	factory_id bigint NULL,
	material_id bigint NULL,
	lot_sizing_procedure varchar(20) NOT NULL,
	min_lot_size numeric(18,6) NOT NULL   DEFAULT 0,
	max_lot_size numeric(18,6) NOT NULL   DEFAULT 0,
	rounding_value numeric(18,6) NOT NULL   DEFAULT 1,
	fixed_lot_size numeric(18,6) NOT NULL   DEFAULT 0,
	period_days integer NOT NULL   DEFAULT 0,
	lead_time_days numeric(10,2) NOT NULL   DEFAULT 0,
	safety_stock_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	created_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_at timestamp without time zone NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.mrp_parameters ADD CONSTRAINT pk_mrp_parameters
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.mrp_parameters ADD CONSTRAINT uk_mrp_parameters UNIQUE (tenant_id,factory_id,material_id)
;

CREATE INDEX IXFK_mrp_parameters_factories ON lychee_erp.mrp_parameters (factory_id ASC)
;

CREATE INDEX IXFK_mrp_parameters_materials ON lychee_erp.mrp_parameters (material_id ASC)
;

ALTER TABLE lychee_erp.mrp_parameters ADD CONSTRAINT fk_mrp_parameters_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.mrp_parameters ADD CONSTRAINT fk_mrp_parameters_materials
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

 
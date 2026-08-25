

DROP TABLE IF EXISTS lychee_erp.mrp_results CASCADE
;

CREATE TABLE lychee_erp.mrp_results
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	mrp_run_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	material_id bigint NOT NULL,
	required_date date NOT NULL,
	required_quantity numeric(18,6) NOT NULL,
	suggested_action_type varchar(20) NOT NULL,
	planned_start_date date NOT NULL,
	planned_end_date date NOT NULL,
	converted_quantity numeric(18,6) NOT NULL DEFAULT 0,
	convert_status varchar(20) NOT NULL DEFAULT 'OPEN',
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.mrp_results ADD CONSTRAINT mrp_results_pkey
	PRIMARY KEY (id)
;

CREATE INDEX IXFK_mrp_results_factories ON lychee_erp.mrp_results (factory_id ASC)
;

CREATE INDEX idx_mrp_results_run ON lychee_erp.mrp_results (mrp_run_id ASC)
;

CREATE INDEX idx_mrp_results_material ON lychee_erp.mrp_results (material_id ASC)
;

CREATE INDEX ix_mrp_results_factory_convert ON lychee_erp.mrp_results (factory_id ASC, convert_status ASC)
;

ALTER TABLE lychee_erp.mrp_results ADD CONSTRAINT fk_mrp_results_factories
    FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.mrp_results ADD CONSTRAINT fk_mrp_results_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.mrp_results ADD CONSTRAINT fk_mrp_results_run
	FOREIGN KEY (mrp_run_id) REFERENCES lychee_erp.mrp_runs (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.mrp_results ADD CONSTRAINT fk_mrp_results_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.mrp_results.convert_status
	IS 'OPEN, PARTIAL, CONVERTED'
;

COMMENT ON COLUMN lychee_erp.mrp_results.converted_quantity
	IS '已转入下游执行单的数量（采购=PO，生产=PLO）；仅 DRAFT/PROPOSED 回退时减少'
;


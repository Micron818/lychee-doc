
DROP TABLE IF EXISTS lychee_erp.mrp_runs CASCADE
;

CREATE TABLE lychee_erp.mrp_runs (
	id bigserial NOT NULL,
	tenant_id int8 NOT NULL,
	run_code varchar(50) NOT NULL,
	run_date timestamp NOT NULL,
	description text NULL,
	created_at timestamp NULL,
	updated_at timestamp NULL,
	created_by int8 NULL,
	updated_by int8 NULL,
	error_message text NULL,
	execution_time_ms int8 NULL,
	run_status varchar(20) NOT NULL,
	factory_id int8 NULL,
	planning_horizon_days int4 NULL,
	trigger_source varchar(20) DEFAULT 'MANUAL'::character varying NOT NULL,
	triggered_by int8 NULL,
	run_mode varchar(20) DEFAULT 'OPERATIVE'::character varying NOT NULL,
	CONSTRAINT mrp_runs_pkey PRIMARY KEY (id),
	CONSTRAINT uk_mrp_runs_tenant_code UNIQUE (tenant_id, run_code)
);
CREATE INDEX idx_mrp_runs_tenant_factory ON lychee_erp.mrp_runs USING btree (tenant_id, factory_id);
CREATE INDEX ix_mrp_runs_factory_id ON lychee_erp.mrp_runs USING btree (factory_id);
CREATE INDEX ix_mrp_runs_tenant_status_factory ON lychee_erp.mrp_runs USING btree (tenant_id, run_status, factory_id);


-- lychee_erp.mrp_runs foreign keys

ALTER TABLE lychee_erp.mrp_runs ADD CONSTRAINT fk_mrp_runs_factories FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories(id);
ALTER TABLE lychee_erp.mrp_runs ADD CONSTRAINT fk_mrp_runs_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants(id);

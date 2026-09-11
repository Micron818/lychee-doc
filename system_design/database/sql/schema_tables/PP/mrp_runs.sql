 

DROP TABLE IF EXISTS lychee_erp.mrp_runs CASCADE
;

CREATE TABLE lychee_erp.mrp_runs
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	run_code varchar(50) NOT NULL,
	run_date timestamp without time zone NOT NULL,
	run_status varchar(20) NOT NULL,
	execution_time_ms bigint NULL,
	error_message text NULL,
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.mrp_runs ADD CONSTRAINT mrp_runs_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.mrp_runs ADD CONSTRAINT uk_mrp_runs_tenant_code UNIQUE (tenant_id,run_code)
;

ALTER TABLE lychee_erp.mrp_runs ADD CONSTRAINT fk_mrp_runs_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

 
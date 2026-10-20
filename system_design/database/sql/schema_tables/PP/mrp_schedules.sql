
DROP TABLE IF EXISTS lychee_erp.mrp_schedules CASCADE
;

CREATE TABLE lychee_erp.mrp_schedules
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	name varchar(100) NOT NULL,
	description text NULL,
	factory_id bigint NULL,
	cron_expression varchar(100) NOT NULL,
	time_zone varchar(64) NOT NULL   DEFAULT 'Asia/Ho_Chi_Minh',
	enabled boolean NOT NULL   DEFAULT true,
	planning_horizon_days integer NULL,
	last_triggered_at timestamp without time zone NULL,
	last_error_message text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.mrp_schedules ADD CONSTRAINT pk_mrp_schedules
	PRIMARY KEY (id)
;

CREATE INDEX ix_mrp_schedules_tenant_enabled ON lychee_erp.mrp_schedules (tenant_id ASC,enabled ASC)
;

CREATE INDEX ix_mrp_schedules_factory_id ON lychee_erp.mrp_schedules (factory_id ASC)
;

CREATE INDEX idx_mrp_schedules_tenant_factory ON lychee_erp.mrp_schedules (tenant_id ASC,factory_id ASC)
;

ALTER TABLE lychee_erp.mrp_schedules ADD CONSTRAINT fk_mrp_schedules_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.mrp_schedules ADD CONSTRAINT fk_mrp_schedules_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;


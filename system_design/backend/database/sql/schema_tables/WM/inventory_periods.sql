DROP TABLE IF EXISTS lychee_erp.inventory_periods CASCADE
;

CREATE TABLE lychee_erp.inventory_periods
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	fiscal_year int NOT NULL,
	period_no int NOT NULL,
	start_date date NOT NULL,
	end_date date NOT NULL,
	is_closed boolean NOT NULL   DEFAULT false,
	closed_at timestamp without time zone NULL,
	closed_by bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.inventory_periods ADD CONSTRAINT inventory_periods_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.inventory_periods ADD CONSTRAINT uk_inventory_periods UNIQUE (tenant_id,factory_id,fiscal_year,period_no)
;

CREATE INDEX idx_inventory_periods_year ON lychee_erp.inventory_periods (fiscal_year ASC)
;

CREATE INDEX idx_inventory_periods_tenant_factory ON lychee_erp.inventory_periods (tenant_id ASC,factory_id ASC,start_date ASC)
;

ALTER TABLE lychee_erp.inventory_periods ADD CONSTRAINT fk_inventory_periods_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.inventory_periods ADD CONSTRAINT fk_inventory_periods_factory
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.inventory_periods ADD CONSTRAINT fk_inventory_periods_closed_by
	FOREIGN KEY (closed_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.inventory_periods ADD CONSTRAINT fk_inventory_periods_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.inventory_periods ADD CONSTRAINT fk_inventory_periods_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

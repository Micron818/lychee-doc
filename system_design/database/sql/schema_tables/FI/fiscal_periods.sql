 

DROP TABLE IF EXISTS lychee_erp.fiscal_periods CASCADE
;

CREATE TABLE lychee_erp.fiscal_periods
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	fiscal_year integer NOT NULL,
	period_no integer NOT NULL,
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

ALTER TABLE lychee_erp.fiscal_periods ADD CONSTRAINT fiscal_periods_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.fiscal_periods ADD CONSTRAINT uk_fiscal_periods UNIQUE (tenant_id,company_id,fiscal_year,period_no)
;

CREATE INDEX idx_fiscal_periods_year ON lychee_erp.fiscal_periods (tenant_id,company_id,fiscal_year)
;

ALTER TABLE lychee_erp.fiscal_periods ADD CONSTRAINT fk_fiscal_periods_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.fiscal_periods ADD CONSTRAINT fk_fiscal_periods_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.fiscal_periods ADD CONSTRAINT fk_fiscal_periods_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.fiscal_periods ADD CONSTRAINT fk_fiscal_periods_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
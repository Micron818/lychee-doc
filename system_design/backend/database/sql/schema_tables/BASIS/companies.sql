 

DROP TABLE IF EXISTS lychee_erp.companies CASCADE
;

CREATE TABLE lychee_erp.companies
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	tax_id varchar(50) NULL,
	address text NULL,
	phone varchar(20) NULL,
	email varchar(100) NULL,
	parent_id bigint NULL,
	level integer NULL   DEFAULT 1,
	manager varchar(100) NULL,
	description text NULL,
	status_option_id bigint NULL,
	local_currency_id bigint NOT NULL,
	default_payment_term_id bigint NULL,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.companies ADD CONSTRAINT companies_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.companies ADD CONSTRAINT uk_company_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_companies_status_option ON lychee_erp.companies (status_option_id ASC)
;

CREATE INDEX idx_companies_local_currency ON lychee_erp.companies (local_currency_id ASC)
;

CREATE INDEX idx_companies_parent ON lychee_erp.companies (parent_id ASC)
;

ALTER TABLE lychee_erp.companies ADD CONSTRAINT fk_companies_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.companies ADD CONSTRAINT fk_companies_parent
	FOREIGN KEY (parent_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.companies ADD CONSTRAINT fk_companies_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.companies ADD CONSTRAINT fk_companies_local_currency
	FOREIGN KEY (local_currency_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.companies ADD CONSTRAINT fk_companies_default_payment_term
	FOREIGN KEY (default_payment_term_id) REFERENCES lychee_erp.fi_payment_terms (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.companies ADD CONSTRAINT fk_companies_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.companies ADD CONSTRAINT fk_companies_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
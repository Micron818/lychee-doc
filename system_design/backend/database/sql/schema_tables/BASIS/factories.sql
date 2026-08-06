 

DROP TABLE IF EXISTS lychee_erp.factories CASCADE
;

CREATE TABLE lychee_erp.factories
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	created_at timestamp without time zone NULL,
	status_option_id bigint NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.factories ADD CONSTRAINT factories_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.factories ADD CONSTRAINT uk_factory_tenant_company_code UNIQUE (tenant_id,company_id,code)
;

CREATE INDEX idx_factories_company ON lychee_erp.factories (company_id ASC)
;

CREATE INDEX idx_factories_status_option ON lychee_erp.factories (status_option_id ASC)
;

ALTER TABLE lychee_erp.factories ADD CONSTRAINT fk_factories_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.factories ADD CONSTRAINT fk_factories_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.factories ADD CONSTRAINT fk_factories_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.factories ADD CONSTRAINT fk_factories_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.factories ADD CONSTRAINT fk_factories_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
 

DROP TABLE IF EXISTS lychee_erp.departments CASCADE
;

CREATE TABLE lychee_erp.departments
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	parent_id bigint NULL,
	manager_id bigint NULL,
	description text NULL,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.departments ADD CONSTRAINT departments_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.departments ADD CONSTRAINT uk_departments_tenant_code UNIQUE (tenant_id,company_id,code)
;

CREATE INDEX idx_departments_status_option ON lychee_erp.departments (status_option_id ASC)
;

CREATE INDEX idx_departments_company ON lychee_erp.departments (company_id ASC)
;

CREATE INDEX idx_departments_parent ON lychee_erp.departments (parent_id ASC)
;

ALTER TABLE lychee_erp.departments ADD CONSTRAINT fk_departments_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.departments ADD CONSTRAINT fk_departments_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.departments ADD CONSTRAINT fk_departments_parent
	FOREIGN KEY (parent_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.departments ADD CONSTRAINT fk_departments_manager
	FOREIGN KEY (manager_id) REFERENCES lychee_erp.users (id) ON DELETE Set Null ON UPDATE No Action
;

ALTER TABLE lychee_erp.departments ADD CONSTRAINT fk_departments_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.departments ADD CONSTRAINT fk_departments_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.departments ADD CONSTRAINT fk_departments_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
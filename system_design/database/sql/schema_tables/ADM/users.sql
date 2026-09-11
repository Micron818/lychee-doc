 

DROP TABLE IF EXISTS lychee_erp.users CASCADE
;

CREATE TABLE lychee_erp.users
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	idp_user_id varchar(255) NOT NULL,
	username varchar(50) NOT NULL,
	email varchar(100) NULL,
	full_name varchar(100) NOT NULL,
	phone varchar(20) NULL,
	company_id bigint NULL,
	factory_id bigint NULL,
	department_id bigint NULL,
	position varchar(100) NULL,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.users ADD CONSTRAINT users_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.users ADD CONSTRAINT idx_users_idp_user_id_tenant_id UNIQUE (tenant_id,idp_user_id)
;

CREATE INDEX IXFK_users_departments ON lychee_erp.users (department_id ASC)
;

CREATE INDEX IXFK_users_factories ON lychee_erp.users (factory_id ASC)
;

CREATE INDEX idx_users_company ON lychee_erp.users (company_id ASC)
;

CREATE INDEX idx_users_status_option ON lychee_erp.users (status_option_id ASC)
;

CREATE INDEX idx_users_tenant ON lychee_erp.users (tenant_id ASC)
;

CREATE INDEX uk_user_tenant_username ON lychee_erp.users (tenant_id ASC,username ASC)
;

ALTER TABLE lychee_erp.users ADD CONSTRAINT fk_users_departments
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.users ADD CONSTRAINT fk_users_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.users ADD CONSTRAINT fk_users_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.users ADD CONSTRAINT fk_users_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.users ADD CONSTRAINT fk_users_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.users ADD CONSTRAINT fk_users_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.users ADD CONSTRAINT fk_users_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action
;

 
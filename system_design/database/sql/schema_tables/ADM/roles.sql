 

DROP TABLE IF EXISTS lychee_erp.roles CASCADE
;

CREATE TABLE lychee_erp.roles
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	name varchar(100) NULL,
	code varchar(50) NOT NULL,
	description text NULL,
	level integer NULL   DEFAULT 1,
	is_system boolean NULL   DEFAULT false,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.roles ADD CONSTRAINT roles_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.roles ADD CONSTRAINT uk_role_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_roles_status_option ON lychee_erp.roles (status_option_id ASC)
;

ALTER TABLE lychee_erp.roles ADD CONSTRAINT fk_roles_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.roles ADD CONSTRAINT fk_roles_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.roles ADD CONSTRAINT fk_roles_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.roles ADD CONSTRAINT fk_roles_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
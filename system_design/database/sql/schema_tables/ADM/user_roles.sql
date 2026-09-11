 

DROP TABLE IF EXISTS lychee_erp.user_roles CASCADE
;

CREATE TABLE lychee_erp.user_roles
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	user_id bigint NOT NULL,
	role_id bigint NOT NULL,
	assigned_by bigint NULL,
	assigned_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	expires_at timestamp without time zone NULL,
	is_active boolean NULL   DEFAULT true,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.user_roles ADD CONSTRAINT user_roles_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.user_roles ADD CONSTRAINT uk_user_role_tenant UNIQUE (tenant_id,user_id,role_id)
;

CREATE INDEX idx_user_roles_role ON lychee_erp.user_roles (role_id ASC)
;

CREATE INDEX idx_user_roles_tenant ON lychee_erp.user_roles (tenant_id ASC)
;

CREATE INDEX idx_user_roles_user ON lychee_erp.user_roles (user_id ASC)
;

CREATE INDEX idx_user_roles_assigned_by ON lychee_erp.user_roles (assigned_by ASC)
;

ALTER TABLE lychee_erp.user_roles ADD CONSTRAINT fk_user_roles_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.user_roles ADD CONSTRAINT fk_user_roles_user
	FOREIGN KEY (user_id) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.user_roles ADD CONSTRAINT fk_user_roles_role
	FOREIGN KEY (role_id) REFERENCES lychee_erp.roles (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.user_roles ADD CONSTRAINT fk_user_roles_assigned_by
	FOREIGN KEY (assigned_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.user_roles ADD CONSTRAINT fk_user_roles_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.user_roles ADD CONSTRAINT fk_user_roles_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
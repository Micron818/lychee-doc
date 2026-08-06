 

DROP TABLE IF EXISTS lychee_erp.role_permissions CASCADE
;

CREATE TABLE lychee_erp.role_permissions
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	role_id bigint NOT NULL,
	permission_id bigint NOT NULL,
	granted_by bigint NULL,
	granted_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.role_permissions ADD CONSTRAINT role_permissions_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.role_permissions ADD CONSTRAINT uk_role_permission_tenant UNIQUE (tenant_id,role_id,permission_id)
;

CREATE INDEX idx_role_permissions_granted_by ON lychee_erp.role_permissions (granted_by ASC)
;

CREATE INDEX idx_role_permissions_permission ON lychee_erp.role_permissions (permission_id ASC)
;

CREATE INDEX idx_role_permissions_role ON lychee_erp.role_permissions (role_id ASC)
;

ALTER TABLE lychee_erp.role_permissions ADD CONSTRAINT fk_role_permissions_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permissions ADD CONSTRAINT fk_role_permissions_role
	FOREIGN KEY (role_id) REFERENCES lychee_erp.roles (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permissions ADD CONSTRAINT fk_role_permissions_permission
	FOREIGN KEY (permission_id) REFERENCES lychee_erp.permissions (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permissions ADD CONSTRAINT fk_role_permissions_granted_by
	FOREIGN KEY (granted_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permissions ADD CONSTRAINT fk_role_permissions_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permissions ADD CONSTRAINT fk_role_permissions_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
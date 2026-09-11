 

DROP TABLE IF EXISTS lychee_erp.data_permissions CASCADE
;

CREATE TABLE lychee_erp.data_permissions
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	role_permission_id bigint NOT NULL,
	scope_option_id bigint NULL,
	conditions jsonb NULL,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.data_permissions ADD CONSTRAINT data_permissions_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.data_permissions ADD CONSTRAINT uk_data_permission_role_permission UNIQUE (tenant_id,role_permission_id)
;

CREATE INDEX idx_data_permissions_scope_option ON lychee_erp.data_permissions (scope_option_id ASC)
;

CREATE INDEX idx_data_permissions_role_permission ON lychee_erp.data_permissions (role_permission_id ASC)
;

ALTER TABLE lychee_erp.data_permissions ADD CONSTRAINT fk_data_permissions_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.data_permissions ADD CONSTRAINT fk_data_permissions_role_permission
	FOREIGN KEY (role_permission_id) REFERENCES lychee_erp.role_permissions (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.data_permissions ADD CONSTRAINT fk_data_permissions_scope_option
	FOREIGN KEY (scope_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.data_permissions ADD CONSTRAINT fk_data_permissions_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.data_permissions ADD CONSTRAINT fk_data_permissions_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
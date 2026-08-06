 

DROP TABLE IF EXISTS lychee_erp.permissions CASCADE
;

CREATE TABLE lychee_erp.permissions
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	menu_id bigint NOT NULL,
	action_option_id bigint NOT NULL,
	is_system boolean NULL   DEFAULT false,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.permissions ADD CONSTRAINT permissions_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.permissions ADD CONSTRAINT uk_permission_menu_action UNIQUE (tenant_id,menu_id,action_option_id)
;

CREATE INDEX idx_permissions_status_option ON lychee_erp.permissions (status_option_id ASC)
;

CREATE INDEX idx_permissions_menu ON lychee_erp.permissions (menu_id ASC)
;

CREATE INDEX idx_permissions_action_option ON lychee_erp.permissions (action_option_id ASC)
;

ALTER TABLE lychee_erp.permissions ADD CONSTRAINT fk_permissions_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.permissions ADD CONSTRAINT fk_permissions_menu
	FOREIGN KEY (menu_id) REFERENCES lychee_erp.menus (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.permissions ADD CONSTRAINT fk_permissions_action_option
	FOREIGN KEY (action_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.permissions ADD CONSTRAINT fk_permissions_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.permissions ADD CONSTRAINT fk_permissions_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.permissions ADD CONSTRAINT fk_permissions_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
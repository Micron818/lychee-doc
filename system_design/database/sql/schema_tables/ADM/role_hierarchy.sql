 

DROP TABLE IF EXISTS lychee_erp.role_hierarchy CASCADE
;

CREATE TABLE lychee_erp.role_hierarchy
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	parent_role_id bigint NOT NULL,
	child_role_id bigint NOT NULL,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.role_hierarchy ADD CONSTRAINT role_hierarchy_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.role_hierarchy ADD CONSTRAINT uk_role_hierarchy_tenant UNIQUE (tenant_id,parent_role_id,child_role_id)
;

CREATE INDEX idx_role_hierarchy_child ON lychee_erp.role_hierarchy (child_role_id ASC)
;

CREATE INDEX idx_role_hierarchy_parent ON lychee_erp.role_hierarchy (parent_role_id ASC)
;

ALTER TABLE lychee_erp.role_hierarchy ADD CONSTRAINT fk_role_hierarchy_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_hierarchy ADD CONSTRAINT fk_role_hierarchy_parent
	FOREIGN KEY (parent_role_id) REFERENCES lychee_erp.roles (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_hierarchy ADD CONSTRAINT fk_role_hierarchy_child
	FOREIGN KEY (child_role_id) REFERENCES lychee_erp.roles (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_hierarchy ADD CONSTRAINT fk_role_hierarchy_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_hierarchy ADD CONSTRAINT fk_role_hierarchy_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
 

DROP TABLE IF EXISTS lychee_erp.material_categories CASCADE
;

CREATE TABLE lychee_erp.material_categories
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	parent_id bigint NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NULL,
	level integer NOT NULL,
	description text NULL,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.material_categories ADD CONSTRAINT material_categories_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.material_categories ADD CONSTRAINT uk_material_categories_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_material_categories_status_option ON lychee_erp.material_categories (status_option_id ASC)
;

CREATE INDEX idx_material_categories_parent ON lychee_erp.material_categories (parent_id ASC)
;

ALTER TABLE lychee_erp.material_categories ADD CONSTRAINT fk_material_categories_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_categories ADD CONSTRAINT fk_material_categories_parent
	FOREIGN KEY (parent_id) REFERENCES lychee_erp.material_categories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_categories ADD CONSTRAINT fk_material_categories_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_categories ADD CONSTRAINT fk_material_categories_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_categories ADD CONSTRAINT fk_material_categories_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
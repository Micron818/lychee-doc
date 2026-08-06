 

DROP TABLE IF EXISTS lychee_erp.menus CASCADE
;

CREATE TABLE lychee_erp.menus
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	name varchar(100) NULL,
	parent_id bigint NULL,
	path varchar(500) NOT NULL,
	icon varchar(100) NULL,
	sort_order integer NULL   DEFAULT 0,
	is_visible boolean NULL   DEFAULT true,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL,
	locale varchar(200) NULL,
	access_key varchar(10) NULL
)
;

ALTER TABLE lychee_erp.menus ADD CONSTRAINT menus_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.menus ADD CONSTRAINT uk_menu_tenant_code UNIQUE (tenant_id,path)
;

CREATE INDEX idx_menus_parent ON lychee_erp.menus (parent_id ASC)
;

CREATE INDEX idx_menus_status_option ON lychee_erp.menus (status_option_id ASC)
;

ALTER TABLE lychee_erp.menus ADD CONSTRAINT fk_menus_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.menus ADD CONSTRAINT fk_menus_parent
	FOREIGN KEY (parent_id) REFERENCES lychee_erp.menus (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.menus ADD CONSTRAINT fk_menus_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.menus ADD CONSTRAINT fk_menus_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.menus ADD CONSTRAINT fk_menus_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
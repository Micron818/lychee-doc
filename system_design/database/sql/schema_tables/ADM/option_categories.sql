 

DROP TABLE IF EXISTS lychee_erp.option_categories CASCADE
;

CREATE TABLE lychee_erp.option_categories
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	name varchar(50) NOT NULL,
	code varchar(50) NOT NULL,
	description text NULL,
	is_system boolean NULL   DEFAULT false,
	is_active boolean NULL   DEFAULT true,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL,
	default_value_id bigint NULL
)
;

ALTER TABLE lychee_erp.option_categories ADD CONSTRAINT option_categories_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.option_categories ADD CONSTRAINT uk_option_category_tenant_code UNIQUE (tenant_id,code)
;

ALTER TABLE lychee_erp.option_categories ADD CONSTRAINT fk_option_categories_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.option_categories ADD CONSTRAINT fk_option_categories_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.option_categories ADD CONSTRAINT fk_option_categories_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
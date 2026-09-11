 

DROP TABLE IF EXISTS lychee_erp.option_values CASCADE
;

CREATE TABLE lychee_erp.option_values
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	category_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NULL,
	sort_order integer NULL   DEFAULT 0,
	is_system boolean NULL   DEFAULT false,
	is_active boolean NULL   DEFAULT true,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.option_values ADD CONSTRAINT option_values_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.option_values ADD CONSTRAINT uk_option_value_tenant_category_code UNIQUE (tenant_id,category_id,code)
;

CREATE INDEX idx_option_values_category ON lychee_erp.option_values (category_id ASC)
;

ALTER TABLE lychee_erp.option_values ADD CONSTRAINT fk_option_values_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.option_values ADD CONSTRAINT fk_option_values_category
	FOREIGN KEY (category_id) REFERENCES lychee_erp.option_categories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.option_values ADD CONSTRAINT fk_option_values_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.option_values ADD CONSTRAINT fk_option_values_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
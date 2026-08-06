 

DROP TABLE IF EXISTS lychee_erp.customers CASCADE
;

CREATE TABLE lychee_erp.customers
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	short_name varchar(50) NULL,
	tax_id varchar(50) NULL,
	email varchar(100) NULL,
	phone varchar(50) NULL,
	fax varchar(50) NULL,
	website varchar(200) NULL,
	address_billing text NULL,
	address_shipping text NULL,
	contact_person varchar(100) NULL,
	contact_phone varchar(50) NULL,
	contact_email varchar(100) NULL,
	currency_option_id bigint NULL,
	customer_type_option_id bigint NULL,
	sales_person_id bigint NULL,
	status_option_id bigint NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.customers ADD CONSTRAINT customers_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.customers ADD CONSTRAINT uk_customers_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_customers_sales_person ON lychee_erp.customers (sales_person_id ASC)
;

CREATE INDEX idx_customers_status_option ON lychee_erp.customers (status_option_id ASC)
;

CREATE INDEX idx_customers_type_option ON lychee_erp.customers (customer_type_option_id ASC)
;

ALTER TABLE lychee_erp.customers ADD CONSTRAINT fk_customers_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customers ADD CONSTRAINT fk_customers_currency_option
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customers ADD CONSTRAINT fk_customers_type_option
	FOREIGN KEY (customer_type_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customers ADD CONSTRAINT fk_customers_sales_person
	FOREIGN KEY (sales_person_id) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customers ADD CONSTRAINT fk_customers_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customers ADD CONSTRAINT fk_customers_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customers ADD CONSTRAINT fk_customers_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
 

DROP TABLE IF EXISTS lychee_erp.suppliers CASCADE
;

CREATE TABLE lychee_erp.suppliers
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	tax_id varchar(50) NULL,
	address_en text NULL,
	supplier_type varchar(20) NOT NULL,
	active_status varchar(20) NOT NULL,
	address_local text NULL,
	phone varchar(20) NULL,
	email varchar(100) NULL,
	contact_person varchar(100) NULL,
	contact_phone varchar(20) NULL,
	contact_email varchar(100) NULL,
	currency_option_id bigint NULL,
	tax_class_id bigint NULL,
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.suppliers ADD CONSTRAINT suppliers_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.suppliers ADD CONSTRAINT uk_supplier_tenant_code UNIQUE (tenant_id,code)
;

ALTER TABLE lychee_erp.suppliers ADD CONSTRAINT fk_suppliers_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.suppliers ADD CONSTRAINT fk_suppliers_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.suppliers ADD CONSTRAINT fk_suppliers_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.suppliers ADD CONSTRAINT fk_suppliers_tax_class
	FOREIGN KEY (tax_class_id) REFERENCES lychee_erp.tax_classes (id) ON DELETE No Action ON UPDATE No Action
;

 
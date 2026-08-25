

DROP TABLE IF EXISTS lychee_erp.material_suppliers CASCADE
;

CREATE TABLE lychee_erp.material_suppliers
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	material_id bigint NOT NULL,
	supplier_id bigint NOT NULL,
	is_default boolean NOT NULL DEFAULT false,
	purchase_unit_id bigint NULL,
	min_order_quantity numeric(18,6) NOT NULL DEFAULT 0,
	lead_time_days numeric(10,2) NOT NULL DEFAULT 0,
	last_price numeric(18,4) NULL,
	currency_option_id bigint NULL,
	valid_from date NULL,
	valid_to date NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT pk_material_suppliers
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT uk_material_suppliers
	UNIQUE (tenant_id, factory_id, material_id, supplier_id)
;

CREATE UNIQUE INDEX uk_material_suppliers_one_default
	ON lychee_erp.material_suppliers (tenant_id, factory_id, material_id)
	WHERE is_default = true
;

CREATE INDEX ix_material_suppliers_material ON lychee_erp.material_suppliers (material_id ASC)
;

CREATE INDEX ix_material_suppliers_supplier ON lychee_erp.material_suppliers (supplier_id ASC)
;

CREATE INDEX ix_material_suppliers_factory ON lychee_erp.material_suppliers (factory_id ASC)
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT fk_material_suppliers_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT fk_material_suppliers_factory
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT fk_material_suppliers_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT fk_material_suppliers_supplier
	FOREIGN KEY (supplier_id) REFERENCES lychee_erp.suppliers (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT fk_material_suppliers_purchase_unit
	FOREIGN KEY (purchase_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT fk_material_suppliers_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT fk_material_suppliers_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_suppliers ADD CONSTRAINT fk_material_suppliers_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

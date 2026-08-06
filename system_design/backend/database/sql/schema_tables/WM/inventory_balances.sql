 

DROP TABLE IF EXISTS lychee_erp.inventory_balances CASCADE
;

CREATE TABLE lychee_erp.inventory_balances
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	inventory_period_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	material_id bigint NOT NULL,
	warehouse_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL   DEFAULT '',
	base_unit_id bigint NOT NULL,
	opening_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	total_in_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	total_out_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	closing_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	opening_amount numeric(18,2) NOT NULL   DEFAULT 0,
	total_in_amount numeric(18,2) NOT NULL   DEFAULT 0,
	total_out_amount numeric(18,2) NOT NULL   DEFAULT 0,
	closing_amount numeric(18,2) NOT NULL   DEFAULT 0,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.inventory_balances ADD CONSTRAINT inventory_balances_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.inventory_balances ADD CONSTRAINT uk_inventory_balances UNIQUE (tenant_id,inventory_period_id,factory_id,material_id,warehouse_id,batch_no)
;

CREATE INDEX idx_inventory_balances_material ON lychee_erp.inventory_balances (material_id ASC)
;

CREATE INDEX idx_inventory_balances_period_factory ON lychee_erp.inventory_balances (tenant_id ASC,inventory_period_id ASC,factory_id ASC)
;

CREATE INDEX idx_inventory_balances_warehouse ON lychee_erp.inventory_balances (tenant_id ASC,inventory_period_id ASC,warehouse_id ASC)
;

ALTER TABLE lychee_erp.inventory_balances ADD CONSTRAINT fk_inventory_balances_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.inventory_balances ADD CONSTRAINT fk_inventory_balances_inventory_period
	FOREIGN KEY (inventory_period_id) REFERENCES lychee_erp.inventory_periods (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.inventory_balances ADD CONSTRAINT fk_inventory_balances_factory
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.inventory_balances ADD CONSTRAINT fk_inventory_balances_warehouse
	FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.inventory_balances ADD CONSTRAINT fk_inventory_balances_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.inventory_balances ADD CONSTRAINT fk_inventory_balances_base_unit
	FOREIGN KEY (base_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

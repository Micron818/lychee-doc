 

 

DROP TABLE IF EXISTS lychee_erp.physical_inventories CASCADE
;

CREATE TABLE lychee_erp.physical_inventories
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	inventory_no varchar(50) NOT NULL,
	inventory_period_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	plan_date date NOT NULL,
	warehouse_id bigint NOT NULL,
	inventory_type varchar(20) NOT NULL,    -- FULL, CYCLE
	status varchar(20) NOT NULL,    -- PLANNED,COUNTED,POSTED,REVERSED
	block_transactions boolean NOT NULL   DEFAULT false,
	remarks text NULL,
	counted_by bigint NULL,
	snapshot_at timestamp without time zone NULL,
	cycle_count_criteria jsonb NULL,
	approved_by bigint NULL,
	approved_at timestamp without time zone NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.physical_inventories ADD CONSTRAINT pk_physical_inventories
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.physical_inventories ADD CONSTRAINT uk_physical_inventories UNIQUE (tenant_id,inventory_no)
;

CREATE INDEX IXFK_physical_inventories_factories ON lychee_erp.physical_inventories (factory_id ASC)
;

CREATE INDEX IXFK_physical_inventories_inventory_periods ON lychee_erp.physical_inventories (inventory_period_id ASC)
;

CREATE INDEX IXFK_physical_inventories_warehouses ON lychee_erp.physical_inventories (warehouse_id ASC)
;

CREATE INDEX idx_physical_inventories_date ON lychee_erp.physical_inventories (tenant_id ASC,plan_date ASC)
;

CREATE INDEX idx_physical_inventories_period ON lychee_erp.physical_inventories (tenant_id ASC,inventory_period_id ASC)
;

ALTER TABLE lychee_erp.physical_inventories ADD CONSTRAINT fk_physical_inventories_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.physical_inventories ADD CONSTRAINT fk_physical_inventories_inventory_periods
	FOREIGN KEY (inventory_period_id) REFERENCES lychee_erp.inventory_periods (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.physical_inventories ADD CONSTRAINT fk_physical_inventories_warehouses
	FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.physical_inventories.inventory_type
	IS 'FULL, CYCLE'
;

COMMENT ON COLUMN lychee_erp.physical_inventories.status
	IS 'PLANNED,COUNTED,POSTED,REVERSED'
;

 

 
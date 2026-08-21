 

DROP TABLE IF EXISTS lychee_erp.physical_inventory_items CASCADE
;

CREATE TABLE lychee_erp.physical_inventory_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	physical_inventory_id bigint NOT NULL,
	item_no integer NOT NULL,
	material_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL   DEFAULT '',
	base_unit_id bigint NOT NULL,
	book_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	counted_quantity numeric(18,6) NULL,
	difference_quantity numeric(18,6) NULL,
	dynamic_transaction_quantity numeric(18,6) NULL,
	posted_difference_quantity numeric(18,6) NULL,
	reason_code varchar(50) NULL,
	remarks text NULL,
	stock_type varchar(20) NOT NULL,    -- UNRESTRICTED, INSPECTION, BLOCKED
	location_code varchar(50) NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.physical_inventory_items ADD CONSTRAINT pk_physical_inventory_items
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.physical_inventory_items ADD CONSTRAINT uk_physical_inventory_items_item_no UNIQUE (tenant_id,physical_inventory_id,item_no)
;


ALTER TABLE lychee_erp.physical_inventory_items ADD CONSTRAINT uk_physical_inventory_items UNIQUE (tenant_id,physical_inventory_id,material_id,batch_no,stock_type)
;

CREATE INDEX IXFK_physical_inventory_items_materials ON lychee_erp.physical_inventory_items (material_id ASC)
;

CREATE INDEX IXFK_physical_inventory_items_physical_inventories ON lychee_erp.physical_inventory_items (physical_inventory_id ASC)
;

ALTER TABLE lychee_erp.physical_inventory_items ADD CONSTRAINT fk_physical_inventory_items_materials
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.physical_inventory_items ADD CONSTRAINT fk_physical_inventory_items_physical_inventories
	FOREIGN KEY (physical_inventory_id) REFERENCES lychee_erp.physical_inventories (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.physical_inventory_items.stock_type
	IS 'UNRESTRICTED, INSPECTION, BLOCKED'
;

 

 

DROP TABLE IF EXISTS lychee_erp.stock_transfer_items CASCADE
;

CREATE TABLE lychee_erp.stock_transfer_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	stock_transfer_id bigint NOT NULL,
	item_no integer NOT NULL,
	material_id bigint NOT NULL,
	from_warehouse_id bigint NOT NULL,
	to_warehouse_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL   DEFAULT '',
	transaction_unit_id bigint NOT NULL,
	transaction_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	base_unit_id bigint NOT NULL,
	base_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	source_doc_type varchar(50) NOT NULL,    -- OUTSOURCE_ORDER, OTHER
	source_doc_id bigint NULL,
	source_doc_no varchar(50) NULL,
	source_doc_item_id bigint NULL,
	source_doc_item_no integer NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.stock_transfer_items ADD CONSTRAINT stock_transfer_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.stock_transfer_items ADD CONSTRAINT uk_stock_transfer_items_item_no UNIQUE (tenant_id,stock_transfer_id,item_no)
;


ALTER TABLE lychee_erp.stock_transfer_items ADD CONSTRAINT uk_stock_transfer_items UNIQUE (tenant_id,stock_transfer_id,material_id,from_warehouse_id,to_warehouse_id,batch_no,source_doc_type,source_doc_item_id,transaction_unit_id)
;

CREATE INDEX idx_st_items_transfer ON lychee_erp.stock_transfer_items (stock_transfer_id ASC)
;

CREATE INDEX idx_st_items_material ON lychee_erp.stock_transfer_items (material_id ASC)
;

CREATE INDEX ixfk_stock_transfer_items_material_units ON lychee_erp.stock_transfer_items (base_unit_id ASC)
;

ALTER TABLE lychee_erp.stock_transfer_items ADD CONSTRAINT fk_st_items_from_warehouse
	FOREIGN KEY (from_warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_transfer_items ADD CONSTRAINT fk_st_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_transfer_items ADD CONSTRAINT fk_st_items_to_warehouse
	FOREIGN KEY (to_warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_transfer_items ADD CONSTRAINT fk_st_items_transfer
	FOREIGN KEY (stock_transfer_id) REFERENCES lychee_erp.stock_transfers (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_transfer_items ADD CONSTRAINT fk_stock_transfer_items_material_units
	FOREIGN KEY (base_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.stock_transfer_items.source_doc_type
	IS 'OUTSOURCE_ORDER, OTHER'
;

 

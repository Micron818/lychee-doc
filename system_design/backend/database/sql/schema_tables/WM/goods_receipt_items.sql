 

DROP TABLE IF EXISTS lychee_erp.goods_receipt_items CASCADE
;

CREATE TABLE lychee_erp.goods_receipt_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	goods_receipt_id bigint NOT NULL,
	item_no integer NOT NULL,
	source_doc_type varchar(20) NOT NULL,    -- PURCHASE_ORDER_ITEM,CUSTOMER_RETURN_ITEM,PURCHASE_RETURN_ITEM,PRODUCTION_REPORT,MISC_RECEIPT,OUTSOURCE_ORDER_ITEM
	source_doc_id bigint NOT NULL,
	source_doc_no varchar(50) NULL,
	source_doc_item_id bigint NULL,
	source_doc_item_no integer NULL,
	material_id bigint NOT NULL,
	warehouse_id bigint NULL,              -- required for inventoried materials; NULL for non-inventoried (e.g. VC-ASSET)
	batch_no varchar(50) NOT NULL   DEFAULT '',
	is_foc boolean NOT NULL   DEFAULT false,
	unit_price numeric(18,4) NOT NULL DEFAULT 0,
	tax_rate numeric(5,2) NULL DEFAULT 0,
	transaction_unit_id bigint NOT NULL,
	transaction_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	base_unit_id bigint NOT NULL,
	base_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	invoiced_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	invoice_status varchar(20) NOT NULL DEFAULT 'UNINVOICED',    -- UNINVOICED, PARTIALLY_INVOICED, FULLY_INVOICED
	expiry_date date NULL,
	remarks text NULL,
	stock_type varchar(20) NULL,    -- UNRESTRICTED, INSPECTION, BLOCKED
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.goods_receipt_items ADD CONSTRAINT goods_receipt_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.goods_receipt_items ADD CONSTRAINT uk_goods_receipt_items_item_no UNIQUE (tenant_id,goods_receipt_id,item_no)
;


CREATE INDEX IXFK_goods_receipt_items_warehouses ON lychee_erp.goods_receipt_items (warehouse_id ASC)
;

CREATE INDEX idx_gr_items_receipt ON lychee_erp.goods_receipt_items (goods_receipt_id ASC)
;

CREATE INDEX idx_gr_items_material ON lychee_erp.goods_receipt_items (material_id ASC)
;

CREATE INDEX idx_gr_items_po_item ON lychee_erp.goods_receipt_items (tenant_id ASC,source_doc_id ASC)
;

ALTER TABLE lychee_erp.goods_receipt_items ADD CONSTRAINT fk_goods_receipt_items_warehouses
	FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.goods_receipt_items ADD CONSTRAINT fk_gr_items_receipt
	FOREIGN KEY (goods_receipt_id) REFERENCES lychee_erp.goods_receipts (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.goods_receipt_items ADD CONSTRAINT fk_gr_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.goods_receipt_items.source_doc_type
	IS 'PURCHASE_ORDER_ITEM,CUSTOMER_RETURN_ITEM,PURCHASE_RETURN_ITEM,PRODUCTION_REPORT,MISC_RECEIPT,OUTSOURCE_ORDER_ITEM'
;

COMMENT ON COLUMN lychee_erp.goods_receipt_items.warehouse_id
	IS 'Receiving warehouse; required for inventoried materials, NULL for non-inventoried (e.g. VC-ASSET)'
;

COMMENT ON COLUMN lychee_erp.goods_receipt_items.stock_type
	IS 'UNRESTRICTED, INSPECTION, BLOCKED'
;

COMMENT ON COLUMN lychee_erp.goods_receipt_items.unit_price
	IS 'Source unit price snapshot (document currency)'
;

COMMENT ON COLUMN lychee_erp.goods_receipt_items.tax_rate
	IS 'Source tax rate snapshot'
;

COMMENT ON COLUMN lychee_erp.goods_receipt_items.invoiced_quantity
	IS 'Quantity already invoiced in transaction unit'
;

COMMENT ON COLUMN lychee_erp.goods_receipt_items.invoice_status
	IS 'UNINVOICED, PARTIALLY_INVOICED, FULLY_INVOICED'
;

 

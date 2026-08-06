 

DROP TABLE IF EXISTS lychee_erp.stock_transactions CASCADE
;

CREATE TABLE lychee_erp.stock_transactions
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	material_id bigint NOT NULL,
	warehouse_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL   DEFAULT '',
	transaction_date timestamp without time zone NOT NULL,
	transaction_type varchar(30) NOT NULL,    -- GOODS_RECEIPT,VENDOR_RETURN,DELIVERY,CUSTOMER_RETURN,STOCK_ISSUE,STOCK_RETURN,ADJUSTMENT,STOCK_TRANSFER,BACKFLUSH
	base_unit_id bigint NOT NULL,
	before_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	in_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	out_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	after_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	unit_cost numeric(18,6) NOT NULL   DEFAULT 0,
	total_amount numeric(18,2) NOT NULL   DEFAULT 0,
	source_doc_type varchar(50) NOT NULL,
	source_doc_id bigint NOT NULL,
	source_doc_no varchar(50) NOT NULL,
	source_doc_item_id bigint NULL,
	source_doc_item_no integer NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_at timestamp without time zone NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.stock_transactions ADD CONSTRAINT stock_transactions_pkey
	PRIMARY KEY (id)
;

CREATE INDEX idx_stock_transactions_date ON lychee_erp.stock_transactions (transaction_date ASC)
;

CREATE INDEX idx_stock_transactions_material ON lychee_erp.stock_transactions (material_id ASC)
;

CREATE INDEX idx_stock_transactions_warehouse ON lychee_erp.stock_transactions (warehouse_id ASC)
;

CREATE INDEX idx_stock_transactions_source ON lychee_erp.stock_transactions (tenant_id ASC,source_doc_type ASC,source_doc_id ASC)
;

CREATE INDEX idx_stock_transactions_source_item ON lychee_erp.stock_transactions (tenant_id ASC,source_doc_type ASC,source_doc_item_id ASC)
;

ALTER TABLE lychee_erp.stock_transactions ADD CONSTRAINT fk_stock_transactions_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_transactions ADD CONSTRAINT fk_stock_transactions_warehouse
	FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_transactions ADD CONSTRAINT fk_stock_transactions_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.stock_transactions.transaction_type
	IS 'GOODS_RECEIPT,VENDOR_RETURN,DELIVERY,CUSTOMER_RETURN,STOCK_ISSUE,STOCK_RETURN,ADJUSTMENT,STOCK_TRANSFER,BACKFLUSH'
;

 

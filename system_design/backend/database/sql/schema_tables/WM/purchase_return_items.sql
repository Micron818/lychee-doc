
DROP TABLE IF EXISTS lychee_erp.purchase_return_items CASCADE
;

CREATE TABLE lychee_erp.purchase_return_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	purchase_return_id bigint NOT NULL,
	item_no integer NOT NULL,
	original_receipt_item_id bigint NOT NULL,
	material_id bigint NOT NULL,
	warehouse_id bigint NULL,
	batch_no varchar(50) NOT NULL DEFAULT '',
	is_foc boolean NOT NULL DEFAULT false,
	unit_price numeric(18,4) NOT NULL DEFAULT 0,
	tax_code_id bigint NULL,
	tax_rate numeric(5,2) NULL DEFAULT 0,
	transaction_unit_id bigint NOT NULL,
	transaction_quantity numeric(18,6) NOT NULL DEFAULT 0,
	base_unit_id bigint NOT NULL,
	base_quantity numeric(18,6) NOT NULL DEFAULT 0,
	stock_type varchar(20) NOT NULL DEFAULT 'UNRESTRICTED',
	reason_code varchar(50) NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.purchase_return_items ADD CONSTRAINT pk_purchase_return_items
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.purchase_return_items ADD CONSTRAINT uk_purchase_return_items_item_no
	UNIQUE (tenant_id, purchase_return_id, item_no)
;

ALTER TABLE lychee_erp.purchase_return_items ADD CONSTRAINT uk_purchase_return_items_original
	UNIQUE (tenant_id, purchase_return_id, original_receipt_item_id)
;

CREATE INDEX ix_purchase_return_items_header ON lychee_erp.purchase_return_items (purchase_return_id ASC)
;

CREATE INDEX ix_purchase_return_items_original ON lychee_erp.purchase_return_items (original_receipt_item_id ASC)
;

CREATE INDEX ix_purchase_return_items_material ON lychee_erp.purchase_return_items (material_id ASC)
;

ALTER TABLE lychee_erp.purchase_return_items ADD CONSTRAINT fk_purchase_return_items_header
	FOREIGN KEY (purchase_return_id) REFERENCES lychee_erp.purchase_returns (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_return_items ADD CONSTRAINT fk_purchase_return_items_original
	FOREIGN KEY (original_receipt_item_id) REFERENCES lychee_erp.goods_receipt_items (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_return_items ADD CONSTRAINT fk_purchase_return_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_return_items ADD CONSTRAINT fk_purchase_return_items_warehouse
	FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_return_items ADD CONSTRAINT fk_purchase_return_items_tax_code
	FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.purchase_return_items.original_receipt_item_id
	IS '必须参照原收货明细；同一退货单内一行对应一条收货明细，跨单部分退由 goods_receipt_items.returned_quantity + 草稿加总控制'
;

COMMENT ON COLUMN lychee_erp.purchase_return_items.stock_type
	IS 'UNRESTRICTED, INSPECTION, BLOCKED；默认原收货行，允许改'
;

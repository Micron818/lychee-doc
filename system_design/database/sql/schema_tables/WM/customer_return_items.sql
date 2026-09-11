
DROP TABLE IF EXISTS lychee_erp.customer_return_items CASCADE
;

CREATE TABLE lychee_erp.customer_return_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	customer_return_id bigint NOT NULL,
	item_no integer NOT NULL,
	original_issue_item_id bigint NOT NULL,
	delivery_item_id bigint NOT NULL,
	material_id bigint NOT NULL,
	warehouse_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL DEFAULT '',
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

ALTER TABLE lychee_erp.customer_return_items ADD CONSTRAINT pk_customer_return_items
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.customer_return_items ADD CONSTRAINT uk_customer_return_items_item_no
	UNIQUE (tenant_id, customer_return_id, item_no)
;

ALTER TABLE lychee_erp.customer_return_items ADD CONSTRAINT uk_customer_return_items_original
	UNIQUE (tenant_id, customer_return_id, original_issue_item_id)
;

CREATE INDEX ix_customer_return_items_header ON lychee_erp.customer_return_items (customer_return_id ASC)
;

CREATE INDEX ix_customer_return_items_original ON lychee_erp.customer_return_items (original_issue_item_id ASC)
;

CREATE INDEX ix_customer_return_items_delivery ON lychee_erp.customer_return_items (delivery_item_id ASC)
;

CREATE INDEX ix_customer_return_items_material ON lychee_erp.customer_return_items (material_id ASC)
;

ALTER TABLE lychee_erp.customer_return_items ADD CONSTRAINT fk_customer_return_items_header
	FOREIGN KEY (customer_return_id) REFERENCES lychee_erp.customer_returns (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_return_items ADD CONSTRAINT fk_customer_return_items_original
	FOREIGN KEY (original_issue_item_id) REFERENCES lychee_erp.stock_issue_items (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_return_items ADD CONSTRAINT fk_customer_return_items_delivery
	FOREIGN KEY (delivery_item_id) REFERENCES lychee_erp.delivery_items (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_return_items ADD CONSTRAINT fk_customer_return_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_return_items ADD CONSTRAINT fk_customer_return_items_warehouse
	FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_return_items ADD CONSTRAINT fk_customer_return_items_tax_code
	FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.customer_return_items.original_issue_item_id
	IS '必须参照表头原领料明细；同一退货单内一行对应一条领料明细，跨单部分退由 stock_issue_items.returned_quantity + 草稿加总控制'
;

COMMENT ON COLUMN lychee_erp.customer_return_items.delivery_item_id
	IS '从原领料行 source_doc_item_id 复制并校验，不可改。开票占用与已退交货量用此列'
;

COMMENT ON COLUMN lychee_erp.customer_return_items.warehouse_id
	IS '从原领料行复制，应用层锁定'
;

COMMENT ON COLUMN lychee_erp.customer_return_items.batch_no
	IS '从原领料行复制，应用层锁定；无批号时为空字串'
;

COMMENT ON COLUMN lychee_erp.customer_return_items.stock_type
	IS 'UNRESTRICTED, INSPECTION, BLOCKED；默认 UNRESTRICTED，允许改'
;

COMMENT ON COLUMN lychee_erp.customer_return_items.reason_code
	IS '自由文本，V1 不挂 option_values'
;


DROP TABLE IF EXISTS lychee_erp.stock_return_items CASCADE
;

DROP TABLE IF EXISTS lychee_erp.stock_issue_return_items CASCADE
;

CREATE TABLE lychee_erp.stock_issue_return_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	stock_issue_return_id bigint NOT NULL,
	item_no integer NOT NULL,
	original_issue_item_id bigint NOT NULL,
	material_id bigint NOT NULL,
	warehouse_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL   DEFAULT '',
	transaction_unit_id bigint NOT NULL,
	transaction_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	base_unit_id bigint NOT NULL,
	base_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	source_doc_type varchar(50) NOT NULL,    -- PRODUCTION_ORDER,PRODUCTION_ORDER_COMPONENT,PRODUCTION_REPORT_COMPONENT,SALES_ORDER,DELIVERY,DEPARTMENT,OTHER
	source_doc_id bigint NULL,
	source_doc_no varchar(50) NULL,
	source_doc_item_id bigint NULL,
	source_doc_item_no integer NULL,
	stock_type varchar(20) NOT NULL DEFAULT 'UNRESTRICTED',    -- UNRESTRICTED, INSPECTION, BLOCKED
	reason_code varchar(50) NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.stock_issue_return_items ADD CONSTRAINT pk_stock_issue_return_items
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.stock_issue_return_items ADD CONSTRAINT uk_stock_issue_return_items_item_no UNIQUE (tenant_id,stock_issue_return_id,item_no)
;


ALTER TABLE lychee_erp.stock_issue_return_items ADD CONSTRAINT uk_stock_issue_return_items UNIQUE (tenant_id,stock_issue_return_id,original_issue_item_id)
;

CREATE INDEX IXFK_stock_issue_return_items_materials ON lychee_erp.stock_issue_return_items (material_id ASC)
;

CREATE INDEX IXFK_stock_issue_return_items_stock_issue_items ON lychee_erp.stock_issue_return_items (original_issue_item_id ASC)
;

CREATE INDEX IXFK_stock_issue_return_items_stock_issue_returns ON lychee_erp.stock_issue_return_items (stock_issue_return_id ASC)
;

CREATE INDEX IXFK_stock_issue_return_items_warehouses ON lychee_erp.stock_issue_return_items (warehouse_id ASC)
;

CREATE INDEX IXFK_stock_issue_return_items_material_units ON lychee_erp.stock_issue_return_items (base_unit_id ASC)
;

ALTER TABLE lychee_erp.stock_issue_return_items ADD CONSTRAINT fk_stock_issue_return_items_materials
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_return_items ADD CONSTRAINT fk_stock_issue_return_items_stock_issue_items
	FOREIGN KEY (original_issue_item_id) REFERENCES lychee_erp.stock_issue_items (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_return_items ADD CONSTRAINT fk_stock_issue_return_items_stock_issue_returns
	FOREIGN KEY (stock_issue_return_id) REFERENCES lychee_erp.stock_issue_returns (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_return_items ADD CONSTRAINT fk_stock_issue_return_items_warehouses
	FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_return_items ADD CONSTRAINT fk_stock_issue_return_items_material_units
	FOREIGN KEY (base_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.stock_issue_return_items.original_issue_item_id
	IS '必须参照原领料明细；同一退料单内一行对应一条领料明细，跨单部分退由 stock_issue_items.returned_quantity 控制'
;

COMMENT ON COLUMN lychee_erp.stock_issue_return_items.source_doc_type
	IS 'PRODUCTION_ORDER,PRODUCTION_ORDER_COMPONENT,PRODUCTION_REPORT_COMPONENT,SALES_ORDER,DELIVERY,DEPARTMENT,OTHER；从原领料明细快照'
;

COMMENT ON COLUMN lychee_erp.stock_issue_return_items.stock_type
	IS 'UNRESTRICTED, INSPECTION, BLOCKED'
;

 

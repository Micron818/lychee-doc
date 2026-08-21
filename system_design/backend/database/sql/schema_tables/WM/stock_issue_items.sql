 

DROP TABLE IF EXISTS lychee_erp.stock_issue_items CASCADE
;

CREATE TABLE lychee_erp.stock_issue_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	stock_issue_id bigint NOT NULL,
	item_no integer NOT NULL,
	material_id bigint NOT NULL,
	warehouse_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL   DEFAULT '',
	transaction_unit_id bigint NOT NULL,
	transaction_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	base_unit_id bigint NOT NULL,
	base_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	returned_quantity numeric(18,6) NOT NULL   DEFAULT 0,    -- 已过账退料基本单位合计
	source_doc_type varchar(50) NOT NULL,    -- PRODUCTION_ORDER,PRODUCTION_ORDER_COMPONENT,PRODUCTION_REPORT_COMPONENT,SALES_ORDER,DELIVERY,DEPARTMENT,OTHER
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

ALTER TABLE lychee_erp.stock_issue_items ADD CONSTRAINT stock_issue_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.stock_issue_items ADD CONSTRAINT uk_stock_issue_items_item_no UNIQUE (tenant_id,stock_issue_id,item_no)
;


ALTER TABLE lychee_erp.stock_issue_items ADD CONSTRAINT uk_stock_issue_items UNIQUE (tenant_id,stock_issue_id,material_id,warehouse_id,batch_no,source_doc_type,source_doc_item_id,transaction_unit_id)
;

CREATE INDEX IXFK_stock_issue_items_material_units ON lychee_erp.stock_issue_items (base_unit_id ASC)
;

CREATE INDEX idx_si_items_material ON lychee_erp.stock_issue_items (material_id ASC)
;

CREATE INDEX idx_si_items_issue ON lychee_erp.stock_issue_items (stock_issue_id ASC)
;

ALTER TABLE lychee_erp.stock_issue_items ADD CONSTRAINT fk_stock_issue_items_material_units
	FOREIGN KEY (base_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_items ADD CONSTRAINT fk_si_items_issue
	FOREIGN KEY (stock_issue_id) REFERENCES lychee_erp.stock_issues (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_items ADD CONSTRAINT fk_si_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_items ADD CONSTRAINT fk_si_items_warehouse
	FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.stock_issue_items.source_doc_type
	IS 'PRODUCTION_ORDER,PRODUCTION_ORDER_COMPONENT,PRODUCTION_REPORT_COMPONENT,SALES_ORDER,DELIVERY,DEPARTMENT,OTHER'
;

COMMENT ON COLUMN lychee_erp.stock_issue_items.returned_quantity
	IS '已过账退料的基本单位合计；可退数量 = base_quantity - returned_quantity；草稿退料另按查询加总'
;

 

 

DROP TABLE IF EXISTS lychee_erp.delivery_items CASCADE
;

CREATE TABLE lychee_erp.delivery_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	delivery_id bigint NOT NULL,
	item_no integer NOT NULL,
	source_doc_type varchar(50) NULL,    -- SALES_ORDER, RETURN_PO, TRANSFER_ORDER, OTHER
	source_doc_id bigint NULL,
	source_doc_item_id bigint NULL,
	source_doc_no varchar(50) NULL,
	source_doc_item_no integer NULL,
	material_id bigint NOT NULL,
	transaction_unit_id bigint NOT NULL,
	transaction_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	base_unit_id bigint NOT NULL,
	base_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	unit_price numeric(18,4) NOT NULL   DEFAULT 0,
	tax_code_id bigint NULL,
	tax_rate numeric(5,2) NULL   DEFAULT 0,
	subtotal_amount numeric(18,2) NOT NULL   DEFAULT 0,
	tax_amount numeric(18,2) NOT NULL   DEFAULT 0,
	total_amount numeric(18,2) NOT NULL   DEFAULT 0,
	status varchar(20) NOT NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.delivery_items ADD CONSTRAINT delivery_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.delivery_items ADD CONSTRAINT uk_delivery_items_item_no UNIQUE (tenant_id,delivery_id,item_no)
;


CREATE INDEX idx_delivery_items_delivery ON lychee_erp.delivery_items (delivery_id ASC)
;

CREATE INDEX idx_delivery_items_material ON lychee_erp.delivery_items (material_id ASC)
;

CREATE INDEX idx_delivery_items_source ON lychee_erp.delivery_items (source_doc_type ASC, source_doc_id ASC)
;

CREATE INDEX idx_delivery_items ON lychee_erp.delivery_items (tenant_id ASC,delivery_id ASC,material_id ASC)
;

ALTER TABLE lychee_erp.delivery_items ADD CONSTRAINT fk_delivery_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.delivery_items ADD CONSTRAINT fk_delivery_items_delivery
	FOREIGN KEY (delivery_id) REFERENCES lychee_erp.deliveries (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.delivery_items ADD CONSTRAINT fk_delivery_items_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.delivery_items ADD CONSTRAINT fk_delivery_items_trans_unit
	FOREIGN KEY (transaction_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.delivery_items ADD CONSTRAINT fk_delivery_items_base_unit
	FOREIGN KEY (base_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.delivery_items ADD CONSTRAINT fk_delivery_items_tax_code
	FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.delivery_items.source_doc_type
	IS 'SALES_ORDER, RETURN_PO, TRANSFER_ORDER, OTHER'
;

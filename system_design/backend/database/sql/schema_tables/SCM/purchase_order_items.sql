 

DROP TABLE IF EXISTS lychee_erp.purchase_order_items CASCADE
;

CREATE TABLE lychee_erp.purchase_order_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	purchase_order_id bigint NOT NULL,
	item_no integer NOT NULL,
	material_id bigint NOT NULL,
	unit_id bigint NOT NULL,
	ordered_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	received_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	invoiced_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	unit_price numeric(18,4) NOT NULL   DEFAULT 0,
	tax_rate numeric(5,2) NULL   DEFAULT 0,
	subtotal_amount numeric(18,2) NOT NULL   DEFAULT 0,
	tax_amount numeric(18,2) NOT NULL   DEFAULT 0,
	total_amount numeric(18,2) NOT NULL   DEFAULT 0,
	required_date date NULL,
	expected_delivery_date date NULL,
	is_unlimited_over_receipt boolean NOT NULL   DEFAULT true,
	over_receipt_tolerance numeric(18,6) NULL,
	status varchar(20) NOT NULL,    -- DRAFT, APPROVED, PARTIAL,COMPLETED, CLOSED
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.purchase_order_items ADD CONSTRAINT purchase_order_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.purchase_order_items ADD CONSTRAINT uk_purchase_order_items_item_no UNIQUE (tenant_id,purchase_order_id,item_no)
;


CREATE INDEX idx_po_items_order ON lychee_erp.purchase_order_items (purchase_order_id ASC)
;

CREATE INDEX idx_po_items_material ON lychee_erp.purchase_order_items (material_id ASC)
;

ALTER TABLE lychee_erp.purchase_order_items ADD CONSTRAINT fk_po_items_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_order_items ADD CONSTRAINT fk_po_items_order
	FOREIGN KEY (purchase_order_id) REFERENCES lychee_erp.purchase_orders (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_order_items ADD CONSTRAINT fk_po_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.purchase_order_items.status
	IS 'DRAFT, APPROVED, PARTIAL,COMPLETED, CLOSED'
;

 

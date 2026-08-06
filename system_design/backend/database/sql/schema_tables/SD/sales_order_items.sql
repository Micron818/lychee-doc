 

DROP TABLE IF EXISTS lychee_erp.sales_order_items CASCADE
;

CREATE TABLE lychee_erp.sales_order_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	sales_order_id bigint NOT NULL,
	item_no integer NOT NULL,
	material_id bigint NOT NULL,
	customer_order_no varchar(50) NOT NULL,
	customer_internal_ref_no varchar(50) NULL,
	unit_id bigint NOT NULL,
	quantity numeric(18,6) NOT NULL,
	unit_price numeric(18,4) NOT NULL   DEFAULT 0,
	tax_rate numeric(5,2) NULL   DEFAULT 0,
	subtotal_amount numeric(18,2) NOT NULL   DEFAULT 0,
	tax_amount numeric(18,2) NOT NULL   DEFAULT 0,
	total_amount numeric(18,2) NOT NULL   DEFAULT 0,
	delivered_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	allocated_quantity numeric(18,6) NOT NULL   DEFAULT 0,    -- quantity of converted to FactoryOrderItem
	expected_delivery_date date NULL,
	order_status varchar(20) NOT NULL,    -- DRAFT,CONFIRMED,DELIVERED,CLOSED,CANCELLED
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.sales_order_items ADD CONSTRAINT sales_order_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.sales_order_items ADD CONSTRAINT uk_sales_order_items_item_no UNIQUE (tenant_id,sales_order_id,item_no)
;


CREATE INDEX idx_sales_order_items_order ON lychee_erp.sales_order_items (sales_order_id ASC)
;

CREATE INDEX idx_sales_order_items_material ON lychee_erp.sales_order_items (material_id ASC)
;

CREATE INDEX idx_sales_order_items_order_status ON lychee_erp.sales_order_items (order_status ASC)
;

ALTER TABLE lychee_erp.sales_order_items ADD CONSTRAINT fk_sales_order_items_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_order_items ADD CONSTRAINT fk_sales_order_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_order_items ADD CONSTRAINT fk_sales_order_items_order
	FOREIGN KEY (sales_order_id) REFERENCES lychee_erp.sales_orders (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_order_items ADD CONSTRAINT fk_sales_order_items_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_order_items ADD CONSTRAINT fk_sales_order_items_unit
	FOREIGN KEY (unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_order_items ADD CONSTRAINT fk_sales_order_items_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.sales_order_items.allocated_quantity
	IS 'quantity of converted to FactoryOrderItem'
;

COMMENT ON COLUMN lychee_erp.sales_order_items.order_status
	IS 'DRAFT,CONFIRMED,DELIVERED,CLOSED,CANCELLED'
;

 

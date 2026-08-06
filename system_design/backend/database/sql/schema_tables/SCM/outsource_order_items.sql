 

DROP TABLE IF EXISTS lychee_erp.outsource_order_items CASCADE
;

CREATE TABLE lychee_erp.outsource_order_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	outsource_order_id bigint NOT NULL,
	item_no integer NOT NULL,
	material_id bigint NOT NULL,
	unit_id bigint NOT NULL,
	ordered_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	received_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	unit_price numeric(18,4) NOT NULL   DEFAULT 0,
	subtotal_amount numeric(18,2) NOT NULL   DEFAULT 0,
	required_date date NULL,
	planned_start_date date NULL,
	requires_physical_receipt boolean NOT NULL   DEFAULT true,
	is_unlimited_over_receipt boolean NOT NULL   DEFAULT true,
	status varchar(20) NOT NULL,    -- DRAFT, ISSUED, PARTIAL, COMPLETED, CLOSED
	over_receipt_tolerance numeric(18,6) NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.outsource_order_items ADD CONSTRAINT outsource_order_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.outsource_order_items ADD CONSTRAINT uk_outsource_order_items_item_no UNIQUE (tenant_id,outsource_order_id,item_no)
;


CREATE INDEX idx_outsource_items_order ON lychee_erp.outsource_order_items (outsource_order_id ASC)
;

CREATE INDEX idx_outsource_items_material ON lychee_erp.outsource_order_items (material_id ASC)
;

ALTER TABLE lychee_erp.outsource_order_items ADD CONSTRAINT fk_outsource_items_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_items ADD CONSTRAINT fk_outsource_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_items ADD CONSTRAINT fk_outsource_items_order
	FOREIGN KEY (outsource_order_id) REFERENCES lychee_erp.outsource_orders (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_items ADD CONSTRAINT fk_outsource_items_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_items ADD CONSTRAINT fk_outsource_items_unit
	FOREIGN KEY (unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_items ADD CONSTRAINT fk_outsource_items_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.outsource_order_items.status
	IS 'DRAFT, ISSUED, PARTIAL, COMPLETED, CLOSED'
;

 

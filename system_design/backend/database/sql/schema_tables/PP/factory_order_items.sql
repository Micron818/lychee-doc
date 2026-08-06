 

DROP TABLE IF EXISTS lychee_erp.factory_order_items CASCADE
;

CREATE TABLE lychee_erp.factory_order_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	factory_order_id bigint NOT NULL,
	item_no integer NOT NULL,
	product_material_id bigint NOT NULL,
	allocated_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	quantity numeric(18,6) NOT NULL   DEFAULT 0,
	due_date date NOT NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.factory_order_items ADD CONSTRAINT factory_order_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.factory_order_items ADD CONSTRAINT uk_factory_order_items_item_no UNIQUE (tenant_id,factory_order_id,item_no)
;


CREATE INDEX idx_factory_order_items_materials ON lychee_erp.factory_order_items (product_material_id ASC)
;

CREATE INDEX idx_factory_order_items_fo ON lychee_erp.factory_order_items (factory_order_id ASC)
;

ALTER TABLE lychee_erp.factory_order_items ADD CONSTRAINT fk_factory_order_items_materials
	FOREIGN KEY (product_material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.factory_order_items ADD CONSTRAINT fk_fo_items_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.factory_order_items ADD CONSTRAINT fk_fo_items_fo
	FOREIGN KEY (factory_order_id) REFERENCES lychee_erp.factory_orders (id) ON DELETE Cascade ON UPDATE No Action
;

 

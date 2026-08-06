 

DROP TABLE IF EXISTS lychee_erp.production_orders CASCADE
;

CREATE TABLE lychee_erp.production_orders
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	order_no varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	product_material_id bigint NOT NULL,
	order_unit_id bigint NOT NULL,
	bom_id bigint NULL,
	department_id bigint NULL,
	planned_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	completed_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	scrapped_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	scheduled_start_date date NULL,
	scheduled_end_date date NULL,
	actual_start_date timestamp without time zone NULL,
	actual_end_date timestamp without time zone NULL,
	under_delivery_tolerance numeric(18,6) NULL   DEFAULT 0,
	order_status varchar(20) NOT NULL,    -- CREATED/RELEASED/IN_PROGRESS/FINISHED/CLOSED/CANCELLED
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.production_orders ADD CONSTRAINT production_orders_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.production_orders ADD CONSTRAINT uk_production_orders_tenant_no UNIQUE (tenant_id,order_no)
;

CREATE INDEX ixfk_production_orders_material_units ON lychee_erp.production_orders (order_unit_id ASC)
;

CREATE INDEX idx_production_orders_product ON lychee_erp.production_orders (product_material_id ASC)
;

CREATE INDEX ixfk_production_orders_factories ON lychee_erp.production_orders (factory_id ASC)
;

CREATE INDEX idx_production_orders_status ON lychee_erp.production_orders (order_status ASC)
;

ALTER TABLE lychee_erp.production_orders ADD CONSTRAINT fk_production_orders_bom
	FOREIGN KEY (bom_id) REFERENCES lychee_erp.bill_of_materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_orders ADD CONSTRAINT fk_production_orders_dept
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE Set Null ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_orders ADD CONSTRAINT fk_production_orders_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_orders ADD CONSTRAINT fk_production_orders_material_units
	FOREIGN KEY (order_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_orders ADD CONSTRAINT fk_production_orders_product
	FOREIGN KEY (product_material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_orders ADD CONSTRAINT fk_production_orders_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.production_orders.order_status
	IS 'CREATED/RELEASED/IN_PROGRESS/FINISHED/CLOSED/CANCELLED'
;

 
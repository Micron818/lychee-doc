 

DROP TABLE IF EXISTS lychee_erp.planned_orders CASCADE
;

CREATE TABLE lychee_erp.planned_orders
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	order_no varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	mrp_run_id bigint NULL,
	product_material_id bigint NOT NULL,
	quantity numeric(18,6) NOT NULL,
	start_date date NOT NULL,
	end_date date NOT NULL,
	order_type varchar(20) NOT NULL,
	order_status varchar(20) NOT NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.planned_orders ADD CONSTRAINT planned_orders_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.planned_orders ADD CONSTRAINT uk_planned_orders_tenant_no UNIQUE (tenant_id,order_no)
;

CREATE INDEX IXFK_planned_orders_factories ON lychee_erp.planned_orders (factory_id ASC)
;

CREATE INDEX idx_planned_orders_date ON lychee_erp.planned_orders (start_date ASC)
;

ALTER TABLE lychee_erp.planned_orders ADD CONSTRAINT fk_planned_orders_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.planned_orders ADD CONSTRAINT fk_planned_orders_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.planned_orders ADD CONSTRAINT fk_planned_orders_mrp_run
	FOREIGN KEY (mrp_run_id) REFERENCES lychee_erp.mrp_runs (id) ON DELETE Set Null ON UPDATE No Action
;

ALTER TABLE lychee_erp.planned_orders ADD CONSTRAINT fk_planned_orders_product
	FOREIGN KEY (product_material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

 
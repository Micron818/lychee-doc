 

DROP TABLE IF EXISTS lychee_erp.factory_orders CASCADE
;

CREATE TABLE lychee_erp.factory_orders
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	order_no varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	customer_id bigint NOT NULL,
	order_date date NOT NULL,
	remarks text NULL,
	order_status varchar(20) NOT NULL,
	priority varchar(20) NOT NULL,
	source_type varchar(20) NOT NULL,
	total_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	so_count integer NOT NULL   DEFAULT 0,
	confirmed_at timestamp without time zone NULL,
	confirmed_by bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.factory_orders ADD CONSTRAINT factory_orders_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.factory_orders ADD CONSTRAINT uk_factory_orders_tenant_no UNIQUE (tenant_id,order_no)
;

CREATE INDEX ixfk_factory_orders_customers ON lychee_erp.factory_orders (customer_id ASC)
;

CREATE INDEX IXFK_factory_orders_factories ON lychee_erp.factory_orders (factory_id ASC)
;

CREATE INDEX idx_factory_orders_order_status ON lychee_erp.factory_orders (order_status ASC)
;

CREATE INDEX idx_factory_orders_priority ON lychee_erp.factory_orders (priority ASC)
;

ALTER TABLE lychee_erp.factory_orders ADD CONSTRAINT fk_factory_orders_customer
	FOREIGN KEY (customer_id) REFERENCES lychee_erp.customers (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.factory_orders ADD CONSTRAINT fk_factory_orders_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.factory_orders ADD CONSTRAINT fk_factory_orders_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

 
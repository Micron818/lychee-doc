 

DROP TABLE IF EXISTS lychee_erp.sales_orders CASCADE
;

CREATE TABLE lychee_erp.sales_orders
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	order_no varchar(50) NOT NULL,
	order_date date NOT NULL,
	expected_delivery_date date NULL,
	customer_id bigint NOT NULL,
	customer_name varchar(200) NULL,
	customer_po_no varchar(50) NOT NULL,
	sales_person_id bigint NULL,
	currency_option_id bigint NULL,
	exchange_rate numeric(18,6) NOT NULL   DEFAULT 1,
	payment_term_option_id bigint NULL,
	billing_address text NULL,
	shipping_address text NULL,
	subtotal_amount numeric(18,2) NOT NULL   DEFAULT 0,
	tax_amount numeric(18,2) NOT NULL   DEFAULT 0,
	total_amount numeric(18,2) NOT NULL   DEFAULT 0,
	order_status varchar(20) NOT NULL,    -- DRAFT,CONFIRMED,DELIVERED,CLOSED,CANCELLED
	confirmed_at timestamp without time zone NULL,
	confirmed_by bigint NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT sales_orders_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT uk_sales_orders_tenant_code UNIQUE (tenant_id,order_no)
;

CREATE INDEX idx_sales_orders_order_date ON lychee_erp.sales_orders (order_date ASC)
;

CREATE INDEX idx_sales_orders_customer ON lychee_erp.sales_orders (customer_id ASC)
;

CREATE INDEX idx_sales_orders_sales_person ON lychee_erp.sales_orders (sales_person_id ASC)
;

CREATE INDEX idx_sales_orders_order_status ON lychee_erp.sales_orders (order_status ASC)
;

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_customer
	FOREIGN KEY (customer_id) REFERENCES lychee_erp.customers (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_payment_term
	FOREIGN KEY (payment_term_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_sales_person
	FOREIGN KEY (sales_person_id) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.sales_orders.order_status
	IS 'DRAFT,CONFIRMED,DELIVERED,CLOSED,CANCELLED'
;

 
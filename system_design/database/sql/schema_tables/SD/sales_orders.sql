 

DROP TABLE IF EXISTS lychee_erp.sales_orders CASCADE
;

CREATE TABLE lychee_erp.sales_orders (
	id bigserial NOT NULL,
	tenant_id int8 NOT NULL,
	order_date date NOT NULL,
	expected_delivery_date date NULL,
	customer_id int8 NOT NULL,
	customer_po_no varchar(50) NOT NULL,
	sales_person_id int8 NULL,
	currency_option_id int8 NULL,
	exchange_rate numeric(18, 6) DEFAULT 1 NOT NULL,
	billing_address text NULL,
	shipping_address text NULL,
	subtotal_amount numeric(18, 2) DEFAULT 0 NOT NULL,
	tax_amount numeric(18, 2) DEFAULT 0 NOT NULL,
	total_amount numeric(18, 2) DEFAULT 0 NOT NULL,
	remarks text NULL,
	confirmed_at timestamp NULL,
	confirmed_by int8 NULL,
	created_at timestamp NULL,
	updated_at timestamp NULL,
	created_by int8 NULL,
	updated_by int8 NULL,
	order_no varchar(50) NOT NULL,
	order_status varchar(20) NOT NULL, -- DRAFT,CONFIRMED,DELIVERED,CLOSED,CANCELLED
	customer_name varchar(200) NULL,
	company_id int8 NOT NULL, -- Selling company (letterhead / company code)
	payment_term_id int8 NULL,
	CONSTRAINT sales_orders_pkey PRIMARY KEY (id),
	CONSTRAINT uk_sales_orders_tenant_code UNIQUE (tenant_id, order_no)
);
CREATE INDEX idx_sales_orders_company ON lychee_erp.sales_orders USING btree (company_id);
CREATE INDEX idx_sales_orders_customer ON lychee_erp.sales_orders USING btree (customer_id);
CREATE INDEX idx_sales_orders_order_date ON lychee_erp.sales_orders USING btree (order_date);
CREATE INDEX idx_sales_orders_order_status ON lychee_erp.sales_orders USING btree (order_status);
CREATE INDEX idx_sales_orders_sales_person ON lychee_erp.sales_orders USING btree (sales_person_id);

-- Column comments

COMMENT ON COLUMN lychee_erp.sales_orders.order_status IS 'DRAFT,CONFIRMED,DELIVERED,CLOSED,CANCELLED';
COMMENT ON COLUMN lychee_erp.sales_orders.company_id IS 'Selling company (letterhead / company code)';


-- lychee_erp.sales_orders foreign keys

ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_company FOREIGN KEY (company_id) REFERENCES lychee_erp.companies(id);
ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users(id);
ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_currency FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values(id);
ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_customer FOREIGN KEY (customer_id) REFERENCES lychee_erp.customers(id);
ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_payment_term FOREIGN KEY (payment_term_id) REFERENCES lychee_erp.fi_payment_terms(id);
ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_sales_person FOREIGN KEY (sales_person_id) REFERENCES lychee_erp.users(id);
ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants(id);
ALTER TABLE lychee_erp.sales_orders ADD CONSTRAINT fk_sales_orders_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users(id);
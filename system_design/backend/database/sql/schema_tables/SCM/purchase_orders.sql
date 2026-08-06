 

DROP TABLE IF EXISTS lychee_erp.purchase_orders CASCADE
;

CREATE TABLE lychee_erp.purchase_orders
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	order_no varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	order_date date NOT NULL,
	supplier_id bigint NOT NULL,
	currency_option_id bigint NULL,
	exchange_rate numeric(18,6) NOT NULL   DEFAULT 1,
	payment_term_option_id bigint NULL,
	billing_address text NULL,
	shipping_address text NULL,
	subtotal_amount numeric(18,2) NOT NULL   DEFAULT 0,
	tax_amount numeric(18,2) NOT NULL   DEFAULT 0,
	total_amount numeric(18,2) NOT NULL   DEFAULT 0,
	status varchar(20) NOT NULL,    -- DRAFT, APPROVED, PARTIAL,COMPLETED, CLOSED
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.purchase_orders ADD CONSTRAINT purchase_orders_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.purchase_orders ADD CONSTRAINT uk_purchase_orders_tenant UNIQUE (tenant_id,order_no)
;

CREATE INDEX IXFK_purchase_orders_factories ON lychee_erp.purchase_orders (factory_id ASC)
;

CREATE INDEX idx_purchase_orders_supplier ON lychee_erp.purchase_orders (supplier_id ASC)
;

ALTER TABLE lychee_erp.purchase_orders ADD CONSTRAINT fk_purchase_orders_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_orders ADD CONSTRAINT fk_purchase_orders_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_orders ADD CONSTRAINT fk_purchase_orders_supplier
	FOREIGN KEY (supplier_id) REFERENCES lychee_erp.suppliers (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_orders ADD CONSTRAINT fk_purchase_orders_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_orders ADD CONSTRAINT fk_purchase_orders_payment_term
	FOREIGN KEY (payment_term_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_orders ADD CONSTRAINT fk_purchase_orders_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_orders ADD CONSTRAINT fk_purchase_orders_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.purchase_orders.status
	IS 'DRAFT, APPROVED, PARTIAL,COMPLETED, CLOSED'
;

 
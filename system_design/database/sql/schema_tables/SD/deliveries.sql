 

DROP TABLE IF EXISTS lychee_erp.deliveries CASCADE
;

CREATE TABLE lychee_erp.deliveries
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	delivery_no varchar(50) NOT NULL,
	delivery_type varchar(20) NOT NULL,    -- NORMAL, RETURN, SAMPLE
	planned_delivery_date date NOT NULL,
	actual_delivery_date date NULL,
	customer_id bigint NOT NULL,
	shipping_address text NULL,
	carrier_name varchar(100) NULL,
	tracking_number varchar(100) NULL,
	currency_option_id bigint NULL,
	exchange_rate numeric(18,6) NOT NULL   DEFAULT 1,
	total_amount numeric(18,2) NOT NULL   DEFAULT 0,
	status varchar(20) NOT NULL,    -- DRAFT, RELEASED, DELIVERED, CANCELLED
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.deliveries ADD CONSTRAINT deliveries_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.deliveries ADD CONSTRAINT uk_deliveries UNIQUE (tenant_id,factory_id,delivery_no)
;

CREATE INDEX IXFK_deliveries_factories ON lychee_erp.deliveries (factory_id ASC)
;

CREATE INDEX idx_deliveries_planned_date ON lychee_erp.deliveries (planned_delivery_date ASC)
;

CREATE INDEX idx_deliveries_actual_date ON lychee_erp.deliveries (actual_delivery_date ASC)
;

CREATE INDEX idx_deliveries_customer ON lychee_erp.deliveries (customer_id ASC)
;

ALTER TABLE lychee_erp.deliveries ADD CONSTRAINT fk_deliveries_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.deliveries ADD CONSTRAINT fk_deliveries_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.deliveries ADD CONSTRAINT fk_deliveries_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.deliveries ADD CONSTRAINT fk_deliveries_customer
	FOREIGN KEY (customer_id) REFERENCES lychee_erp.customers (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.deliveries ADD CONSTRAINT fk_deliveries_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.deliveries ADD CONSTRAINT fk_deliveries_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.deliveries.delivery_type
	IS 'NORMAL, RETURN, SAMPLE'
;

COMMENT ON COLUMN lychee_erp.deliveries.status
	IS 'DRAFT, RELEASED, DELIVERED, CANCELLED'
;

 
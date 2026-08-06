 

DROP TABLE IF EXISTS lychee_erp.sales_forecasts CASCADE
;

CREATE TABLE lychee_erp.sales_forecasts
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	material_id bigint NOT NULL,
	bucket_date date NOT NULL,
	unit_id bigint NOT NULL,
	forecast_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	consumed_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	customer_id bigint NOT NULL,
	status varchar(20) NOT NULL,    -- DRAFT, ACTIVE, CLOSED
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.sales_forecasts ADD CONSTRAINT sales_forecasts_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.sales_forecasts ADD CONSTRAINT uk_sales_forecasts_item_date_version UNIQUE (tenant_id,material_id,bucket_date)
;

CREATE INDEX idx_sales_forecasts_material ON lychee_erp.sales_forecasts (material_id ASC)
;

CREATE INDEX idx_sales_forecasts_customer ON lychee_erp.sales_forecasts (customer_id ASC)
;

ALTER TABLE lychee_erp.sales_forecasts ADD CONSTRAINT fk_sales_forecasts_customer
	FOREIGN KEY (customer_id) REFERENCES lychee_erp.customers (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.sales_forecasts ADD CONSTRAINT fk_sales_forecasts_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.sales_forecasts.status
	IS 'DRAFT, ACTIVE, CLOSED'
;

 
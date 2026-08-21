 

DROP TABLE IF EXISTS lychee_erp.stock_returns CASCADE
;

CREATE TABLE lychee_erp.stock_returns
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	return_date date NOT NULL,
	department_id bigint NULL,
	return_type varchar(20) NOT NULL,    -- PRODUCTION,PRODUCTION_REPORT,COST_CENTER,SCRAP,SAMPLE,SALES_DELIVERY
	status varchar(20) NOT NULL,    -- DRAFT, POSTED, REVERSED
	approved_by bigint NULL,
	approved_at timestamp without time zone NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.stock_returns ADD CONSTRAINT pk_stock_returns
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.stock_returns ADD CONSTRAINT uk_stock_returns UNIQUE (tenant_id,code)
;

COMMENT ON COLUMN lychee_erp.stock_returns.return_type
	IS 'PRODUCTION,PRODUCTION_REPORT,COST_CENTER,SCRAP,SAMPLE,SALES_DELIVERY'
;

COMMENT ON COLUMN lychee_erp.stock_returns.status
	IS 'DRAFT, POSTED, REVERSED'
;

 
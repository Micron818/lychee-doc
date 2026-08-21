 

DROP TABLE IF EXISTS lychee_erp.stock_transfers CASCADE
;

CREATE TABLE lychee_erp.stock_transfers
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	transfer_date date NOT NULL,
	transfer_type varchar(20) NOT NULL,    -- OUTSOURCE, INTERNAL
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

ALTER TABLE lychee_erp.stock_transfers ADD CONSTRAINT stock_transfers_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.stock_transfers ADD CONSTRAINT uk_stock_transfers_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_stock_transfers_date ON lychee_erp.stock_transfers (transfer_date ASC)
;

ALTER TABLE lychee_erp.stock_transfers ADD CONSTRAINT fk_stock_transfers_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_transfers ADD CONSTRAINT fk_stock_transfers_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_transfers ADD CONSTRAINT fk_stock_transfers_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.stock_transfers.transfer_type
	IS 'OUTSOURCE, INTERNAL'
;

COMMENT ON COLUMN lychee_erp.stock_transfers.status
	IS 'DRAFT, POSTED, REVERSED'
;

 
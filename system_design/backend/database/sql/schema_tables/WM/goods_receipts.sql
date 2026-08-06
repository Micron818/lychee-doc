 

DROP TABLE IF EXISTS lychee_erp.goods_receipts CASCADE
;

CREATE TABLE lychee_erp.goods_receipts
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	receipt_no varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	receipt_date date NOT NULL,
	receipt_type varchar(20) NOT NULL,    -- PURCHASE, PRODUCTION_REPORT, MISC
	supplier_id bigint NULL,
	delivery_note_no varchar(50) NULL,
	remarks text NULL,
	status varchar(20) NOT NULL,    -- DRAFT, POSTED, REVERSED
	invoice_status varchar(20) NOT NULL DEFAULT 'UNINVOICED',
	journal_entry_id bigint NULL,
	currency_option_id bigint NULL,
	exchange_rate numeric(18,6) NOT NULL DEFAULT 1,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.goods_receipts ADD CONSTRAINT goods_receipts_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.goods_receipts ADD CONSTRAINT uk_goods_receipts UNIQUE (tenant_id,receipt_no)
;

CREATE INDEX idx_goods_receipts_supplier ON lychee_erp.goods_receipts (supplier_id ASC)
;

ALTER TABLE lychee_erp.goods_receipts ADD CONSTRAINT fk_goods_receipts_supplier
	FOREIGN KEY (supplier_id) REFERENCES lychee_erp.suppliers (id) ON DELETE No Action ON UPDATE No Action
;

CREATE INDEX idx_goods_receipts_journal_entry ON lychee_erp.goods_receipts (journal_entry_id ASC)
;

ALTER TABLE lychee_erp.goods_receipts ADD CONSTRAINT fk_goods_receipts_journal_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.goods_receipts ADD CONSTRAINT fk_goods_receipts_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.goods_receipts.receipt_type
	IS 'PURCHASE, PRODUCTION_REPORT, MISC'
;

COMMENT ON COLUMN lychee_erp.goods_receipts.status
	IS 'DRAFT, POSTED, REVERSED'
;

COMMENT ON COLUMN lychee_erp.goods_receipts.invoice_status
	IS 'UNINVOICED, PARTIAL, FULLY_INVOICED'
;

COMMENT ON COLUMN lychee_erp.goods_receipts.journal_entry_id
	IS '收货暂估(GR/IR)凭证'
;

COMMENT ON COLUMN lychee_erp.goods_receipts.currency_option_id
	IS 'Document currency snapshot from source PO / outsource (frozen at post)'
;

COMMENT ON COLUMN lychee_erp.goods_receipts.exchange_rate
	IS 'Document → local exchange rate snapshot (frozen at post)'
;

 
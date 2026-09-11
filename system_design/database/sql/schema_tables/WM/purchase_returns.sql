
DROP TABLE IF EXISTS lychee_erp.purchase_returns CASCADE
;

CREATE TABLE lychee_erp.purchase_returns
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	return_date date NOT NULL,
	supplier_id bigint NOT NULL,
	original_goods_receipt_id bigint NOT NULL,
	status varchar(20) NOT NULL,    -- DRAFT, POSTED, REVERSED
	currency_option_id bigint NULL,
	exchange_rate numeric(18,6) NOT NULL DEFAULT 1,
	remarks text NULL,
	journal_entry_id bigint NULL,
	approved_by bigint NULL,
	approved_at timestamp without time zone NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.purchase_returns ADD CONSTRAINT pk_purchase_returns
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.purchase_returns ADD CONSTRAINT uk_purchase_returns UNIQUE (tenant_id,code)
;

CREATE INDEX idx_purchase_returns_date ON lychee_erp.purchase_returns (return_date ASC)
;

CREATE INDEX idx_purchase_returns_supplier ON lychee_erp.purchase_returns (supplier_id ASC)
;

CREATE INDEX idx_purchase_returns_original_receipt ON lychee_erp.purchase_returns (original_goods_receipt_id ASC)
;

CREATE INDEX idx_purchase_returns_journal_entry ON lychee_erp.purchase_returns (journal_entry_id ASC)
;

ALTER TABLE lychee_erp.purchase_returns ADD CONSTRAINT fk_purchase_returns_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_returns ADD CONSTRAINT fk_purchase_returns_factory
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_returns ADD CONSTRAINT fk_purchase_returns_supplier
	FOREIGN KEY (supplier_id) REFERENCES lychee_erp.suppliers (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_returns ADD CONSTRAINT fk_purchase_returns_original_receipt
	FOREIGN KEY (original_goods_receipt_id) REFERENCES lychee_erp.goods_receipts (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_returns ADD CONSTRAINT fk_purchase_returns_journal_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_returns ADD CONSTRAINT fk_purchase_returns_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.purchase_returns.original_goods_receipt_id
	IS '一张采购退货单只对应一张已过账采购收货 goods_receipts.id'
;

COMMENT ON COLUMN lychee_erp.purchase_returns.status
	IS 'DRAFT, POSTED, REVERSED'
;

COMMENT ON COLUMN lychee_erp.purchase_returns.approved_by
	IS '过账人，不是独立审批节点'
;

COMMENT ON COLUMN lychee_erp.purchase_returns.journal_entry_id
	IS '本单 GR/IR 冲回凭证；不回写原收货 journal_entry_id'
;

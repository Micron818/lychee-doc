
DROP TABLE IF EXISTS lychee_erp.customer_returns CASCADE
;

CREATE TABLE lychee_erp.customer_returns
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	return_date date NOT NULL,
	customer_id bigint NOT NULL,
	original_stock_issue_id bigint NOT NULL,
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

ALTER TABLE lychee_erp.customer_returns ADD CONSTRAINT pk_customer_returns
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.customer_returns ADD CONSTRAINT uk_customer_returns UNIQUE (tenant_id,code)
;

CREATE INDEX idx_customer_returns_date ON lychee_erp.customer_returns (return_date ASC)
;

CREATE INDEX idx_customer_returns_customer ON lychee_erp.customer_returns (customer_id ASC)
;

CREATE INDEX idx_customer_returns_original_issue ON lychee_erp.customer_returns (original_stock_issue_id ASC)
;

CREATE INDEX idx_customer_returns_journal_entry ON lychee_erp.customer_returns (journal_entry_id ASC)
;

ALTER TABLE lychee_erp.customer_returns ADD CONSTRAINT fk_customer_returns_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_returns ADD CONSTRAINT fk_customer_returns_factory
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_returns ADD CONSTRAINT fk_customer_returns_customer
	FOREIGN KEY (customer_id) REFERENCES lychee_erp.customers (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_returns ADD CONSTRAINT fk_customer_returns_original_issue
	FOREIGN KEY (original_stock_issue_id) REFERENCES lychee_erp.stock_issues (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_returns ADD CONSTRAINT fk_customer_returns_journal_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.customer_returns ADD CONSTRAINT fk_customer_returns_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.customer_returns.original_stock_issue_id
	IS '一张客户退货单只对应一张已过账 SALES_DELIVERY 领料 stock_issues.id'
;

COMMENT ON COLUMN lychee_erp.customer_returns.status
	IS 'DRAFT, POSTED, REVERSED'
;

COMMENT ON COLUMN lychee_erp.customer_returns.approved_by
	IS '过账人，不是独立审批节点'
;

COMMENT ON COLUMN lychee_erp.customer_returns.journal_entry_id
	IS '本单 COGS 冲回凭证；不回写原领料 journal_entry_id。冲销后退货单此列置空'
;

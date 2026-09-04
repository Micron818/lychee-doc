DROP TABLE IF EXISTS lychee_erp.journal_entries CASCADE;

CREATE TABLE lychee_erp.journal_entries
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	journal_no varchar(50) NOT NULL,
	journal_date date NOT NULL,
	fiscal_period_id bigint NOT NULL,
	document_date date NOT NULL,
	post_date date NULL,
	currency_id bigint NOT NULL,
	local_currency_id bigint NOT NULL,
	exchange_rate numeric(18,6) NOT NULL DEFAULT 1,
	
	-- 汇总金额 (用于快速校验借贷必相等)
	total_debit numeric(18,2) NOT NULL DEFAULT 0,
	total_credit numeric(18,2) NOT NULL DEFAULT 0,
	local_total_debit numeric(18,2) NOT NULL DEFAULT 0,
	local_total_credit numeric(18,2) NOT NULL DEFAULT 0,
	
	attachments_count integer NULL,
	journal_type varchar(20) NOT NULL DEFAULT 'AUTO',    -- AUTO, MANUAL
	
	-- 来源单据追溯 (主表级别)
	source_module varchar(20) NOT NULL,    -- GL, AR, AP, FA, IN, CASH, COSTING
	source_doc_type varchar(50) NULL,      -- AR_INVOICE, AP_INVOICE, AP_CREDIT_MEMO, AR_CREDIT_MEMO, PAYMENT, PAYMENT_ALLOC, SUPPLIER_REFUND, SUPPLIER_REFUND_ALLOC, CUSTOMER_REFUND, CUSTOMER_REFUND_ALLOC
	source_doc_id bigint NULL,             -- 关联来源单据的主键ID
	reference_no varchar(100) NULL,        -- 来源单据号 (如发票号，方便财务人员直观查看)
	
	-- 冲销关联
	reversal_entry_id bigint NULL,         -- 如果是冲销凭证，记录被冲销的凭证ID；或者记录冲销它的凭证ID
	
	description text NULL,
	status varchar(20) NOT NULL DEFAULT 'DRAFT',    -- DRAFT, PENDING_APPROVAL, APPROVED, POSTED, VOIDED, REVERSED
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT journal_entries_pkey
	PRIMARY KEY (id);

ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT uk_journal_entries UNIQUE (tenant_id,company_id,journal_no);

CREATE INDEX IXFK_journal_entries_companies ON lychee_erp.journal_entries (company_id ASC);
CREATE INDEX IXFK_journal_entries_local_currency ON lychee_erp.journal_entries (local_currency_id ASC);
CREATE INDEX idx_journal_entries_period ON lychee_erp.journal_entries (fiscal_period_id ASC);
CREATE INDEX idx_journal_entries_source ON lychee_erp.journal_entries (source_doc_type ASC,source_doc_id ASC);
CREATE INDEX IXFK_journal_entries_currency ON lychee_erp.journal_entries (currency_id ASC);
CREATE INDEX idx_journal_entries_reversal ON lychee_erp.journal_entries (reversal_entry_id ASC);

ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT fk_journal_entries_companies
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT fk_journal_entries_local_currency
	FOREIGN KEY (local_currency_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT fk_journal_entries_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT fk_journal_entries_period
	FOREIGN KEY (fiscal_period_id) REFERENCES lychee_erp.fiscal_periods (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT fk_journal_entries_currency
	FOREIGN KEY (currency_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;

-- 自关联外键 (冲销凭证)
ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT fk_journal_entries_reversal
	FOREIGN KEY (reversal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT fk_journal_entries_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entries ADD CONSTRAINT fk_journal_entries_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.journal_entries.journal_type
	IS 'AUTO, MANUAL';

COMMENT ON COLUMN lychee_erp.journal_entries.source_module
	IS 'GL, AR, AP, FA, IN, CASH, COSTING';

COMMENT ON COLUMN lychee_erp.journal_entries.status
	IS 'DRAFT, PENDING_APPROVAL, APPROVED, POSTED, VOIDED, REVERSED';

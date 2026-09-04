DROP TABLE IF EXISTS lychee_erp.payments CASCADE;

-- ==========================================
-- Payments (收付款主表)
-- ==========================================
CREATE TABLE lychee_erp.payments
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	payment_no varchar(50) NOT NULL,
	payment_type varchar(20) NOT NULL,      -- RECEIPT (收款), DISBURSEMENT (付款)
	payment_purpose varchar(30) NOT NULL DEFAULT 'STANDARD', -- STANDARD, SUPPLIER_REFUND, CUSTOMER_REFUND
	payment_date date NOT NULL,

	-- 往来单位 (与 ap_invoices / ar_invoices 一致，指向 FI.business_partners)
	partner_type varchar(50) NOT NULL,      -- CUSTOMER, SUPPLIER, EMPLOYEE
	partner_id bigint NOT NULL,
	partner_code varchar(50) NOT NULL,      -- 对方编码快照
	partner_name varchar(100) NOT NULL,     -- 对方名称快照

	-- 对方银行账户 (关联 partner_bank_accounts，提交/过账时写入快照)
	partner_bank_account_id bigint NULL,
	partner_bank_name varchar(100) NULL,
	partner_bank_branch varchar(100) NULL,
	partner_account_no varchar(50) NULL,
	partner_account_name varchar(100) NULL,

	-- 公司内部资金账户 (关联 company_bank_accounts，提交/过账时写入快照)
	internal_bank_account_id bigint NULL,
	internal_bank_name varchar(100) NULL,
	internal_bank_branch varchar(100) NULL,
	internal_account_no varchar(50) NULL,
	internal_account_name varchar(100) NULL,

	-- 金额
	currency_option_id bigint NOT NULL,
	exchange_rate numeric(18,6) NOT NULL DEFAULT 1,
	amount numeric(18,2) NOT NULL DEFAULT 0,
	unallocated_amount numeric(18,2) NOT NULL DEFAULT 0, -- 未核销金额 (用于处理预收款/预付款)
	is_prepayment boolean NOT NULL DEFAULT false,

	-- 支付方式
	payment_method varchar(50) NULL,        -- BANK_TRANSFER, CHECK, CASH
	reference_no varchar(100) NULL,         -- 外部流水号/支票号/网银交易号

	status varchar(20) NOT NULL DEFAULT 'DRAFT', -- DRAFT, PENDING_APPROVAL, APPROVED, POSTED, VOIDED
	journal_entry_id bigint NULL,
	approved_at timestamp without time zone NULL,
	approved_by bigint NULL,
	posted_at timestamp without time zone NULL,
	posted_by bigint NULL,
	voided_at timestamp without time zone NULL,
	voided_by bigint NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.payments ADD CONSTRAINT payments_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.payments ADD CONSTRAINT uk_payments_tenant_company_no UNIQUE (tenant_id, company_id, payment_no);

CREATE INDEX idx_payments_date ON lychee_erp.payments (tenant_id, company_id, payment_date ASC);
CREATE INDEX idx_payments_partner ON lychee_erp.payments (partner_id ASC);
CREATE INDEX idx_payments_type ON lychee_erp.payments (payment_type ASC);
CREATE INDEX idx_payments_status ON lychee_erp.payments (status ASC);
CREATE INDEX idx_payments_journal_entry ON lychee_erp.payments (journal_entry_id ASC);
CREATE INDEX idx_payments_partner_bank_account ON lychee_erp.payments (partner_bank_account_id ASC);
CREATE INDEX idx_payments_internal_bank_account ON lychee_erp.payments (internal_bank_account_id ASC);
CREATE INDEX idx_payments_purpose ON lychee_erp.payments (tenant_id, company_id, payment_purpose, status);

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_partner
	FOREIGN KEY (partner_id) REFERENCES lychee_erp.business_partners (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_partner_bank_account
	FOREIGN KEY (partner_bank_account_id) REFERENCES lychee_erp.partner_bank_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_internal_bank_account
	FOREIGN KEY (internal_bank_account_id) REFERENCES lychee_erp.company_bank_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_journal_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_approved_by
	FOREIGN KEY (approved_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_posted_by
	FOREIGN KEY (posted_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_voided_by
	FOREIGN KEY (voided_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payments ADD CONSTRAINT fk_payments_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.payments.status
	IS 'DRAFT, PENDING_APPROVAL, APPROVED, POSTED, VOIDED';

COMMENT ON COLUMN lychee_erp.payments.payment_type
	IS 'RECEIPT (收款), DISBURSEMENT (付款)';

COMMENT ON COLUMN lychee_erp.payments.payment_purpose
	IS 'STANDARD, SUPPLIER_REFUND, CUSTOMER_REFUND';

COMMENT ON COLUMN lychee_erp.payments.unallocated_amount
	IS '未核销金额 (用于处理预收款/预付款)';

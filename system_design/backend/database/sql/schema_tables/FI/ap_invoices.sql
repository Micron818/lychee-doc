DROP TABLE IF EXISTS lychee_erp.ap_invoices CASCADE;

-- ==========================================
-- AP Invoices Header (应付发票主表)
-- ==========================================
CREATE TABLE lychee_erp.ap_invoices
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	code varchar(50) NOT NULL, --内部的单据流转 例如：AP-202606-0001
	external_invoice_no varchar(50) NOT NULL, -- 供应商开具的真实税务发票号
	invoice_date date NOT NULL,
	due_date date NOT NULL, -- MAX(ap_invoice_schedules.due_date); not a user-entered field
	payment_term_id bigint NOT NULL,
	base_date date NOT NULL,
	partner_id bigint NOT NULL,
	partner_code varchar(50) NOT NULL,
	partner_name varchar(100) NOT NULL,
	
	currency_option_id bigint NOT NULL,
	exchange_rate numeric(18,6) NOT NULL DEFAULT 1,
	subtotal_amount numeric(18,2) NOT NULL DEFAULT 0,
	tax_amount numeric(18,2) NOT NULL DEFAULT 0,
	total_amount numeric(18,2) NOT NULL DEFAULT 0,
	paid_amount numeric(18,2) NOT NULL DEFAULT 0,
	credited_amount numeric(18,2) NOT NULL DEFAULT 0,
	applied_credit_amount numeric(18,2) NOT NULL DEFAULT 0,
	remaining_amount numeric(18,2) NOT NULL DEFAULT 0,
	invoice_status varchar(20) NOT NULL DEFAULT 'DRAFT',    -- DRAFT, PENDING_APPROVAL, APPROVED, POSTED, VOIDED
	payment_status varchar(20) NOT NULL DEFAULT 'UNPAID',    -- UNPAID, PARTIAL, PAID
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

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT ap_invoices_pkey
	PRIMARY KEY (id);

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT uk_ap_invoices_tenant_code UNIQUE (tenant_id,company_id,code);

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT uk_ap_invoices_tenant_company_partner_invoice_no UNIQUE (tenant_id, company_id, partner_id, external_invoice_no);

CREATE INDEX idx_ap_invoices_due_date ON lychee_erp.ap_invoices (tenant_id,company_id, due_date);
CREATE INDEX idx_ap_invoices_status ON lychee_erp.ap_invoices (tenant_id,company_id, invoice_status );
CREATE INDEX idx_ap_invoices_partner ON lychee_erp.ap_invoices (partner_id ASC);
CREATE INDEX idx_ap_invoices_journal_entry ON lychee_erp.ap_invoices (journal_entry_id ASC);

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_partner
	FOREIGN KEY (partner_id) REFERENCES lychee_erp.business_partners (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_payment_term
	FOREIGN KEY (payment_term_id) REFERENCES lychee_erp.fi_payment_terms (id) ON DELETE No Action ON UPDATE No Action;

CREATE INDEX ix_ap_invoices_payment_term ON lychee_erp.ap_invoices (payment_term_id);

COMMENT ON COLUMN lychee_erp.ap_invoices.due_date
	IS 'MAX(invoice schedules.due_date); not a user-entered field';

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_journal_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_approved_by
	FOREIGN KEY (approved_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_posted_by
	FOREIGN KEY (posted_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_voided_by
	FOREIGN KEY (voided_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoices ADD CONSTRAINT fk_ap_invoices_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.ap_invoices.invoice_status
	IS 'DRAFT, PENDING_APPROVAL, APPROVED, POSTED, VOIDED';

COMMENT ON COLUMN lychee_erp.ap_invoices.payment_status
	IS 'UNPAID, PARTIAL, PAID';

COMMENT ON COLUMN lychee_erp.ap_invoices.credited_amount
	IS '已过账未作废应付贷项合计';

COMMENT ON COLUMN lychee_erp.ap_invoices.applied_credit_amount
	IS '已过账未作废贷项中实际冲减本票未付金额的合计';

COMMENT ON COLUMN lychee_erp.ap_invoices.remaining_amount
	IS 'remaining = total_amount − paid_amount − applied_credit_amount';



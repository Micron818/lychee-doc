DROP TABLE IF EXISTS lychee_erp.ap_credit_memos CASCADE;

-- ==========================================
-- AP Credit Memos Header (应付贷项主表)
-- ==========================================
CREATE TABLE lychee_erp.ap_credit_memos
(
	id                          bigserial       NOT NULL,
	tenant_id                   bigint          NOT NULL,
	company_id                  bigint          NOT NULL,
	code                        varchar(50)     NOT NULL,
	external_credit_note_no     varchar(50)     NOT NULL,
	original_ap_invoice_id      bigint          NOT NULL,
	credit_date                 date            NOT NULL,
	partner_id                  bigint          NOT NULL,
	partner_code                varchar(50)     NOT NULL,
	partner_name                varchar(100)    NOT NULL,
	currency_option_id          bigint          NOT NULL,
	exchange_rate               numeric(18,6)   NOT NULL DEFAULT 1,
	subtotal_amount             numeric(18,2)   NOT NULL DEFAULT 0,
	tax_amount                  numeric(18,2)   NOT NULL DEFAULT 0,
	total_amount                numeric(18,2)   NOT NULL DEFAULT 0,
	applied_amount              numeric(18,2)   NOT NULL DEFAULT 0,
	refundable_amount           numeric(18,2)   NOT NULL DEFAULT 0,
	applied_base_amount         numeric(18,2)   NOT NULL DEFAULT 0,
	refundable_base_amount      numeric(18,2)   NOT NULL DEFAULT 0,
	refunded_amount             numeric(18,2)   NOT NULL DEFAULT 0,
	refund_remaining_amount     numeric(18,2)   NOT NULL DEFAULT 0,
	refund_status               varchar(20)     NOT NULL DEFAULT 'NOT_REQUIRED',
	invoice_status              varchar(20)     NOT NULL DEFAULT 'DRAFT',
	journal_entry_id            bigint          NULL,
	approved_at                 timestamp       NULL,
	approved_by                 bigint          NULL,
	posted_at                   timestamp       NULL,
	posted_by                   bigint          NULL,
	voided_at                   timestamp       NULL,
	voided_by                   bigint          NULL,
	remarks                     text            NULL,
	created_at                  timestamp       NULL,
	updated_at                  timestamp       NULL,
	created_by                  bigint          NULL,
	updated_by                  bigint          NULL,
	CONSTRAINT pk_ap_credit_memos PRIMARY KEY (id),
	CONSTRAINT uk_ap_credit_memos_code UNIQUE (tenant_id, company_id, code),
	CONSTRAINT uk_ap_credit_memos_ext_no
		UNIQUE (tenant_id, company_id, partner_id, external_credit_note_no),
	CONSTRAINT ck_ap_credit_memos_applied_nonnegative CHECK (applied_amount >= 0),
	CONSTRAINT ck_ap_credit_memos_refundable_nonnegative CHECK (refundable_amount >= 0),
	CONSTRAINT ck_ap_credit_memos_applied_base_nonnegative CHECK (applied_base_amount >= 0),
	CONSTRAINT ck_ap_credit_memos_refundable_base_nonnegative CHECK (refundable_base_amount >= 0),
	CONSTRAINT ck_ap_credit_memos_refunded_range
		CHECK (refunded_amount >= 0 AND refunded_amount <= refundable_amount),
	CONSTRAINT ck_ap_credit_memos_refund_remaining_nonnegative CHECK (refund_remaining_amount >= 0)
);

CREATE INDEX idx_ap_credit_memos_original
	ON lychee_erp.ap_credit_memos (original_ap_invoice_id);
CREATE INDEX idx_ap_credit_memos_status
	ON lychee_erp.ap_credit_memos (tenant_id, company_id, invoice_status);
CREATE INDEX idx_ap_credit_memos_partner
	ON lychee_erp.ap_credit_memos (partner_id);
CREATE INDEX idx_ap_credit_memos_journal
	ON lychee_erp.ap_credit_memos (journal_entry_id);
CREATE INDEX idx_ap_credit_memos_date
	ON lychee_erp.ap_credit_memos (credit_date);
CREATE INDEX idx_ap_credit_memos_refundable
	ON lychee_erp.ap_credit_memos (tenant_id, company_id, partner_id, currency_option_id)
	WHERE invoice_status = 'POSTED' AND refund_remaining_amount > 0;

ALTER TABLE lychee_erp.ap_credit_memos
	ADD CONSTRAINT fk_ap_credit_memos_tenant
		FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.ap_credit_memos
	ADD CONSTRAINT fk_ap_credit_memos_company
		FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id);
ALTER TABLE lychee_erp.ap_credit_memos
	ADD CONSTRAINT fk_ap_credit_memos_original
		FOREIGN KEY (original_ap_invoice_id) REFERENCES lychee_erp.ap_invoices (id);
ALTER TABLE lychee_erp.ap_credit_memos
	ADD CONSTRAINT fk_ap_credit_memos_partner
		FOREIGN KEY (partner_id) REFERENCES lychee_erp.business_partners (id);
ALTER TABLE lychee_erp.ap_credit_memos
	ADD CONSTRAINT fk_ap_credit_memos_currency
		FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id);
ALTER TABLE lychee_erp.ap_credit_memos
	ADD CONSTRAINT fk_ap_credit_memos_journal
		FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id);

COMMENT ON TABLE lychee_erp.ap_credit_memos
	IS '应付贷项：一对一已过账应付发票；过账拆 applied/refundable，可再登记供应商退款';
COMMENT ON COLUMN lychee_erp.ap_credit_memos.invoice_status
	IS 'DRAFT, PENDING_APPROVAL, APPROVED, POSTED, VOIDED';
COMMENT ON COLUMN lychee_erp.ap_credit_memos.refund_status
	IS 'NOT_REQUIRED, UNREFUNDED, PARTIAL, REFUNDED';
COMMENT ON COLUMN lychee_erp.ap_credit_memos.applied_amount
	IS '过账时冲减原票未付的金额';
COMMENT ON COLUMN lychee_erp.ap_credit_memos.refundable_amount
	IS '过账时形成的待退款开放金额';
COMMENT ON COLUMN lychee_erp.ap_credit_memos.external_credit_note_no
	IS '供应商贷项号；草稿可用 PENDING- UUID 占位符';
COMMENT ON COLUMN lychee_erp.ap_credit_memos.journal_entry_id
	IS '本单凭证；VOID 后置空，不改原票 journal_entry_id';

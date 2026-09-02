DROP TABLE IF EXISTS lychee_erp.payment_lines CASCADE;

CREATE TABLE lychee_erp.payment_lines
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	payment_id bigint NOT NULL,
	line_no integer NOT NULL,
	
	allocation_type varchar(20) NOT NULL DEFAULT 'INVOICE', -- INVOICE, GL_ACCOUNT, PREPAYMENT, AP_CREDIT_MEMO
	
	-- 关联发票 / 贷项
	ar_invoice_id bigint NULL,
	ap_invoice_id bigint NULL,
	ap_credit_memo_id bigint NULL,
	ap_invoice_schedule_id bigint NULL,
	ar_invoice_schedule_id bigint NULL,
	applied_payment_id bigint NULL,         -- 关联被抵扣的历史预付款单
	
	-- 核销与折扣金额
	allocated_amount numeric(18,2) NOT NULL DEFAULT 0,      -- 本次核销金额
	discount_amount numeric(18,2) NOT NULL DEFAULT 0,       -- 现金折扣金额 (如提前付款享受折扣)
	
	-- 财务维度
	gl_account_id bigint NULL,                              -- 对应的应收/应付科目，或直接记账的费用科目
	department_id bigint NULL,                              -- 部门/成本中心 (用于直接记账的费用)
	journal_entry_id bigint NULL,                           -- 折扣 / GL_ACCOUNT 调整凭证，或供应商退款汇兑凭证
	source_exchange_rate numeric(18,6) NULL,                -- 退款核销行：贷项汇率快照
	source_base_amount numeric(18,2) NULL,
	settlement_base_amount numeric(18,2) NULL,
	exchange_difference_amount numeric(18,2) NULL,
	
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT payment_lines_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT uk_payment_lines UNIQUE (tenant_id,payment_id,line_no);

CREATE INDEX idx_payment_lines_payment ON lychee_erp.payment_lines (payment_id ASC);
CREATE INDEX idx_payment_lines_ar_invoice ON lychee_erp.payment_lines (ar_invoice_id ASC);
CREATE INDEX idx_payment_lines_ap_invoice ON lychee_erp.payment_lines (ap_invoice_id ASC);
CREATE INDEX idx_payment_lines_ap_credit_memo ON lychee_erp.payment_lines (ap_credit_memo_id ASC);
CREATE INDEX idx_payment_lines_gl_account ON lychee_erp.payment_lines (gl_account_id ASC);
CREATE INDEX idx_payment_lines_journal_entry ON lychee_erp.payment_lines (journal_entry_id ASC);

CREATE UNIQUE INDEX uk_payment_lines_payment_credit_memo
	ON lychee_erp.payment_lines (tenant_id, payment_id, ap_credit_memo_id)
	WHERE ap_credit_memo_id IS NOT NULL;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_payment
	FOREIGN KEY (payment_id) REFERENCES lychee_erp.payments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_ar_invoice
	FOREIGN KEY (ar_invoice_id) REFERENCES lychee_erp.ar_invoices (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_ap_invoice
	FOREIGN KEY (ap_invoice_id) REFERENCES lychee_erp.ap_invoices (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_ap_credit_memo
	FOREIGN KEY (ap_credit_memo_id) REFERENCES lychee_erp.ap_credit_memos (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_ap_schedule
	FOREIGN KEY (ap_invoice_schedule_id) REFERENCES lychee_erp.ap_invoice_schedules (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_ar_schedule
	FOREIGN KEY (ar_invoice_schedule_id) REFERENCES lychee_erp.ar_invoice_schedules (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_gl_account
	FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_department
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_applied_payment
	FOREIGN KEY (applied_payment_id) REFERENCES lychee_erp.payments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_journal_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.payment_lines.allocation_type
	IS 'INVOICE (核销发票), GL_ACCOUNT (直接记账), PREPAYMENT (核销预付款), AP_CREDIT_MEMO (供应商退款核销贷项)';

COMMENT ON COLUMN lychee_erp.payment_lines.ap_credit_memo_id
	IS '供应商退款核销的应付贷项；仅 allocation_type = AP_CREDIT_MEMO';

COMMENT ON COLUMN lychee_erp.payment_lines.journal_entry_id
	IS '折扣 / GL_ACCOUNT 调整凭证，或供应商退款汇兑凭证；无汇差则为 NULL';

COMMENT ON COLUMN lychee_erp.payment_lines.source_exchange_rate
	IS '退款核销行：贷项汇率快照';
COMMENT ON COLUMN lychee_erp.payment_lines.source_base_amount
	IS '退款核销行：按贷项汇率重乘的本位币';
COMMENT ON COLUMN lychee_erp.payment_lines.settlement_base_amount
	IS '退款核销行：按退款汇率重乘的本位币';
COMMENT ON COLUMN lychee_erp.payment_lines.exchange_difference_amount
	IS '退款核销行：settlement_base − source_base；无汇差为 0';

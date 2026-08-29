DROP TABLE IF EXISTS lychee_erp.payment_lines CASCADE;

CREATE TABLE lychee_erp.payment_lines
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	payment_id bigint NOT NULL,
	line_no integer NOT NULL,
	
	allocation_type varchar(20) NOT NULL DEFAULT 'INVOICE', -- INVOICE (核销发票), GL_ACCOUNT (直接记账,如手续费/汇兑损益), PREPAYMENT (核销预付款)
	
	-- 关联发票 (二选一)
	ar_invoice_id bigint NULL,
	ap_invoice_id bigint NULL,
	ap_invoice_schedule_id bigint NULL,
	ar_invoice_schedule_id bigint NULL,
	applied_payment_id bigint NULL,         -- 关联被抵扣的历史预付款单
	
	-- 核销与折扣金额
	allocated_amount numeric(18,2) NOT NULL DEFAULT 0,      -- 本次核销金额
	discount_amount numeric(18,2) NOT NULL DEFAULT 0,       -- 现金折扣金额 (如提前付款享受折扣)
	
	-- 财务维度
	gl_account_id bigint NULL,                              -- 对应的应收/应付科目，或直接记账的费用科目
	department_id bigint NULL,                              -- 部门/成本中心 (用于直接记账的费用)
	journal_entry_id bigint NULL,                           -- 折扣 / GL_ACCOUNT 调整凭证；纯 INVOICE 行为 NULL
	
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
CREATE INDEX idx_payment_lines_gl_account ON lychee_erp.payment_lines (gl_account_id ASC);
CREATE INDEX idx_payment_lines_journal_entry ON lychee_erp.payment_lines (journal_entry_id ASC);

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_payment
	FOREIGN KEY (payment_id) REFERENCES lychee_erp.payments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_ar_invoice
	FOREIGN KEY (ar_invoice_id) REFERENCES lychee_erp.ar_invoices (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.payment_lines ADD CONSTRAINT fk_payment_lines_ap_invoice
	FOREIGN KEY (ap_invoice_id) REFERENCES lychee_erp.ap_invoices (id) ON DELETE No Action ON UPDATE No Action;

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
	IS 'INVOICE (核销发票), GL_ACCOUNT (直接记账,如手续费/汇兑损益), PREPAYMENT (核销预付款)';

COMMENT ON COLUMN lychee_erp.payment_lines.journal_entry_id
	IS '折扣 / GL_ACCOUNT 核销调整凭证 journal_entries.id；纯 INVOICE 行为 NULL';

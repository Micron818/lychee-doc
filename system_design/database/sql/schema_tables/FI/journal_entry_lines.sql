DROP TABLE IF EXISTS lychee_erp.journal_entry_lines CASCADE;

CREATE TABLE lychee_erp.journal_entry_lines
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	journal_entry_id bigint NOT NULL,
	line_no integer NOT NULL,
	
	-- 科目与金额
	gl_account_id bigint NOT NULL,
	account_code varchar(50) NOT NULL,
	debit_amount numeric(18,2) NOT NULL DEFAULT 0,
	credit_amount numeric(18,2) NOT NULL DEFAULT 0,
	local_debit_amount numeric(18,2) NOT NULL DEFAULT 0,
	local_credit_amount numeric(18,2) NOT NULL DEFAULT 0,
	
	-- 辅助核算维度 (Subledger/Dimensions)
	department_id bigint NULL,             -- 部门/成本中心
	partner_type varchar(50) NULL,         -- CUSTOMER, SUPPLIER, EMPLOYEE
	partner_id bigint NULL,                -- 往来单位ID
	partner_code varchar(50) NULL,
	partner_name varchar(100) NULL,
	
	-- 来源单据追溯 (明细行级别)
	source_line_id bigint NULL,            -- 关联来源单据的明细行ID (如 ar_invoice_lines.id)
	
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.journal_entry_lines ADD CONSTRAINT journal_entry_lines_pkey
	PRIMARY KEY (id);

ALTER TABLE lychee_erp.journal_entry_lines ADD CONSTRAINT uk_journal_entry_lines UNIQUE (tenant_id,journal_entry_id,line_no);

CREATE INDEX idx_journal_entry_lines_account ON lychee_erp.journal_entry_lines (gl_account_id ASC);
CREATE INDEX idx_journal_entry_lines_entry ON lychee_erp.journal_entry_lines (journal_entry_id ASC);
CREATE INDEX idx_journal_entry_lines_department ON lychee_erp.journal_entry_lines (department_id ASC);
CREATE INDEX idx_journal_entry_lines_partner ON lychee_erp.journal_entry_lines (partner_type ASC, partner_id ASC);
CREATE INDEX idx_journal_entry_lines_source_line ON lychee_erp.journal_entry_lines (source_line_id ASC);

ALTER TABLE lychee_erp.journal_entry_lines ADD CONSTRAINT fk_journal_entry_lines_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entry_lines ADD CONSTRAINT fk_journal_entry_lines_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entry_lines ADD CONSTRAINT fk_journal_entry_lines_account
	FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entry_lines ADD CONSTRAINT fk_journal_entry_lines_department
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entry_lines ADD CONSTRAINT fk_journal_entry_lines_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.journal_entry_lines ADD CONSTRAINT fk_journal_entry_lines_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.journal_entry_lines.partner_type
	IS 'CUSTOMER, SUPPLIER, EMPLOYEE';

 

DROP TABLE IF EXISTS lychee_erp.stock_issues CASCADE
;

CREATE TABLE lychee_erp.stock_issues
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	issue_date date NOT NULL,
	department_id bigint NULL,
	issue_type varchar(20) NOT NULL,    -- PRODUCTION,PRODUCTION_REPORT,COST_CENTER,SCRAP,SAMPLE
	status varchar(20) NOT NULL,    -- DRAFT, POSTED, REVERSED
	journal_entry_id bigint NULL,   -- 发料成本结转凭证
	approved_by bigint NULL,
	remarks text NULL,
	approved_at timestamp without time zone NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.stock_issues ADD CONSTRAINT stock_issues_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.stock_issues ADD CONSTRAINT uk_stock_issues_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_stock_issues_date ON lychee_erp.stock_issues (issue_date ASC)
;

CREATE INDEX idx_stock_issues_department ON lychee_erp.stock_issues (department_id ASC)
;

ALTER TABLE lychee_erp.stock_issues ADD CONSTRAINT fk_stock_issues_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issues ADD CONSTRAINT fk_stock_issues_department
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issues ADD CONSTRAINT fk_stock_issues_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issues ADD CONSTRAINT fk_stock_issues_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issues ADD CONSTRAINT fk_stock_issues_journal_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action
;

CREATE INDEX idx_stock_issues_journal_entry ON lychee_erp.stock_issues (journal_entry_id ASC)
;

COMMENT ON COLUMN lychee_erp.stock_issues.issue_type
	IS 'PRODUCTION,PRODUCTION_REPORT,COST_CENTER,SCRAP,SAMPLE,SALES_DELIVERY'
;

COMMENT ON COLUMN lychee_erp.stock_issues.status
	IS 'DRAFT, POSTED, REVERSED'
;

COMMENT ON COLUMN lychee_erp.stock_issues.journal_entry_id
	IS '发料成本结转凭证 journal_entries.id'
;

 
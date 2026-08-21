
DROP TABLE IF EXISTS lychee_erp.stock_return_items CASCADE
;

DROP TABLE IF EXISTS lychee_erp.stock_returns CASCADE
;

DROP TABLE IF EXISTS lychee_erp.stock_issue_returns CASCADE
;

CREATE TABLE lychee_erp.stock_issue_returns
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	return_date date NOT NULL,
	department_id bigint NULL,
	original_stock_issue_id bigint NOT NULL,
	return_type varchar(20) NOT NULL,    -- PRODUCTION,COST_CENTER,SAMPLE
	status varchar(20) NOT NULL,    -- DRAFT, POSTED, REVERSED
	approved_by bigint NULL,
	approved_at timestamp without time zone NULL,
	remarks text NULL,
	journal_entry_id bigint NULL,   -- 退料成本冲回凭证
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.stock_issue_returns ADD CONSTRAINT pk_stock_issue_returns
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.stock_issue_returns ADD CONSTRAINT uk_stock_issue_returns UNIQUE (tenant_id,code)
;

CREATE INDEX idx_stock_issue_returns_date ON lychee_erp.stock_issue_returns (return_date ASC)
;

CREATE INDEX idx_stock_issue_returns_department ON lychee_erp.stock_issue_returns (department_id ASC)
;

CREATE INDEX idx_stock_issue_returns_original_issue ON lychee_erp.stock_issue_returns (original_stock_issue_id ASC)
;

CREATE INDEX idx_stock_issue_returns_journal_entry ON lychee_erp.stock_issue_returns (journal_entry_id ASC)
;

ALTER TABLE lychee_erp.stock_issue_returns ADD CONSTRAINT fk_stock_issue_returns_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_returns ADD CONSTRAINT fk_stock_issue_returns_department
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_returns ADD CONSTRAINT fk_stock_issue_returns_original_issue
	FOREIGN KEY (original_stock_issue_id) REFERENCES lychee_erp.stock_issues (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_returns ADD CONSTRAINT fk_stock_issue_returns_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_returns ADD CONSTRAINT fk_stock_issue_returns_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_issue_returns ADD CONSTRAINT fk_stock_issue_returns_journal_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.stock_issue_returns.original_stock_issue_id
	IS '一张退料单只对应一张已过账领料单 stock_issues.id'
;

COMMENT ON COLUMN lychee_erp.stock_issue_returns.return_type
	IS 'PRODUCTION,COST_CENTER,SAMPLE'
;

COMMENT ON COLUMN lychee_erp.stock_issue_returns.status
	IS 'DRAFT, POSTED, REVERSED'
;

COMMENT ON COLUMN lychee_erp.stock_issue_returns.journal_entry_id
	IS '退料成本冲回凭证 journal_entries.id；不回写原领料单 journal_entry_id'
;


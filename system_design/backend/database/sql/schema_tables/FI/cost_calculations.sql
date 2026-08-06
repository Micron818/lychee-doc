DROP TABLE IF EXISTS lychee_erp.cost_calculations CASCADE;

CREATE TABLE lychee_erp.cost_calculations
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	fiscal_period_id bigint NOT NULL,
	inventory_period_id bigint NULL,              -- 關聯 WM 庫存期間 (重開帳時可標記失效)
	run_no varchar(50) NOT NULL,
	run_date timestamp without time zone NOT NULL DEFAULT now(),
	cost_method varchar(30) NOT NULL,             -- STANDARD_COST, MOVING_AVERAGE, ACTUAL_COST
	description text NULL,
	status varchar(20) NOT NULL DEFAULT 'DRAFT', -- DRAFT, FINALIZED, POSTED, INVALIDATED
	is_posted boolean NOT NULL DEFAULT false,     -- 與 status=POSTED 同步的派生欄位
	journal_entry_id bigint NULL,
	posted_at timestamp without time zone NULL,
	posted_by bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT cost_calculations_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT uk_cost_calculations_run UNIQUE (tenant_id, company_id, fiscal_period_id, run_no);

CREATE INDEX idx_cost_calculations_period ON lychee_erp.cost_calculations (tenant_id ASC, company_id ASC, fiscal_period_id ASC);
CREATE INDEX idx_cost_calculations_status ON lychee_erp.cost_calculations (status ASC);
CREATE INDEX idx_cost_calculations_inventory_period ON lychee_erp.cost_calculations (inventory_period_id ASC);
CREATE INDEX idx_cost_calculations_journal_entry ON lychee_erp.cost_calculations (journal_entry_id ASC);

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT fk_cost_calculations_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT fk_cost_calculations_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT fk_cost_calculations_period
	FOREIGN KEY (fiscal_period_id) REFERENCES lychee_erp.fiscal_periods (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT fk_cost_calculations_inventory_period
	FOREIGN KEY (inventory_period_id) REFERENCES lychee_erp.inventory_periods (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT fk_cost_calculations_journal_entry
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT fk_cost_calculations_posted_by
	FOREIGN KEY (posted_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT fk_cost_calculations_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculations ADD CONSTRAINT fk_cost_calculations_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.cost_calculations.cost_method
	IS 'STANDARD_COST, MOVING_AVERAGE, ACTUAL_COST';

COMMENT ON COLUMN lychee_erp.cost_calculations.status
	IS 'DRAFT, FINALIZED, POSTED, INVALIDATED';

COMMENT ON COLUMN lychee_erp.cost_calculations.is_posted
	IS 'Derived flag synced with status=POSTED';

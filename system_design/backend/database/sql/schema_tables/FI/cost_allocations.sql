DROP TABLE IF EXISTS lychee_erp.cost_allocations CASCADE;

CREATE TABLE lychee_erp.cost_allocations
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	cost_calculation_id bigint NOT NULL,
	fiscal_period_id bigint NOT NULL,
	source_department_id bigint NULL,  -- 費用來源部門 (如: 廠務部)
	target_department_id bigint NOT NULL, -- 費用分攤部門 (如: 生產一部)
	gl_account_id bigint NOT NULL,     -- 費用科目 (如: 電費)
	amount numeric(18,2) NOT NULL,   -- 分攤金額
	cost_element varchar(30) NOT NULL DEFAULT 'OVERHEAD', -- LABOR, OVERHEAD
	allocation_basis varchar(50) NULL, -- HEADCOUNT, FLOOR_AREA, MACHINE_HOURS
	basis_quantity numeric(18,6) NULL,
	allocation_ratio numeric(8,6) NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT cost_allocations_pkey PRIMARY KEY (id);

CREATE INDEX idx_cost_allocations_calculation ON lychee_erp.cost_allocations (cost_calculation_id ASC);
CREATE INDEX idx_cost_allocations_period ON lychee_erp.cost_allocations (tenant_id ASC, company_id ASC, fiscal_period_id ASC);
CREATE INDEX idx_cost_allocations_source ON lychee_erp.cost_allocations (source_department_id ASC);
CREATE INDEX idx_cost_allocations_target ON lychee_erp.cost_allocations (target_department_id ASC);

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT fk_cost_allocations_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT fk_cost_allocations_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT fk_cost_allocations_calculation
	FOREIGN KEY (cost_calculation_id) REFERENCES lychee_erp.cost_calculations (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT fk_cost_allocations_period
	FOREIGN KEY (fiscal_period_id) REFERENCES lychee_erp.fiscal_periods (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT fk_cost_allocations_source
	FOREIGN KEY (source_department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT fk_cost_allocations_target
	FOREIGN KEY (target_department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT fk_cost_allocations_account
	FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT fk_cost_allocations_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_allocations ADD CONSTRAINT fk_cost_allocations_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.cost_allocations.cost_element
	IS 'LABOR, OVERHEAD — absorbed into laborCost / overheadCost on cost run complete';

COMMENT ON COLUMN lychee_erp.cost_allocations.allocation_basis
	IS 'HEADCOUNT, FLOOR_AREA, MACHINE_HOURS';

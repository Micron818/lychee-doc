DROP TABLE IF EXISTS lychee_erp.fi_costing_policies CASCADE;

CREATE TABLE lychee_erp.fi_costing_policies
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	default_cost_method varchar(30) NOT NULL DEFAULT 'STANDARD_COST',
	variance_settlement varchar(30) NOT NULL DEFAULT 'FULL_TO_PL',
	oh_absorption_basis varchar(30) NOT NULL DEFAULT 'LABOR_HOURS',
	require_posted_cost_run_on_close boolean NOT NULL DEFAULT false,
	require_standard_cost_on_stock_post boolean NOT NULL DEFAULT true,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.fi_costing_policies ADD CONSTRAINT fi_costing_policies_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.fi_costing_policies ADD CONSTRAINT uk_fi_costing_policies_company
	UNIQUE (tenant_id, company_id);

CREATE INDEX idx_fi_costing_policies_company ON lychee_erp.fi_costing_policies (tenant_id ASC, company_id ASC);

ALTER TABLE lychee_erp.fi_costing_policies ADD CONSTRAINT fk_fi_costing_policies_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_costing_policies ADD CONSTRAINT fk_fi_costing_policies_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_costing_policies ADD CONSTRAINT fk_fi_costing_policies_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_costing_policies ADD CONSTRAINT fk_fi_costing_policies_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.fi_costing_policies.default_cost_method
	IS 'STANDARD_COST (daily valuation), MOVING_AVERAGE (future), ACTUAL_COST (month-end snapshot only)';

COMMENT ON COLUMN lychee_erp.fi_costing_policies.variance_settlement
	IS 'FULL_TO_PL: settle variances fully to P&L';

COMMENT ON COLUMN lychee_erp.fi_costing_policies.oh_absorption_basis
	IS 'LABOR_HOURS, MACHINE_HOURS, OUTPUT_QTY, MATERIAL_COST';

COMMENT ON COLUMN lychee_erp.fi_costing_policies.require_posted_cost_run_on_close
	IS 'When true, fiscal period close requires a posted cost calculation for the period';

COMMENT ON COLUMN lychee_erp.fi_costing_policies.require_standard_cost_on_stock_post
	IS 'When true, stock post requires active standard unit cost > 0 and posts inventory valuation journals. When false, quantity-only: unit_cost=0 allowed, skip inventory valuation journals, Cost Run disallowed.';

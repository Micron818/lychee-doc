DROP TABLE IF EXISTS lychee_erp.material_costs CASCADE;

CREATE TABLE lychee_erp.material_costs
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	material_id bigint NOT NULL,
	fiscal_period_id bigint NOT NULL,  -- 成本期間
	cost_calculation_id bigint NULL,   -- 來源成本結算作業 (手工維護標準成本可為 NULL)
	cost_method varchar(30) NOT NULL,  -- STANDARD_COST, MOVING_AVERAGE, ACTUAL_COST
	unit_cost numeric(18,6) NOT NULL,  -- 單位成本 (料+工+費)
	material_cost numeric(18,6) NOT NULL DEFAULT 0, -- 料
	labor_cost numeric(18,6) NOT NULL DEFAULT 0,    -- 工
	overhead_cost numeric(18,6) NOT NULL DEFAULT 0, -- 費
	is_active boolean NOT NULL DEFAULT true,
	calculated_at timestamp without time zone NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.material_costs ADD CONSTRAINT material_costs_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.material_costs ADD CONSTRAINT uk_material_costs UNIQUE (tenant_id, company_id, material_id, fiscal_period_id, cost_method);

CREATE INDEX idx_material_costs_company ON lychee_erp.material_costs (tenant_id ASC, company_id ASC);
CREATE INDEX idx_material_costs_material ON lychee_erp.material_costs (material_id ASC);
CREATE INDEX idx_material_costs_period ON lychee_erp.material_costs (fiscal_period_id ASC);
CREATE INDEX idx_material_costs_calculation ON lychee_erp.material_costs (cost_calculation_id ASC);

ALTER TABLE lychee_erp.material_costs ADD CONSTRAINT fk_material_costs_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_costs ADD CONSTRAINT fk_material_costs_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_costs ADD CONSTRAINT fk_material_costs_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_costs ADD CONSTRAINT fk_material_costs_period
	FOREIGN KEY (fiscal_period_id) REFERENCES lychee_erp.fiscal_periods (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_costs ADD CONSTRAINT fk_material_costs_calculation
	FOREIGN KEY (cost_calculation_id) REFERENCES lychee_erp.cost_calculations (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_costs ADD CONSTRAINT fk_material_costs_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.material_costs ADD CONSTRAINT fk_material_costs_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.material_costs.cost_method
	IS 'STANDARD_COST, MOVING_AVERAGE, ACTUAL_COST';

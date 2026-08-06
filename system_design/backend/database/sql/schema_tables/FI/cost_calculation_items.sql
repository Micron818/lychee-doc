DROP TABLE IF EXISTS lychee_erp.cost_calculation_items CASCADE;

CREATE TABLE lychee_erp.cost_calculation_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	cost_calculation_id bigint NOT NULL,
	material_id bigint NOT NULL,

	opening_qty numeric(18,6) NOT NULL DEFAULT 0,
	receipt_qty numeric(18,6) NOT NULL DEFAULT 0,
	issue_qty numeric(18,6) NOT NULL DEFAULT 0,
	closing_qty numeric(18,6) NOT NULL DEFAULT 0,

	opening_stock_value numeric(18,2) NOT NULL DEFAULT 0,
	receipt_value numeric(18,2) NOT NULL DEFAULT 0,
	issue_value numeric(18,2) NOT NULL DEFAULT 0,
	closing_stock_value numeric(18,2) NOT NULL DEFAULT 0,

	calculated_unit_cost numeric(18,6) NOT NULL, -- 計算出的本期單位成本
	standard_unit_cost numeric(18,6) NOT NULL DEFAULT 0, -- startRun 凍結的標準單價快照
	material_cost numeric(18,6) NOT NULL DEFAULT 0, -- 料
	labor_cost numeric(18,6) NOT NULL DEFAULT 0,    -- 工
	overhead_cost numeric(18,6) NOT NULL DEFAULT 0, -- 費
	variance_amount numeric(18,2) NOT NULL DEFAULT 0, -- 成本差異 (標準 vs 實際)
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.cost_calculation_items ADD CONSTRAINT cost_calculation_items_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.cost_calculation_items ADD CONSTRAINT uk_cost_calc_items_run_material UNIQUE (cost_calculation_id, material_id);

CREATE INDEX idx_cost_calc_items_run ON lychee_erp.cost_calculation_items (cost_calculation_id ASC);
CREATE INDEX idx_cost_calc_items_material ON lychee_erp.cost_calculation_items (material_id ASC);

ALTER TABLE lychee_erp.cost_calculation_items ADD CONSTRAINT fk_cost_calc_items_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculation_items ADD CONSTRAINT fk_cost_calc_items_run
	FOREIGN KEY (cost_calculation_id) REFERENCES lychee_erp.cost_calculations (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculation_items ADD CONSTRAINT fk_cost_calc_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculation_items ADD CONSTRAINT fk_cost_calc_items_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.cost_calculation_items ADD CONSTRAINT fk_cost_calc_items_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

DROP TABLE IF EXISTS lychee_erp.fixed_assets CASCADE;

CREATE TABLE lychee_erp.fixed_assets
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	asset_category_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	acquisition_date date NOT NULL,
	start_depreciation_date date NOT NULL,
	original_value numeric(18,2) NOT NULL,
	salvage_value numeric(18,2) NOT NULL DEFAULT 0, -- 殘值
	current_value numeric(18,2) NOT NULL,           -- 帳面價值 (Book Value)
	accumulated_depreciation numeric(18,2) NOT NULL DEFAULT 0, -- 累計折舊

	-- 卡片級覆寫 (NULL 則沿用 asset_categories 預設)
	depreciation_method varchar(30) NULL,
	useful_life_months integer NULL,

	location varchar(100) NULL,
	department_id bigint NULL,                      -- 保管/歸屬部門
	custodian_id bigint NULL,                       -- 保管人 (User)
	status varchar(20) NOT NULL DEFAULT 'ACTIVE',   -- ACTIVE, DISPOSED, SOLD, FULLY_DEPRECIATED

	-- 取得/处置憑證
	acquisition_currency_id bigint NULL,           -- 取得交易原始币别 (FK option_values)
	acquisition_exchange_rate numeric(18,6) NULL, -- 取得日汇率 (原币 -> 本位币)
	acquisition_amount_txn numeric(18,2) NULL,     -- 取得交易原币金额
	acquisition_journal_entry_id bigint NULL,

	-- AP 联动作来源（手动从 AP 行生成；1 行 N 卡）
	ap_invoice_id bigint NULL,
	ap_invoice_line_id bigint NULL,
	split_no integer NULL,

	disposal_date date NULL,
	disposal_amount numeric(18,2) NULL,
	disposal_gain_loss numeric(18,2) NULL,
	disposal_journal_entry_id bigint NULL,
	disposed_at timestamp without time zone NULL,
	disposed_by bigint NULL,

	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fixed_assets_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT uk_fixed_assets_tenant_company_code UNIQUE (tenant_id, company_id, code);

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT uk_fixed_assets_ap_invoice_line_split UNIQUE (tenant_id, ap_invoice_line_id, split_no);

CREATE INDEX idx_fixed_assets_company ON lychee_erp.fixed_assets (tenant_id ASC, company_id ASC);
CREATE INDEX idx_fixed_assets_category ON lychee_erp.fixed_assets (asset_category_id ASC);
CREATE INDEX idx_fixed_assets_department ON lychee_erp.fixed_assets (department_id ASC);
CREATE INDEX idx_fixed_assets_status ON lychee_erp.fixed_assets (status ASC);
CREATE INDEX idx_fixed_assets_ap_invoice ON lychee_erp.fixed_assets (tenant_id ASC, ap_invoice_id ASC);
CREATE INDEX idx_fixed_assets_ap_invoice_line ON lychee_erp.fixed_assets (ap_invoice_line_id ASC);

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_category
	FOREIGN KEY (asset_category_id) REFERENCES lychee_erp.asset_categories (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_department
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_custodian
	FOREIGN KEY (custodian_id) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_acquisition_currency
	FOREIGN KEY (acquisition_currency_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_acquisition_je
	FOREIGN KEY (acquisition_journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_ap_invoice
	FOREIGN KEY (ap_invoice_id) REFERENCES lychee_erp.ap_invoices (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_ap_invoice_line
	FOREIGN KEY (ap_invoice_line_id) REFERENCES lychee_erp.ap_invoice_lines (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_disposal_je
	FOREIGN KEY (disposal_journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_disposed_by
	FOREIGN KEY (disposed_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fixed_assets ADD CONSTRAINT fk_fixed_assets_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.fixed_assets.status
	IS 'ACTIVE, DISPOSED, SOLD, FULLY_DEPRECIATED';

COMMENT ON COLUMN lychee_erp.fixed_assets.depreciation_method
	IS 'STRAIGHT_LINE, DECLINING_BALANCE; NULL 表示沿用 asset_categories';

COMMENT ON COLUMN lychee_erp.fixed_assets.original_value
	IS '以资产所属公司本位币 (companies.local_currency_id) 记账，非交易原币';

COMMENT ON COLUMN lychee_erp.fixed_assets.salvage_value
	IS '以资产所属公司本位币 (companies.local_currency_id) 记账，非交易原币';

COMMENT ON COLUMN lychee_erp.fixed_assets.current_value
	IS '以资产所属公司本位币 (companies.local_currency_id) 记账，非交易原币';

COMMENT ON COLUMN lychee_erp.fixed_assets.accumulated_depreciation
	IS '以资产所属公司本位币 (companies.local_currency_id) 记账，非交易原币';

COMMENT ON COLUMN lychee_erp.fixed_assets.disposal_amount
	IS '以资产所属公司本位币 (companies.local_currency_id) 记账，非交易原币';

COMMENT ON COLUMN lychee_erp.fixed_assets.disposal_gain_loss
	IS '以资产所属公司本位币 (companies.local_currency_id) 记账，非交易原币';

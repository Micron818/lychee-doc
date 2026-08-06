DROP TABLE IF EXISTS lychee_erp.asset_depreciations CASCADE;

CREATE TABLE lychee_erp.asset_depreciations
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	fixed_asset_id bigint NOT NULL,
	fiscal_period_id bigint NOT NULL,
	depreciation_date date NOT NULL,
	depreciation_amount numeric(18,2) NOT NULL,
	accumulated_depreciation_after numeric(18,2) NOT NULL, -- 本期計提後累計折舊
	status varchar(20) NOT NULL DEFAULT 'DRAFT',          -- DRAFT, POSTED, VOIDED
	journal_entry_id bigint NULL,                         -- 關聯產生的折舊傳票
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.asset_depreciations ADD CONSTRAINT asset_depreciations_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.asset_depreciations ADD CONSTRAINT uk_asset_depreciations_asset_period UNIQUE (tenant_id, fixed_asset_id, fiscal_period_id);

CREATE INDEX idx_asset_depreciations_asset ON lychee_erp.asset_depreciations (fixed_asset_id ASC);
CREATE INDEX idx_asset_depreciations_period ON lychee_erp.asset_depreciations (tenant_id ASC, fiscal_period_id ASC);
CREATE INDEX idx_asset_depreciations_company ON lychee_erp.asset_depreciations (tenant_id ASC, company_id ASC);
CREATE INDEX idx_asset_depreciations_journal_entry ON lychee_erp.asset_depreciations (journal_entry_id ASC);

ALTER TABLE lychee_erp.asset_depreciations ADD CONSTRAINT fk_asset_depreciations_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_depreciations ADD CONSTRAINT fk_asset_depreciations_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_depreciations ADD CONSTRAINT fk_asset_depreciations_asset
	FOREIGN KEY (fixed_asset_id) REFERENCES lychee_erp.fixed_assets (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_depreciations ADD CONSTRAINT fk_asset_depreciations_period
	FOREIGN KEY (fiscal_period_id) REFERENCES lychee_erp.fiscal_periods (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_depreciations ADD CONSTRAINT fk_asset_depreciations_je
	FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_depreciations ADD CONSTRAINT fk_asset_depreciations_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_depreciations ADD CONSTRAINT fk_asset_depreciations_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.asset_depreciations.status
	IS 'DRAFT, POSTED, VOIDED';

COMMENT ON COLUMN lychee_erp.asset_depreciations.depreciation_amount
	IS '以资产所属公司本位币 (companies.local_currency_id) 记账，非交易原币';

COMMENT ON COLUMN lychee_erp.asset_depreciations.accumulated_depreciation_after
	IS '以资产所属公司本位币 (companies.local_currency_id) 记账，非交易原币';

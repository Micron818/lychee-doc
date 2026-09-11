DROP TABLE IF EXISTS lychee_erp.asset_categories CASCADE;

CREATE TABLE lychee_erp.asset_categories
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	depreciation_method varchar(30) NOT NULL, -- STRAIGHT_LINE, DECLINING_BALANCE
	useful_life_months integer NOT NULL,
	depreciation_rate numeric(5,4) NULL,      -- 餘額遞減法使用；直線法可為 NULL
	salvage_rate numeric(5,4) NULL,           -- 類別預設殘值率
	asset_account_id bigint NOT NULL,              -- 資產科目 (GL)
	depreciation_account_id bigint NOT NULL,       -- 折舊費用科目 (GL)
	accumulated_depreciation_account_id bigint NOT NULL, -- 累計折舊科目 (GL)
	disposal_gain_loss_account_id bigint NULL,     -- 資產處置損益科目 (GL)
	is_active boolean NOT NULL DEFAULT true,
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.asset_categories ADD CONSTRAINT asset_categories_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.asset_categories ADD CONSTRAINT uk_asset_categories_tenant_code UNIQUE (tenant_id, code);

ALTER TABLE lychee_erp.asset_categories ADD CONSTRAINT fk_asset_categories_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_categories ADD CONSTRAINT fk_asset_categories_asset_acct
	FOREIGN KEY (asset_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_categories ADD CONSTRAINT fk_asset_categories_depr_acct
	FOREIGN KEY (depreciation_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_categories ADD CONSTRAINT fk_asset_categories_acc_depr_acct
	FOREIGN KEY (accumulated_depreciation_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_categories ADD CONSTRAINT fk_asset_categories_disposal_gl_acct
	FOREIGN KEY (disposal_gain_loss_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_categories ADD CONSTRAINT fk_asset_categories_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.asset_categories ADD CONSTRAINT fk_asset_categories_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.asset_categories.depreciation_method
	IS 'STRAIGHT_LINE, DECLINING_BALANCE';

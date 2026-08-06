DROP TABLE IF EXISTS lychee_erp.company_bank_accounts CASCADE;

CREATE TABLE lychee_erp.company_bank_accounts
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,             -- 归属公司 (FK companies)

	account_code varchar(50) NOT NULL,      -- 内部编码
	account_name varchar(100) NOT NULL,     -- 显示名称
	account_type varchar(20) NOT NULL,      -- BANK (银行账户), CASH (现金/备用金)

	bank_name varchar(100) NULL,            -- 银行名称 (BANK 必填)
	bank_branch varchar(100) NULL,          -- 支行/分行名称
	account_no varchar(50) NULL,            -- 银行账号 (BANK 必填)
	account_holder varchar(100) NULL,       -- 账户户名

	currency_option_id bigint NOT NULL,     -- 账户币种
	gl_account_id bigint NOT NULL,          -- 对应银行/现金 GL 科目 (过账子分类账)

	is_default boolean NOT NULL DEFAULT false, -- 是否为该公司该币种的默认账户
	status varchar(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE

	swift_code varchar(20) NULL,            -- SWIFT / BIC (银企直联可选)
	bank_code varchar(20) NULL,             -- 联行号等 (银企直联可选)

	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.company_bank_accounts ADD CONSTRAINT company_bank_accounts_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.company_bank_accounts ADD CONSTRAINT uk_company_bank_accounts_code UNIQUE (tenant_id, company_id, account_code);

CREATE INDEX idx_company_bank_accounts_company ON lychee_erp.company_bank_accounts (tenant_id ASC, company_id ASC);
CREATE INDEX idx_company_bank_accounts_gl_account ON lychee_erp.company_bank_accounts (gl_account_id ASC);

ALTER TABLE lychee_erp.company_bank_accounts ADD CONSTRAINT fk_company_bank_accounts_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.company_bank_accounts ADD CONSTRAINT fk_company_bank_accounts_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.company_bank_accounts ADD CONSTRAINT fk_company_bank_accounts_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.company_bank_accounts ADD CONSTRAINT fk_company_bank_accounts_gl_account
	FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.company_bank_accounts ADD CONSTRAINT fk_company_bank_accounts_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.company_bank_accounts ADD CONSTRAINT fk_company_bank_accounts_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.company_bank_accounts.account_type
	IS 'BANK (银行账户), CASH (现金/备用金)';

COMMENT ON COLUMN lychee_erp.company_bank_accounts.status
	IS 'ACTIVE, INACTIVE';

DROP TABLE IF EXISTS lychee_erp.partner_bank_accounts CASCADE;

CREATE TABLE lychee_erp.partner_bank_accounts
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	partner_id bigint NOT NULL,             -- 关联 FI.business_partners.id
	
	bank_name varchar(100) NOT NULL,        -- 银行名称 (如: 招商银行)
	bank_branch varchar(100) NULL,          -- 支行/分行名称
	account_no varchar(50) NOT NULL,        -- 银行账号
	account_name varchar(100) NOT NULL,     -- 账户户名
	
	currency_option_id bigint NULL,         -- 账户币种
	is_default boolean NOT NULL DEFAULT false, -- 是否为默认收款账户
	status varchar(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE
	
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.partner_bank_accounts ADD CONSTRAINT partner_bank_accounts_pkey PRIMARY KEY (id);

CREATE INDEX idx_partner_bank_accounts_partner ON lychee_erp.partner_bank_accounts (partner_id ASC);

ALTER TABLE lychee_erp.partner_bank_accounts ADD CONSTRAINT fk_partner_bank_accounts_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.partner_bank_accounts ADD CONSTRAINT fk_partner_bank_accounts_partner
	FOREIGN KEY (partner_id) REFERENCES lychee_erp.business_partners (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.partner_bank_accounts ADD CONSTRAINT fk_partner_bank_accounts_currency
	FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.partner_bank_accounts ADD CONSTRAINT fk_partner_bank_accounts_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.partner_bank_accounts ADD CONSTRAINT fk_partner_bank_accounts_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

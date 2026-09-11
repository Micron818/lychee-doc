DROP TABLE IF EXISTS lychee_erp.business_partners CASCADE;

CREATE TABLE lychee_erp.business_partners
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	partner_type varchar(50) NOT NULL,      -- CUSTOMER, SUPPLIER
	source_id bigint NOT NULL,              -- 关联 SCM.suppliers.id 或 SD.customers.id
	
	-- 基础信息（从 SCM/SD 异步同步过来的副本，FI 模组只读）
	partner_code varchar(50) NOT NULL,
	partner_name varchar(100) NOT NULL,
	tax_id varchar(50) NULL,
	
	-- 财务属性（FI 模组独有，财务人员维护）
	gl_account_id bigint NULL,              -- 默认的应收/应付统驭科目
	payment_term_id bigint NULL,            -- 财务核准的付款条件（FK fi_payment_terms）
	credit_limit numeric(18,2) NULL,        -- 信用额度
	status varchar(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE
	
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.business_partners ADD CONSTRAINT business_partners_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.business_partners ADD CONSTRAINT uk_business_partners_source UNIQUE (tenant_id, partner_type, source_id);

CREATE INDEX idx_business_partners_code ON lychee_erp.business_partners (tenant_id ASC, partner_code ASC);

ALTER TABLE lychee_erp.business_partners ADD CONSTRAINT fk_business_partners_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.business_partners ADD CONSTRAINT fk_business_partners_gl_account
	FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.business_partners ADD CONSTRAINT fk_business_partners_payment_term
	FOREIGN KEY (payment_term_id) REFERENCES lychee_erp.fi_payment_terms (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.business_partners ADD CONSTRAINT fk_business_partners_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.business_partners ADD CONSTRAINT fk_business_partners_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.business_partners.partner_type
	IS 'CUSTOMER, SUPPLIER';

COMMENT ON COLUMN lychee_erp.business_partners.status
	IS 'ACTIVE, INACTIVE';
DROP TABLE IF EXISTS lychee_erp.fi_account_determination CASCADE;

CREATE TABLE lychee_erp.fi_account_determination
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NULL,
	posting_key varchar(30) NOT NULL,
	valuation_class_id bigint NULL,
	gl_account_id bigint NOT NULL,
	is_active boolean NOT NULL DEFAULT true,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.fi_account_determination ADD CONSTRAINT fi_account_determination_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX uk_fi_account_determination
	ON lychee_erp.fi_account_determination (
		tenant_id,
		COALESCE(company_id, 0),
		posting_key,
		COALESCE(valuation_class_id, 0)
	);

CREATE INDEX idx_fi_account_determination_company ON lychee_erp.fi_account_determination (company_id ASC);
CREATE INDEX idx_fi_account_determination_posting_key ON lychee_erp.fi_account_determination (posting_key ASC);
CREATE INDEX idx_fi_account_determination_valuation_class ON lychee_erp.fi_account_determination (valuation_class_id ASC);
CREATE INDEX idx_fi_account_determination_gl_account ON lychee_erp.fi_account_determination (gl_account_id ASC);

ALTER TABLE lychee_erp.fi_account_determination ADD CONSTRAINT fk_fi_account_determination_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_account_determination ADD CONSTRAINT fk_fi_account_determination_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_account_determination ADD CONSTRAINT fk_fi_account_determination_valuation_class
	FOREIGN KEY (valuation_class_id) REFERENCES lychee_erp.valuation_classes (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_account_determination ADD CONSTRAINT fk_fi_account_determination_gl_account
	FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_account_determination ADD CONSTRAINT fk_fi_account_determination_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_account_determination ADD CONSTRAINT fk_fi_account_determination_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON TABLE lychee_erp.fi_account_determination IS '科目判定：company + posting_key + valuation_class → gl_account';
COMMENT ON COLUMN lychee_erp.fi_account_determination.company_id IS 'NULL = 租户默认；有值 = 公司覆盖';
COMMENT ON COLUMN lychee_erp.fi_account_determination.valuation_class_id IS 'NULL = 通配（不区分评估类）';
COMMENT ON COLUMN lychee_erp.fi_account_determination.posting_key IS 'INV_STOCK, GRIR, INPUT_TAX, OUTPUT_TAX, EXPENSE, REVENUE, COGS, WIP, PRICE_VAR, EXCHANGE_DIFF, CIP';

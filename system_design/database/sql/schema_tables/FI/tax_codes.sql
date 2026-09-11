DROP TABLE IF EXISTS lychee_erp.tax_codes CASCADE;

CREATE TABLE lychee_erp.tax_codes
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	country_code varchar(2) NOT NULL,
	direction varchar(20) NOT NULL,
	tax_type varchar(20) NOT NULL,
	is_deductible boolean NOT NULL DEFAULT true,
	input_gl_account_id bigint NULL,
	output_gl_account_id bigint NULL,
	is_active boolean NOT NULL DEFAULT true,
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.tax_codes ADD CONSTRAINT pk_tax_codes PRIMARY KEY (id);

ALTER TABLE lychee_erp.tax_codes ADD CONSTRAINT uk_tax_codes UNIQUE (tenant_id, code);

CREATE INDEX ix_tax_codes_country ON lychee_erp.tax_codes (tenant_id, country_code, direction);

ALTER TABLE lychee_erp.tax_codes ADD CONSTRAINT fk_tax_codes_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_codes ADD CONSTRAINT fk_tax_codes_input_gl
	FOREIGN KEY (input_gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_codes ADD CONSTRAINT fk_tax_codes_output_gl
	FOREIGN KEY (output_gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_codes ADD CONSTRAINT fk_tax_codes_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_codes ADD CONSTRAINT fk_tax_codes_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON TABLE lychee_erp.tax_codes IS '税码：税务身份、方向、税种与税行科目覆盖';
COMMENT ON COLUMN lychee_erp.tax_codes.direction IS 'INPUT | OUTPUT | BOTH';
COMMENT ON COLUMN lychee_erp.tax_codes.tax_type IS 'STANDARD | REDUCED | ZERO | EXEMPT | NON_TAXABLE';
COMMENT ON COLUMN lychee_erp.tax_codes.is_deductible IS 'false 时 input_gl_account_id 必填，过账不得回退 INPUT_TAX';

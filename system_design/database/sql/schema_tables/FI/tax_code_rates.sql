DROP TABLE IF EXISTS lychee_erp.tax_code_rates CASCADE;

CREATE TABLE lychee_erp.tax_code_rates
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	tax_code_id bigint NOT NULL,
	rate numeric(5,2) NOT NULL,
	valid_from date NOT NULL,
	valid_to date NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.tax_code_rates ADD CONSTRAINT pk_tax_code_rates PRIMARY KEY (id);

ALTER TABLE lychee_erp.tax_code_rates ADD CONSTRAINT ck_tax_code_rates_rate CHECK (rate >= 0 AND rate <= 100);

ALTER TABLE lychee_erp.tax_code_rates ADD CONSTRAINT ck_tax_code_rates_dates CHECK (valid_to IS NULL OR valid_to >= valid_from);

CREATE INDEX ix_tax_code_rates_code_date ON lychee_erp.tax_code_rates (tax_code_id, valid_from);

ALTER TABLE lychee_erp.tax_code_rates ADD CONSTRAINT fk_tax_code_rates_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_code_rates ADD CONSTRAINT fk_tax_code_rates_code
	FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_code_rates ADD CONSTRAINT fk_tax_code_rates_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_code_rates ADD CONSTRAINT fk_tax_code_rates_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON TABLE lychee_erp.tax_code_rates IS '税码税率档；单据行 tax_rate 仅为开单日快照';
COMMENT ON COLUMN lychee_erp.tax_code_rates.rate IS '百分比，如 10.00 = 10%';

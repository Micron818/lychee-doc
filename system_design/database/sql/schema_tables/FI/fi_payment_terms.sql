DROP TABLE IF EXISTS lychee_erp.fi_payment_terms CASCADE;

CREATE TABLE lychee_erp.fi_payment_terms
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	base_date_type varchar(20) NOT NULL,    -- INVOICE_DATE, SOURCE_DATE
	partner_scope varchar(20) NOT NULL DEFAULT 'BOTH', -- BOTH, CUSTOMER, SUPPLIER
	is_active boolean NOT NULL DEFAULT true,
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.fi_payment_terms ADD CONSTRAINT pk_fi_payment_terms PRIMARY KEY (id);

ALTER TABLE lychee_erp.fi_payment_terms ADD CONSTRAINT uk_fi_payment_terms UNIQUE (tenant_id, code);

CREATE INDEX ix_fi_payment_terms_scope
	ON lychee_erp.fi_payment_terms (tenant_id, partner_scope, is_active);

ALTER TABLE lychee_erp.fi_payment_terms ADD CONSTRAINT fk_fi_payment_terms_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_payment_terms ADD CONSTRAINT fk_fi_payment_terms_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_payment_terms ADD CONSTRAINT fk_fi_payment_terms_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON TABLE lychee_erp.fi_payment_terms IS '付款条件主档：基准日类型与往来范围在头上，全行共用';
COMMENT ON COLUMN lychee_erp.fi_payment_terms.base_date_type IS 'INVOICE_DATE, SOURCE_DATE';
COMMENT ON COLUMN lychee_erp.fi_payment_terms.partner_scope IS 'BOTH, CUSTOMER, SUPPLIER';


DROP TABLE IF EXISTS lychee_erp.company_texts CASCADE
;

CREATE TABLE lychee_erp.company_texts
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	locale varchar(10) NOT NULL,
	name varchar(100) NOT NULL,
	address text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.company_texts ADD CONSTRAINT company_texts_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.company_texts ADD CONSTRAINT uk_company_texts_company_locale
	UNIQUE (tenant_id, company_id, locale)
;

CREATE INDEX ix_company_texts_company ON lychee_erp.company_texts (company_id ASC)
;

ALTER TABLE lychee_erp.company_texts ADD CONSTRAINT fk_company_texts_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.company_texts ADD CONSTRAINT fk_company_texts_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.company_texts ADD CONSTRAINT fk_company_texts_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.company_texts ADD CONSTRAINT fk_company_texts_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.company_texts.locale
	IS 'Translation language, en / zh_CN / vi, and not the company source_locale'
;

COMMENT ON COLUMN lychee_erp.company_texts.name
	IS 'Translated company name'
;

COMMENT ON COLUMN lychee_erp.company_texts.address
	IS 'Translated company address; blank means no translation for this field'
;

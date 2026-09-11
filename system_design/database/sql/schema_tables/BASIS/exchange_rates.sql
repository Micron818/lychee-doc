
DROP TABLE IF EXISTS lychee_erp.exchange_rates CASCADE
;

CREATE TABLE lychee_erp.exchange_rates
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	company_id bigint NOT NULL,
	from_currency_id bigint NOT NULL,
	to_currency_id bigint NOT NULL,
	rate_date date NOT NULL,
	rate_type varchar(20) NOT NULL DEFAULT 'STANDARD',
	rate numeric(18,6) NOT NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT exchange_rates_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT uk_exchange_rates
	UNIQUE (tenant_id, company_id, from_currency_id, to_currency_id, rate_type, rate_date)
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT chk_exchange_rates_rate_positive
	CHECK (rate > 0)
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT chk_exchange_rates_currency_pair
	CHECK (from_currency_id <> to_currency_id)
;

CREATE INDEX idx_exchange_rates_lookup
	ON lychee_erp.exchange_rates (tenant_id, company_id, from_currency_id, to_currency_id, rate_type, rate_date DESC)
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT fk_exchange_rates_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT fk_exchange_rates_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT fk_exchange_rates_from_currency
	FOREIGN KEY (from_currency_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT fk_exchange_rates_to_currency
	FOREIGN KEY (to_currency_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT fk_exchange_rates_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.exchange_rates ADD CONSTRAINT fk_exchange_rates_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.exchange_rates.from_currency_id
	IS 'Document / foreign currency (FK option_values CURRENCY)'
;

COMMENT ON COLUMN lychee_erp.exchange_rates.to_currency_id
	IS 'Local currency; must equal companies.local_currency_id'
;

COMMENT ON COLUMN lychee_erp.exchange_rates.rate
	IS 'Direct quotation: 1 from_currency = rate to_currency. local_amount = document_amount * rate'
;

COMMENT ON COLUMN lychee_erp.exchange_rates.rate_type
	IS 'STANDARD (document default), CLOSING (period-end revaluation, reserved)'
;

COMMENT ON COLUMN lychee_erp.exchange_rates.rate_date
	IS 'Effective date; lookup uses latest rate_date <= document date'
;

DROP TABLE IF EXISTS lychee_erp.fi_payment_term_lines CASCADE;

CREATE TABLE lychee_erp.fi_payment_term_lines
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	payment_term_id bigint NOT NULL,
	line_no integer NOT NULL,
	percent numeric(5,2) NOT NULL,
	calc_method varchar(20) NOT NULL,    -- NET_DAYS, EOM_PLUS_DAYS, FIXED_DAY, IMMEDIATE
	days integer NOT NULL DEFAULT 0,
	extra_months integer NOT NULL DEFAULT 0,
	fixed_day integer NULL,
	discount_percent numeric(5,2) NOT NULL DEFAULT 0,
	discount_days integer NOT NULL DEFAULT 0,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT pk_fi_payment_term_lines PRIMARY KEY (id);

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT uk_fi_payment_term_lines UNIQUE (tenant_id, payment_term_id, line_no);

CREATE INDEX ix_fi_payment_term_lines_term
	ON lychee_erp.fi_payment_term_lines (payment_term_id);

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT fk_fi_ptl_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT fk_fi_ptl_term
	FOREIGN KEY (payment_term_id) REFERENCES lychee_erp.fi_payment_terms (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT fk_fi_ptl_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT fk_fi_ptl_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT ck_fi_ptl_percent
	CHECK (percent > 0 AND percent <= 100);

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT ck_fi_ptl_days
	CHECK (days >= 0);

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT ck_fi_ptl_extra_months
	CHECK (extra_months >= 0);

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT ck_fi_ptl_fixed_day
	CHECK (fixed_day IS NULL OR (fixed_day >= 1 AND fixed_day <= 31));

ALTER TABLE lychee_erp.fi_payment_term_lines ADD CONSTRAINT ck_fi_ptl_discount
	CHECK (discount_percent >= 0 AND discount_percent <= 100 AND discount_days >= 0);

COMMENT ON COLUMN lychee_erp.fi_payment_term_lines.percent IS '30.00 = 30%；保存时 SUM(percent) 必须 = 100.00';
COMMENT ON COLUMN lychee_erp.fi_payment_term_lines.calc_method IS 'NET_DAYS, EOM_PLUS_DAYS, FIXED_DAY, IMMEDIATE';

DROP TABLE IF EXISTS lychee_erp.ap_invoice_schedules CASCADE;

CREATE TABLE lychee_erp.ap_invoice_schedules
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	invoice_id bigint NOT NULL,
	line_no integer NOT NULL,
	payment_term_line_id bigint NULL,
	percent numeric(5,2) NOT NULL,
	amount numeric(18,2) NOT NULL,
	due_date date NOT NULL,
	due_date_overridden boolean NOT NULL DEFAULT false,
	discount_percent numeric(5,2) NOT NULL DEFAULT 0,
	discount_days integer NOT NULL DEFAULT 0,
	discount_until date NULL,
	discount_amount numeric(18,2) NOT NULL DEFAULT 0,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.ap_invoice_schedules ADD CONSTRAINT pk_ap_invoice_schedules PRIMARY KEY (id);

ALTER TABLE lychee_erp.ap_invoice_schedules ADD CONSTRAINT uk_ap_invoice_schedules UNIQUE (tenant_id, invoice_id, line_no);

CREATE INDEX ix_ap_invoice_schedules_due
	ON lychee_erp.ap_invoice_schedules (tenant_id, due_date);

CREATE INDEX ix_ap_invoice_schedules_invoice
	ON lychee_erp.ap_invoice_schedules (invoice_id);

ALTER TABLE lychee_erp.ap_invoice_schedules ADD CONSTRAINT fk_ap_sch_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoice_schedules ADD CONSTRAINT fk_ap_sch_invoice
	FOREIGN KEY (invoice_id) REFERENCES lychee_erp.ap_invoices (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoice_schedules ADD CONSTRAINT fk_ap_sch_term_line
	FOREIGN KEY (payment_term_line_id) REFERENCES lychee_erp.fi_payment_term_lines (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoice_schedules ADD CONSTRAINT fk_ap_sch_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoice_schedules ADD CONSTRAINT fk_ap_sch_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON TABLE lychee_erp.ap_invoice_schedules IS '应付发票付款排程；percent/折扣为生成时快照';
COMMENT ON COLUMN lychee_erp.ap_invoice_schedules.due_date_overridden IS 'true 时改合计只重摊金额，保留到期日';

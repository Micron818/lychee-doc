DROP TABLE IF EXISTS lychee_erp.ar_invoice_lines CASCADE;

-- ==========================================
-- AR Invoice Lines (应收发票明细表)
-- ==========================================
CREATE TABLE lychee_erp.ar_invoice_lines
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	invoice_id bigint NOT NULL,
	line_no integer NOT NULL,
	description varchar(255) NOT NULL,
	quantity numeric(18,6) NOT NULL DEFAULT 1,
	unit_price numeric(18,4) NOT NULL DEFAULT 0,
	line_amount numeric(18,2) NOT NULL DEFAULT 0,
	tax_code_id bigint NULL,
	tax_rate numeric(5,2) NOT NULL DEFAULT 0,    -- 百分比，如 13.00 表示 13%
	tax_amount numeric(18,2) NOT NULL DEFAULT 0,
	tax_amount_overridden boolean NOT NULL DEFAULT false,
	total_amount numeric(18,2) NOT NULL DEFAULT 0,
	gl_account_id bigint NULL,
	department_id bigint NULL,

	source_doc_type varchar(50) NOT NULL,    -- SALES_ORDER, SHIPMENT
	source_doc_id bigint NULL,
	source_doc_no varchar(50) NOT NULL,
	source_line_id bigint NULL,
	source_line_no integer NULL,

	material_id bigint NULL,           -- 关联 SCM 的物料ID (可选，支持无物料号的费用发票)
	material_code varchar(50) NULL,    -- 物料编码快照
	material_name varchar(200) NULL,   -- 物料名称快照
	uom_code varchar(20) NULL,         -- 单位编码快照 (如 PCS, KG)

	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.ar_invoice_lines ADD CONSTRAINT ar_invoice_lines_pkey
	PRIMARY KEY (id);
	
ALTER TABLE lychee_erp.ar_invoice_lines ADD CONSTRAINT uk_ar_invoice_lines UNIQUE (tenant_id,invoice_id,line_no);

CREATE INDEX idx_ar_invoice_lines_invoice ON lychee_erp.ar_invoice_lines (invoice_id ASC);
CREATE INDEX idx_ar_invoice_lines_source_doc ON lychee_erp.ar_invoice_lines (source_doc_id ASC);
CREATE INDEX idx_ar_invoice_lines_gl_account ON lychee_erp.ar_invoice_lines (gl_account_id ASC);

ALTER TABLE lychee_erp.ar_invoice_lines ADD CONSTRAINT fk_ar_invoice_lines_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ar_invoice_lines ADD CONSTRAINT fk_ar_invoice_lines_invoice
	FOREIGN KEY (invoice_id) REFERENCES lychee_erp.ar_invoices (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ar_invoice_lines ADD CONSTRAINT fk_ar_invoice_lines_gl_account
	FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ar_invoice_lines ADD CONSTRAINT fk_ar_invoice_lines_department
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ar_invoice_lines ADD CONSTRAINT fk_ar_invoice_lines_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ar_invoice_lines ADD CONSTRAINT fk_ar_invoice_lines_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ar_invoice_lines ADD CONSTRAINT fk_ar_invoice_lines_tax_code
	FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.ar_invoice_lines.source_doc_type
	IS 'SALES_ORDER, SHIPMENT';

COMMENT ON COLUMN lychee_erp.ar_invoice_lines.tax_rate
	IS '百分比，如 13.00 表示 13%';

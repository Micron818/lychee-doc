DROP TABLE IF EXISTS lychee_erp.ap_invoice_lines CASCADE;

-- ==========================================
-- AP Invoice Lines (应付发票明细表)
-- ==========================================
CREATE TABLE lychee_erp.ap_invoice_lines
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	invoice_id bigint NOT NULL,
	line_no integer NOT NULL,
	description varchar(255) NOT NULL, --发票票面上的实际货物/服务名称（用于税务合规、无物料号的杂项费用记录
	quantity numeric(18,6) NOT NULL DEFAULT 1,
	unit_price numeric(18,4) NOT NULL DEFAULT 0,
	line_amount numeric(18,2) NOT NULL DEFAULT 0,
	source_amount numeric(18,2) NULL,
	tax_rate numeric(5,2) NOT NULL DEFAULT 0,    -- 百分比，如 13.00 表示 13%
	tax_amount numeric(18,2) NOT NULL DEFAULT 0,
	total_amount numeric(18,2) NOT NULL DEFAULT 0,
	gl_account_id bigint NULL,
	department_id bigint NULL,
	
	source_doc_type varchar(50) NOT NULL,    -- RECEIPT, PURCHASE_ORDER
	source_doc_id bigint NULL,
	source_doc_no varchar(50) NOT NULL,
	source_line_id bigint NULL,
	source_line_no integer NULL,

	material_id bigint NULL,           -- 关联 SCM 的物料ID (可选，支持无物料号的费用发票)
	material_code varchar(50) NULL,    -- 物料编码快照
	material_name varchar(200) NULL,   -- 物料名称快照
	uom_code varchar(20) NULL,         -- 单位编码快照 (如 PCS, KG)

	remarks text NULL, -- 财务人员的内部备注和特殊情况说明
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.ap_invoice_lines ADD CONSTRAINT ap_invoice_lines_pkey
	PRIMARY KEY (id);

ALTER TABLE lychee_erp.ap_invoice_lines ADD CONSTRAINT uk_ap_invoice_lines UNIQUE (tenant_id,invoice_id,line_no);

CREATE INDEX idx_ap_invoice_lines_invoice ON lychee_erp.ap_invoice_lines (invoice_id ASC);
CREATE INDEX idx_ap_invoice_lines_source_doc ON lychee_erp.ap_invoice_lines (source_doc_id ASC);
CREATE INDEX idx_ap_invoice_lines_gl_account ON lychee_erp.ap_invoice_lines (gl_account_id ASC);

ALTER TABLE lychee_erp.ap_invoice_lines ADD CONSTRAINT fk_ap_invoice_lines_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoice_lines ADD CONSTRAINT fk_ap_invoice_lines_invoice
	FOREIGN KEY (invoice_id) REFERENCES lychee_erp.ap_invoices (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoice_lines ADD CONSTRAINT fk_ap_invoice_lines_gl_account
	FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoice_lines ADD CONSTRAINT fk_ap_invoice_lines_department
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoice_lines ADD CONSTRAINT fk_ap_invoice_lines_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.ap_invoice_lines ADD CONSTRAINT fk_ap_invoice_lines_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON COLUMN lychee_erp.ap_invoice_lines.source_doc_type
	IS 'RECEIPT, PURCHASE_ORDER';

COMMENT ON COLUMN lychee_erp.ap_invoice_lines.tax_rate
	IS '百分比，如 13.00 表示 13%';

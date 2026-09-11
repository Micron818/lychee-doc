DROP TABLE IF EXISTS lychee_erp.ap_credit_memo_lines CASCADE;

-- ==========================================
-- AP Credit Memo Lines (应付贷项明细表)
-- ==========================================
CREATE TABLE lychee_erp.ap_credit_memo_lines
(
	id                              bigserial       NOT NULL,
	tenant_id                       bigint          NOT NULL,
	credit_memo_id                  bigint          NOT NULL,
	line_no                         integer         NOT NULL,
	original_ap_invoice_line_id     bigint          NOT NULL,
	description                     varchar(255)    NOT NULL,
	quantity                        numeric(18,6)   NOT NULL DEFAULT 1,
	unit_price                      numeric(18,4)   NOT NULL DEFAULT 0,
	line_amount                     numeric(18,2)   NOT NULL DEFAULT 0,
	source_amount                   numeric(18,2)   NULL,
	tax_code_id                     bigint          NULL,
	tax_rate                        numeric(5,2)    NOT NULL DEFAULT 0,
	tax_amount                      numeric(18,2)   NOT NULL DEFAULT 0,
	tax_amount_overridden           boolean         NOT NULL DEFAULT false,
	total_amount                    numeric(18,2)   NOT NULL DEFAULT 0,
	gl_account_id                   bigint          NULL,
	department_id                   bigint          NULL,
	source_doc_type                 varchar(50)     NOT NULL,
	source_doc_id                   bigint          NULL,
	source_doc_no                   varchar(50)     NOT NULL,
	source_line_id                  bigint          NULL,
	source_line_no                  integer         NULL,
	material_id                     bigint          NULL,
	material_code                   varchar(50)     NULL,
	material_name                   varchar(200)    NULL,
	uom_code                        varchar(20)     NULL,
	remarks                         text            NULL,
	created_at                      timestamp       NULL,
	updated_at                      timestamp       NULL,
	created_by                      bigint          NULL,
	updated_by                      bigint          NULL,
	CONSTRAINT pk_ap_credit_memo_lines PRIMARY KEY (id),
	CONSTRAINT uk_ap_credit_memo_lines_no
		UNIQUE (tenant_id, credit_memo_id, line_no),
	CONSTRAINT uk_ap_credit_memo_lines_original
		UNIQUE (tenant_id, credit_memo_id, original_ap_invoice_line_id)
);

CREATE INDEX ix_ap_credit_memo_lines_header
	ON lychee_erp.ap_credit_memo_lines (credit_memo_id);
CREATE INDEX ix_ap_credit_memo_lines_original
	ON lychee_erp.ap_credit_memo_lines (original_ap_invoice_line_id);
CREATE INDEX ix_ap_credit_memo_lines_source
	ON lychee_erp.ap_credit_memo_lines (source_doc_type, source_doc_id, source_line_id);

ALTER TABLE lychee_erp.ap_credit_memo_lines
	ADD CONSTRAINT fk_ap_credit_memo_lines_header
		FOREIGN KEY (credit_memo_id)
		REFERENCES lychee_erp.ap_credit_memos (id);
ALTER TABLE lychee_erp.ap_credit_memo_lines
	ADD CONSTRAINT fk_ap_credit_memo_lines_original
		FOREIGN KEY (original_ap_invoice_line_id)
		REFERENCES lychee_erp.ap_invoice_lines (id);
ALTER TABLE lychee_erp.ap_credit_memo_lines
	ADD CONSTRAINT fk_ap_credit_memo_lines_gl
		FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id);
ALTER TABLE lychee_erp.ap_credit_memo_lines
	ADD CONSTRAINT fk_ap_credit_memo_lines_tax
		FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id);
ALTER TABLE lychee_erp.ap_credit_memo_lines
	ADD CONSTRAINT fk_ap_credit_memo_lines_dept
		FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id);

COMMENT ON TABLE lychee_erp.ap_credit_memo_lines
	IS '应付贷项明细：数量与金额为正数，来源为原应付发票行';
COMMENT ON COLUMN lychee_erp.ap_credit_memo_lines.source_amount
	IS '原行暂估按数量比例；过账用来贷 GR/IR';

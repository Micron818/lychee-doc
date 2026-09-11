DROP TABLE IF EXISTS lychee_erp.tax_determinations CASCADE;

CREATE TABLE lychee_erp.tax_determinations
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	country_code varchar(2) NOT NULL,
	company_id bigint NULL,
	tax_direction varchar(20) NOT NULL,
	partner_tax_class_id bigint NULL,
	material_tax_class_id bigint NULL,
	tax_code_id bigint NOT NULL,
	is_active boolean NOT NULL DEFAULT true,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.tax_determinations ADD CONSTRAINT pk_tax_determinations PRIMARY KEY (id);

CREATE UNIQUE INDEX uk_tax_determinations
	ON lychee_erp.tax_determinations (
		tenant_id,
		country_code,
		COALESCE(company_id, 0),
		tax_direction,
		COALESCE(partner_tax_class_id, 0),
		COALESCE(material_tax_class_id, 0)
	);

ALTER TABLE lychee_erp.tax_determinations ADD CONSTRAINT fk_tax_det_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_determinations ADD CONSTRAINT fk_tax_det_company
	FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_determinations ADD CONSTRAINT fk_tax_det_partner_class
	FOREIGN KEY (partner_tax_class_id) REFERENCES lychee_erp.tax_classes (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_determinations ADD CONSTRAINT fk_tax_det_material_class
	FOREIGN KEY (material_tax_class_id) REFERENCES lychee_erp.tax_classes (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_determinations ADD CONSTRAINT fk_tax_det_tax_code
	FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_determinations ADD CONSTRAINT fk_tax_det_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_determinations ADD CONSTRAINT fk_tax_det_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON TABLE lychee_erp.tax_determinations IS '税码判定矩阵；company_id 空为该国默认';
COMMENT ON COLUMN lychee_erp.tax_determinations.company_id IS 'NULL = 该国默认；有值 = 公司覆盖';
COMMENT ON COLUMN lychee_erp.tax_determinations.tax_direction IS 'INPUT | OUTPUT；不可 BOTH';

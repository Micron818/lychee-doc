DROP TABLE IF EXISTS lychee_erp.tax_classes CASCADE;

CREATE TABLE lychee_erp.tax_classes
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	class_scope varchar(20) NOT NULL,
	is_active boolean NOT NULL DEFAULT true,
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.tax_classes ADD CONSTRAINT pk_tax_classes PRIMARY KEY (id);

ALTER TABLE lychee_erp.tax_classes ADD CONSTRAINT uk_tax_classes UNIQUE (tenant_id, code);

CREATE INDEX ix_tax_classes_scope ON lychee_erp.tax_classes (tenant_id, class_scope);

ALTER TABLE lychee_erp.tax_classes ADD CONSTRAINT fk_tax_classes_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_classes ADD CONSTRAINT fk_tax_classes_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.tax_classes ADD CONSTRAINT fk_tax_classes_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON TABLE lychee_erp.tax_classes IS '税分类：物料或往来的税务身份，供判定矩阵匹配';
COMMENT ON COLUMN lychee_erp.tax_classes.class_scope IS 'MATERIAL | PARTNER';

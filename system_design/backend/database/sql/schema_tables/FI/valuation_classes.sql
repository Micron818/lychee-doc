DROP TABLE IF EXISTS lychee_erp.valuation_classes CASCADE;

CREATE TABLE lychee_erp.valuation_classes
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	name varchar(100) NOT NULL,
	is_inventoried boolean NOT NULL DEFAULT true,
	is_active boolean NOT NULL DEFAULT true,
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
);

ALTER TABLE lychee_erp.valuation_classes ADD CONSTRAINT valuation_classes_pkey PRIMARY KEY (id);

ALTER TABLE lychee_erp.valuation_classes ADD CONSTRAINT uk_valuation_classes_tenant_code UNIQUE (tenant_id, code);

ALTER TABLE lychee_erp.valuation_classes ADD CONSTRAINT fk_valuation_classes_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.valuation_classes ADD CONSTRAINT fk_valuation_classes_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

ALTER TABLE lychee_erp.valuation_classes ADD CONSTRAINT fk_valuation_classes_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;

COMMENT ON TABLE lychee_erp.valuation_classes IS '评估类：会计科目判定维度，独立于物料类型';
COMMENT ON COLUMN lychee_erp.valuation_classes.is_inventoried IS '执行期存货判定 SSOT：是否参与库存数量、仓库必填、GR/IR 暂估；须与 material_types.is_inventoried 同值才可映射';

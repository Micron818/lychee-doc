DROP TABLE IF EXISTS lychee_erp.inspection_characteristics CASCADE;

CREATE TABLE lychee_erp.inspection_characteristics
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    code varchar(50) NOT NULL,
    name varchar(100) NOT NULL,
    description text NULL,
    data_type_option_id bigint NOT NULL, -- 'Numeric', 'Boolean', 'Text'
    uom_id bigint NULL, -- Unit of Measure for the characteristic (e.g., cm, kg)
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.inspection_characteristics ADD CONSTRAINT inspection_characteristics_pkey PRIMARY KEY (id);
ALTER TABLE lychee_erp.inspection_characteristics ADD CONSTRAINT uk_inspection_characteristics_tenant_code UNIQUE (tenant_id, code);

ALTER TABLE lychee_erp.inspection_characteristics ADD CONSTRAINT fk_inspection_characteristics_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_characteristics ADD CONSTRAINT fk_inspection_characteristics_data_type FOREIGN KEY (data_type_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_characteristics ADD CONSTRAINT fk_inspection_characteristics_uom FOREIGN KEY (uom_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_characteristics ADD CONSTRAINT fk_inspection_characteristics_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_characteristics ADD CONSTRAINT fk_inspection_characteristics_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


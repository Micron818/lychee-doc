DROP TABLE IF EXISTS lychee_erp.inspection_plans CASCADE;

CREATE TABLE lychee_erp.inspection_plans
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    material_id bigint NOT NULL,
    inspection_type_option_id bigint NOT NULL, -- 'Incoming', 'InProcess', 'Final'
    version varchar(20) NOT NULL DEFAULT '1.0',
    valid_from date NOT NULL,
    valid_to date NULL,
    is_active boolean NOT NULL DEFAULT true,
    description text NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.inspection_plans ADD CONSTRAINT inspection_plans_pkey PRIMARY KEY (id);
CREATE INDEX idx_inspection_plans_material ON lychee_erp.inspection_plans (material_id ASC);

ALTER TABLE lychee_erp.inspection_plans ADD CONSTRAINT fk_inspection_plans_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_plans ADD CONSTRAINT fk_inspection_plans_material FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_plans ADD CONSTRAINT fk_inspection_plans_type FOREIGN KEY (inspection_type_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_plans ADD CONSTRAINT fk_inspection_plans_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_plans ADD CONSTRAINT fk_inspection_plans_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


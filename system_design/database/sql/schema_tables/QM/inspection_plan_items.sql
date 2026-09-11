DROP TABLE IF EXISTS lychee_erp.inspection_plan_items CASCADE;

CREATE TABLE lychee_erp.inspection_plan_items
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    inspection_plan_id bigint NOT NULL,
    inspection_characteristic_id bigint NOT NULL,
    sequence int NOT NULL DEFAULT 0,
    target_value numeric(18,6) NULL,
    upper_limit numeric(18,6) NULL, -- 規格上限 (USL)
    lower_limit numeric(18,6) NULL, -- 規格下限 (LSL)
    text_value_expected varchar(100) NULL, -- 預期文字結果 (for non-numeric)
    is_mandatory boolean NOT NULL DEFAULT true,
    remarks text NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.inspection_plan_items ADD CONSTRAINT inspection_plan_items_pkey PRIMARY KEY (id);
CREATE INDEX idx_inspection_plan_items_plan ON lychee_erp.inspection_plan_items (inspection_plan_id ASC);

ALTER TABLE lychee_erp.inspection_plan_items ADD CONSTRAINT fk_inspection_plan_items_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_plan_items ADD CONSTRAINT fk_inspection_plan_items_plan FOREIGN KEY (inspection_plan_id) REFERENCES lychee_erp.inspection_plans (id) ON DELETE Cascade ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_plan_items ADD CONSTRAINT fk_inspection_plan_items_char FOREIGN KEY (inspection_characteristic_id) REFERENCES lychee_erp.inspection_characteristics (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_plan_items ADD CONSTRAINT fk_inspection_plan_items_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_plan_items ADD CONSTRAINT fk_inspection_plan_items_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


DROP TABLE IF EXISTS lychee_erp.inspection_results CASCADE;

CREATE TABLE lychee_erp.inspection_results
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    inspection_order_id bigint NOT NULL,
    inspection_characteristic_id bigint NOT NULL,
    measured_value numeric(18,6) NULL, -- 實測數值
    text_value varchar(100) NULL,      -- 文字結果 (for qualitative)
    is_passed boolean NOT NULL,        -- 該項目是否合格
    remarks text NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.inspection_results ADD CONSTRAINT inspection_results_pkey PRIMARY KEY (id);
CREATE INDEX idx_inspection_results_order ON lychee_erp.inspection_results (inspection_order_id ASC);

ALTER TABLE lychee_erp.inspection_results ADD CONSTRAINT fk_inspection_results_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_results ADD CONSTRAINT fk_inspection_results_order FOREIGN KEY (inspection_order_id) REFERENCES lychee_erp.inspection_orders (id) ON DELETE Cascade ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_results ADD CONSTRAINT fk_inspection_results_char FOREIGN KEY (inspection_characteristic_id) REFERENCES lychee_erp.inspection_characteristics (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_results ADD CONSTRAINT fk_inspection_results_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_results ADD CONSTRAINT fk_inspection_results_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


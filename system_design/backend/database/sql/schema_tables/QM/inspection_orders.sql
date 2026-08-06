DROP TABLE IF EXISTS lychee_erp.inspection_orders CASCADE;

CREATE TABLE lychee_erp.inspection_orders
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    code varchar(50) NOT NULL,
    inspection_type_option_id bigint NOT NULL, -- 'Incoming', 'InProcess', 'Final'
    material_id bigint NOT NULL,
    batch_no varchar(50) NULL,
    quantity numeric(18,6) NOT NULL, -- 送檢數量
    sample_size numeric(18,6) NULL,  -- 抽樣數量
    
    source_doc_type varchar(50) NULL, -- 'GoodsReceipt', 'ProductionOrder'
    source_doc_id bigint NULL,
    
    inspection_status_option_id bigint NULL, -- 'Created', 'InProcess', 'Completed', 'Closed'
    usage_decision_option_id bigint NULL,    -- 'Accept', 'Reject', 'Concession' (特採)
    decision_date timestamp without time zone NULL,
    decision_by bigint NULL,
    
    remarks text NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT inspection_orders_pkey PRIMARY KEY (id);
ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT uk_inspection_orders_tenant_code UNIQUE (tenant_id, code);
CREATE INDEX idx_inspection_orders_material ON lychee_erp.inspection_orders (material_id ASC);
CREATE INDEX idx_inspection_orders_source ON lychee_erp.inspection_orders (source_doc_type, source_doc_id);

ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT fk_inspection_orders_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT fk_inspection_orders_material FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT fk_inspection_orders_type FOREIGN KEY (inspection_type_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT fk_inspection_orders_status FOREIGN KEY (inspection_status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT fk_inspection_orders_decision FOREIGN KEY (usage_decision_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT fk_inspection_orders_decision_by FOREIGN KEY (decision_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT fk_inspection_orders_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.inspection_orders ADD CONSTRAINT fk_inspection_orders_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


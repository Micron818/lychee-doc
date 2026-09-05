CREATE TABLE lychee_erp.sales_forecast_items
(
    id                      bigserial       NOT NULL,
    tenant_id               bigint          NOT NULL,
    sales_forecast_id       bigint          NOT NULL,
    item_no                 integer         NOT NULL,
    material_id             bigint          NOT NULL,
    unit_id                 bigint          NOT NULL,
    bucket_date             date            NOT NULL,
    required_date           date            NOT NULL,
    forecast_quantity       numeric(18,6)   NOT NULL,
    allocated_quantity      numeric(18,6)   NOT NULL DEFAULT 0,
    consumed_quantity       numeric(18,6)   NOT NULL DEFAULT 0,
    customer_item_ref_no    varchar(50)     NULL,
    line_status             varchar(20)     NOT NULL,    -- DRAFT, ACTIVE, CLOSED, CANCELLED
    remarks                 text            NULL,
    created_at              timestamp       NULL,
    updated_at              timestamp       NULL,
    created_by              bigint          NULL,
    updated_by              bigint          NULL,
    CONSTRAINT pk_sales_forecast_items PRIMARY KEY (id),
    CONSTRAINT uk_sales_forecast_items_item_no
        UNIQUE (tenant_id, sales_forecast_id, item_no),
    CONSTRAINT uk_sales_forecast_items_material_bucket
        UNIQUE (tenant_id, sales_forecast_id, material_id, bucket_date),
    CONSTRAINT ck_sales_forecast_items_qty_positive
        CHECK (forecast_quantity > 0),
    CONSTRAINT ck_sales_forecast_items_qty_nonneg
        CHECK (allocated_quantity >= 0 AND consumed_quantity >= 0),
    CONSTRAINT ck_sales_forecast_items_qty_cover
        CHECK (allocated_quantity + consumed_quantity <= forecast_quantity)
)
;

CREATE INDEX idx_sales_forecast_items_header
    ON lychee_erp.sales_forecast_items (sales_forecast_id)
;
CREATE INDEX idx_sales_forecast_items_material
    ON lychee_erp.sales_forecast_items (material_id)
;
CREATE INDEX idx_sales_forecast_items_bucket
    ON lychee_erp.sales_forecast_items (tenant_id, material_id, bucket_date)
;
CREATE INDEX idx_sales_forecast_items_status
    ON lychee_erp.sales_forecast_items (line_status)
;

ALTER TABLE lychee_erp.sales_forecast_items
    ADD CONSTRAINT fk_sales_forecast_items_header
        FOREIGN KEY (sales_forecast_id)
        REFERENCES lychee_erp.sales_forecasts (id) ON DELETE CASCADE
;
ALTER TABLE lychee_erp.sales_forecast_items
    ADD CONSTRAINT fk_sales_forecast_items_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id)
;
ALTER TABLE lychee_erp.sales_forecast_items
    ADD CONSTRAINT fk_sales_forecast_items_material
        FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id)
;
ALTER TABLE lychee_erp.sales_forecast_items
    ADD CONSTRAINT fk_sales_forecast_items_unit
        FOREIGN KEY (unit_id) REFERENCES lychee_erp.material_units (id)
;

COMMENT ON TABLE lychee_erp.sales_forecast_items
    IS '客户预告订单明细。一行 = 物料 + 时间桶'
;
COMMENT ON COLUMN lychee_erp.sales_forecast_items.bucket_date
    IS '时间桶锚点：DAY=required_date；WEEK=该周 ISO 周一；MONTH=该月 1 日'
;
COMMENT ON COLUMN lychee_erp.sales_forecast_items.required_date
    IS '需求日，转 FO 时写入 factory_order_items.due_date'
;
COMMENT ON COLUMN lychee_erp.sales_forecast_items.forecast_quantity
    IS '本行预告数量（单据单位）'
;
COMMENT ON COLUMN lychee_erp.sales_forecast_items.allocated_quantity
    IS '已转 FactoryOrderItem 且仍挂在本预告上的数量'
;
COMMENT ON COLUMN lychee_erp.sales_forecast_items.consumed_quantity
    IS '已被正式 sales_order_items 消耗的数量'
;
COMMENT ON COLUMN lychee_erp.sales_forecast_items.line_status
    IS 'DRAFT, ACTIVE, CLOSED, CANCELLED'
;

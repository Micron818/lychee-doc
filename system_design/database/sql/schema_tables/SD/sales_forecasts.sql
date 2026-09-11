DROP TABLE IF EXISTS lychee_erp.sales_forecast_items CASCADE
;
DROP TABLE IF EXISTS lychee_erp.sales_forecasts CASCADE
;

CREATE TABLE lychee_erp.sales_forecasts
(
    id                      bigserial       NOT NULL,
    tenant_id               bigint          NOT NULL,
    company_id              bigint          NOT NULL,
    forecast_no             varchar(50)     NOT NULL,
    forecast_date           date            NOT NULL,
    customer_id             bigint          NOT NULL,
    customer_name           varchar(200)    NULL,
    customer_forecast_no    varchar(50)     NULL,
    version                 varchar(50)     NOT NULL,
    bucket_type             varchar(20)     NOT NULL,    -- DAY, WEEK, MONTH
    sales_person_id         bigint          NULL,
    forecast_status         varchar(20)     NOT NULL,    -- DRAFT, ACTIVE, CLOSED, CANCELLED
    supersedes_id           bigint          NULL,
    confirmed_at            timestamp       NULL,
    confirmed_by            bigint          NULL,
    remarks                 text            NULL,
    created_at              timestamp       NULL,
    updated_at              timestamp       NULL,
    created_by              bigint          NULL,
    updated_by              bigint          NULL,
    CONSTRAINT pk_sales_forecasts PRIMARY KEY (id),
    CONSTRAINT uk_sales_forecasts_no UNIQUE (tenant_id, forecast_no)
)
;

CREATE UNIQUE INDEX uk_sales_forecasts_one_active
    ON lychee_erp.sales_forecasts (tenant_id, company_id, customer_id)
    WHERE forecast_status = 'ACTIVE'
;

CREATE UNIQUE INDEX uk_sales_forecasts_customer_version
    ON lychee_erp.sales_forecasts (tenant_id, company_id, customer_id, version)
    WHERE forecast_status IN ('DRAFT', 'ACTIVE')
;

CREATE INDEX idx_sales_forecasts_date
    ON lychee_erp.sales_forecasts (forecast_date)
;
CREATE INDEX idx_sales_forecasts_customer
    ON lychee_erp.sales_forecasts (customer_id)
;
CREATE INDEX idx_sales_forecasts_company
    ON lychee_erp.sales_forecasts (company_id)
;
CREATE INDEX idx_sales_forecasts_status
    ON lychee_erp.sales_forecasts (forecast_status)
;
CREATE INDEX idx_sales_forecasts_supersedes
    ON lychee_erp.sales_forecasts (supersedes_id)
;

ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id)
;
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_company
        FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id)
;
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_customer
        FOREIGN KEY (customer_id) REFERENCES lychee_erp.customers (id)
;
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_sales_person
        FOREIGN KEY (sales_person_id) REFERENCES lychee_erp.users (id)
;
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_confirmed_by
        FOREIGN KEY (confirmed_by) REFERENCES lychee_erp.users (id)
;
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_supersedes
        FOREIGN KEY (supersedes_id) REFERENCES lychee_erp.sales_forecasts (id)
        ON DELETE SET NULL
;

COMMENT ON TABLE lychee_erp.sales_forecasts
    IS '客户预告订单表头。计划需求，不可交货/开票'
;
COMMENT ON COLUMN lychee_erp.sales_forecasts.forecast_no
    IS '系统单号，DocumentTypeEnum.SALES_FORECAST，前缀 SFO'
;
COMMENT ON COLUMN lychee_erp.sales_forecasts.company_id
    IS 'Selling company（与 sales_orders.company_id 同语义）。ACTIVE/版本唯一键含本列，消耗不得跨公司'
;
COMMENT ON COLUMN lychee_erp.sales_forecasts.customer_forecast_no
    IS '客户侧预告/Booking 单号，不对系统唯一'
;
COMMENT ON COLUMN lychee_erp.sales_forecasts.version
    IS '滚动版本号，如 2026W36。同一公司+客户 DRAFT/ACTIVE 内唯一'
;
COMMENT ON COLUMN lychee_erp.sales_forecasts.bucket_type
    IS 'DAY, WEEK, MONTH。本单全部明细共用'
;
COMMENT ON COLUMN lychee_erp.sales_forecasts.forecast_status
    IS 'DRAFT, ACTIVE, CLOSED, CANCELLED'
;
COMMENT ON COLUMN lychee_erp.sales_forecasts.supersedes_id
    IS '本单取代的上一张预告（通常为刚关闭的同客户 ACTIVE）'
;

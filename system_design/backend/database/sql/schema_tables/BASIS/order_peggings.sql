 

DROP TABLE IF EXISTS lychee_erp.order_peggings CASCADE
;

CREATE TABLE lychee_erp.order_peggings
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	material_id bigint NOT NULL,
	demand_id bigint NOT NULL,
	supply_id bigint NOT NULL,
	demand_type varchar(30) NOT NULL,    -- SALES_ORDER,FACTORY_ORDER,MRP_RESULT,PLANNED_ORDER,PRODUCTION_ORDER,PURCHASE_REQUISITION,PURCHASE_ORDER,GOODS_RECEIPT,OUTSOURCE_ORDER
	supply_type varchar(30) NOT NULL,    -- SALES_ORDER,FACTORY_ORDER,MRP_RESULT,PLANNED_ORDER,PRODUCTION_ORDER,PURCHASE_REQUISITION,PURCHASE_ORDER,GOODS_RECEIPT,OUTSOURCE_ORDER
	pegged_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.order_peggings ADD CONSTRAINT pk_order_peggings
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.order_peggings ADD CONSTRAINT uk_order_peggings UNIQUE (tenant_id,material_id,demand_id,supply_id)
;

CREATE INDEX idx_order_peggings_demand ON lychee_erp.order_peggings (tenant_id ASC,demand_type ASC,demand_id ASC)
;

CREATE INDEX idx_order_peggings_supply ON lychee_erp.order_peggings (tenant_id ASC,supply_type ASC,supply_id ASC)
;

COMMENT ON COLUMN lychee_erp.order_peggings.demand_type
	IS 'SALES_ORDER,FACTORY_ORDER,MRP_RESULT,PLANNED_ORDER,PRODUCTION_ORDER,PURCHASE_REQUISITION,PURCHASE_ORDER,GOODS_RECEIPT,OUTSOURCE_ORDER'
;

COMMENT ON COLUMN lychee_erp.order_peggings.supply_type
	IS 'SALES_ORDER,FACTORY_ORDER,MRP_RESULT,PLANNED_ORDER,PRODUCTION_ORDER,PURCHASE_REQUISITION,PURCHASE_ORDER,GOODS_RECEIPT,OUTSOURCE_ORDER'
;

 
 

DROP TABLE IF EXISTS lychee_erp.production_reports CASCADE
;

CREATE TABLE lychee_erp.production_reports
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	report_no varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	production_order_id bigint NOT NULL,
	report_date date NOT NULL,
	good_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	rework_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	scrap_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	product_material_id bigint NOT NULL,
	warehouse_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL   DEFAULT '',
	unit_id bigint NOT NULL,
	report_status varchar(20) NOT NULL,    -- DRAFT/POSTED/CANCELLED
	defect_reason_code varchar(50) NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.production_reports ADD CONSTRAINT pk_production_reports
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.production_reports ADD CONSTRAINT uk_production_reports UNIQUE (tenant_id,report_no)
;

CREATE INDEX IXFK_production_reports_material_units ON lychee_erp.production_reports (unit_id ASC)
;

CREATE INDEX IXFK_production_reports_materials ON lychee_erp.production_reports (product_material_id ASC)
;

CREATE INDEX IXFK_production_reports_production_orders ON lychee_erp.production_reports (production_order_id ASC)
;

CREATE INDEX idx_prod_reports_date ON lychee_erp.production_reports (tenant_id ASC,report_date ASC)
;

ALTER TABLE lychee_erp.production_reports ADD CONSTRAINT fk_production_reports_material_units
	FOREIGN KEY (unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_reports ADD CONSTRAINT fk_production_reports_materials
	FOREIGN KEY (product_material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_reports ADD CONSTRAINT fk_production_reports_production_orders
	FOREIGN KEY (production_order_id) REFERENCES lychee_erp.production_orders (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.production_reports.report_status
	IS 'DRAFT/POSTED/CANCELLED'
;

 
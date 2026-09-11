 

DROP TABLE IF EXISTS lychee_erp.production_report_components CASCADE
;

CREATE TABLE lychee_erp.production_report_components
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	production_report_id bigint NOT NULL,
	item_no integer NOT NULL,
	production_order_component_id bigint NOT NULL,
	warehouse_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL   DEFAULT '',
	material_id bigint NOT NULL,
	unit_id bigint NOT NULL,
	issue_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.production_report_components ADD CONSTRAINT PK_production_report_components
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.production_report_components ADD CONSTRAINT uk_production_report_components_item_no UNIQUE (tenant_id,production_report_id,item_no)
;


CREATE INDEX IXFK_production_report_components_material_units ON lychee_erp.production_report_components (unit_id ASC)
;

CREATE INDEX IXFK_production_report_components_materials ON lychee_erp.production_report_components (material_id ASC)
;

CREATE INDEX IXFK_production_report_components_production_order_components ON lychee_erp.production_report_components (production_order_component_id ASC)
;

CREATE INDEX IXFK_production_report_components_production_reports ON lychee_erp.production_report_components (production_report_id ASC)
;

ALTER TABLE lychee_erp.production_report_components ADD CONSTRAINT fk_production_report_components_material_units
	FOREIGN KEY (unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_report_components ADD CONSTRAINT fk_production_report_components_materials
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_report_components ADD CONSTRAINT fk_production_report_components_production_order_components
	FOREIGN KEY (production_order_component_id) REFERENCES lychee_erp.production_order_components (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_report_components ADD CONSTRAINT fk_production_report_components_production_reports
	FOREIGN KEY (production_report_id) REFERENCES lychee_erp.production_reports (id) ON DELETE No Action ON UPDATE No Action
;

 

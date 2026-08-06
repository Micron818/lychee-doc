 

DROP TABLE IF EXISTS lychee_erp.production_order_components CASCADE
;

CREATE TABLE lychee_erp.production_order_components
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	production_order_id bigint NOT NULL,
	item_no integer NOT NULL,
	material_id bigint NOT NULL,
	issue_unit_id bigint NOT NULL,
	required_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	issued_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	is_backflush boolean NOT NULL   DEFAULT false,
	under_issue_tolerance numeric(18,6) NULL   DEFAULT 0,
	remarks text NULL
)
;

ALTER TABLE lychee_erp.production_order_components ADD CONSTRAINT production_order_components_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.production_order_components ADD CONSTRAINT uk_production_order_components_item_no UNIQUE (tenant_id,production_order_id,item_no)
;


CREATE INDEX ixfk_production_order_components_material_units ON lychee_erp.production_order_components (issue_unit_id ASC)
;

CREATE INDEX idx_po_components_order ON lychee_erp.production_order_components (production_order_id ASC)
;

ALTER TABLE lychee_erp.production_order_components ADD CONSTRAINT fk_po_components_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_order_components ADD CONSTRAINT fk_po_components_order
	FOREIGN KEY (production_order_id) REFERENCES lychee_erp.production_orders (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_order_components ADD CONSTRAINT fk_po_components_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.production_order_components ADD CONSTRAINT fk_production_order_components_material_units
	FOREIGN KEY (issue_unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

 

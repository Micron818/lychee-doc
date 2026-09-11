 

DROP TABLE IF EXISTS lychee_erp.bom_items CASCADE
;

CREATE TABLE lychee_erp.bom_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	bom_id bigint NOT NULL,
	item_no integer NOT NULL,
	component_material_id bigint NOT NULL,
	quantity numeric(18,6) NOT NULL,
	scrap_rate numeric(5,2) NULL   DEFAULT 0,
	is_backflush boolean NULL,
	active_status varchar(20) NOT NULL,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.bom_items ADD CONSTRAINT bom_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.bom_items ADD CONSTRAINT uk_bom_items_item_no UNIQUE (tenant_id,bom_id,item_no)
;


ALTER TABLE lychee_erp.bom_items ADD CONSTRAINT uk_bom_items UNIQUE (tenant_id,bom_id,component_material_id)
;

CREATE INDEX idx_bom_items_bom ON lychee_erp.bom_items (bom_id ASC)
;

CREATE INDEX idx_bom_items_component ON lychee_erp.bom_items (component_material_id ASC)
;

ALTER TABLE lychee_erp.bom_items ADD CONSTRAINT fk_bom_items_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.bom_items ADD CONSTRAINT fk_bom_items_bom
	FOREIGN KEY (bom_id) REFERENCES lychee_erp.bill_of_materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.bom_items ADD CONSTRAINT fk_bom_items_component
	FOREIGN KEY (component_material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.bom_items ADD CONSTRAINT fk_bom_items_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.bom_items ADD CONSTRAINT fk_bom_items_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 

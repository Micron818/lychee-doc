 

DROP TABLE IF EXISTS lychee_erp.outsource_order_components CASCADE
;

CREATE TABLE lychee_erp.outsource_order_components
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	outsource_order_item_id bigint NOT NULL,
	item_no integer NOT NULL,
	material_id bigint NOT NULL,
	unit_id bigint NOT NULL,
	required_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	issued_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	consumed_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	is_supplier_provided boolean NOT NULL   DEFAULT false,
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.outsource_order_components ADD CONSTRAINT outsource_order_components_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.outsource_order_components ADD CONSTRAINT uk_outsource_order_components_item_no UNIQUE (tenant_id,outsource_order_item_id,item_no)
;


CREATE INDEX idx_outsource_components_mat ON lychee_erp.outsource_order_components (material_id ASC)
;

CREATE INDEX idx_outsource_components_item ON lychee_erp.outsource_order_components (outsource_order_item_id ASC)
;

ALTER TABLE lychee_erp.outsource_order_components ADD CONSTRAINT fk_outsource_comp_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_components ADD CONSTRAINT fk_outsource_comp_item
	FOREIGN KEY (outsource_order_item_id) REFERENCES lychee_erp.outsource_order_items (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_components ADD CONSTRAINT fk_outsource_comp_mat
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_components ADD CONSTRAINT fk_outsource_comp_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_components ADD CONSTRAINT fk_outsource_comp_unit
	FOREIGN KEY (unit_id) REFERENCES lychee_erp.material_units (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.outsource_order_components ADD CONSTRAINT fk_outsource_comp_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

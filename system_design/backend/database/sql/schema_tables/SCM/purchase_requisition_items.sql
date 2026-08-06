 

DROP TABLE IF EXISTS lychee_erp.purchase_requisition_items CASCADE
;

CREATE TABLE lychee_erp.purchase_requisition_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	purchase_requisition_id bigint NOT NULL,
	item_no integer NOT NULL,
	material_id bigint NOT NULL,
	required_date date NOT NULL,    -- MrpResult.plannedEndDate
	latest_order_date date NULL,    -- MrpResult.plannedStartDate
	required_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	ordered_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	unit_id bigint NULL,
	suggested_supplier_id bigint NULL,
	status varchar(20) NOT NULL,    -- DRAFT,APPROVED, PARTIAL, COMPLETED, CLOSED
	remarks text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.purchase_requisition_items ADD CONSTRAINT purchase_requisition_items_pkey
	PRIMARY KEY (id)
;
ALTER TABLE lychee_erp.purchase_requisition_items ADD CONSTRAINT uk_purchase_requisition_items_item_no UNIQUE (tenant_id,purchase_requisition_id,item_no)
;


CREATE INDEX idx_pr_items_material ON lychee_erp.purchase_requisition_items (material_id ASC)
;

CREATE INDEX idx_pr_items_requisition ON lychee_erp.purchase_requisition_items (purchase_requisition_id ASC)
;

ALTER TABLE lychee_erp.purchase_requisition_items ADD CONSTRAINT fk_pr_items_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_requisition_items ADD CONSTRAINT fk_pr_items_requisition
	FOREIGN KEY (purchase_requisition_id) REFERENCES lychee_erp.purchase_requisitions (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_requisition_items ADD CONSTRAINT fk_pr_items_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_requisition_items ADD CONSTRAINT fk_pr_items_supplier
	FOREIGN KEY (suggested_supplier_id) REFERENCES lychee_erp.suppliers (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.purchase_requisition_items.required_date
	IS 'MrpResult.plannedEndDate'
;

COMMENT ON COLUMN lychee_erp.purchase_requisition_items.latest_order_date
	IS 'MrpResult.plannedStartDate'
;

COMMENT ON COLUMN lychee_erp.purchase_requisition_items.status
	IS 'DRAFT,APPROVED, PARTIAL, COMPLETED, CLOSED'
;

 

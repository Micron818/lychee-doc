 

DROP TABLE IF EXISTS lychee_erp.stock_on_hand CASCADE
;

CREATE TABLE lychee_erp.stock_on_hand
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	material_id bigint NOT NULL,
	warehouse_id bigint NOT NULL,
	batch_no varchar(50) NOT NULL   DEFAULT '',
	base_unit_id bigint NOT NULL,
	physical_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	reserved_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	blocked_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	qa_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	last_transaction_at timestamp without time zone NULL,
	location_code varchar(50) NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.stock_on_hand ADD CONSTRAINT stock_on_hand_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.stock_on_hand ADD CONSTRAINT uk_stock_on_hand_unique UNIQUE (tenant_id,factory_id,warehouse_id,material_id,batch_no)
;

CREATE INDEX idx_stock_on_hand_warehouse ON lychee_erp.stock_on_hand (warehouse_id ASC)
;

CREATE INDEX idx_stock_on_hand_material ON lychee_erp.stock_on_hand (material_id ASC)
;

CREATE INDEX idx_stock_on_hand_mrp ON lychee_erp.stock_on_hand (tenant_id ASC,factory_id ASC,material_id ASC)
;

ALTER TABLE lychee_erp.stock_on_hand ADD CONSTRAINT fk_stock_on_hand_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_on_hand ADD CONSTRAINT fk_stock_on_hand_warehouse
	FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.stock_on_hand ADD CONSTRAINT fk_stock_on_hand_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

 
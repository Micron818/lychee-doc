 

DROP TABLE IF EXISTS lychee_erp.warehouses CASCADE
;

CREATE TABLE lychee_erp.warehouses
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	name varchar(100) NOT NULL,
	warehouse_type varchar(20) NOT NULL,    -- RAW_MATERIAL,WIP,FINISHED_GOODS,TRANSIT,SCRAP,OUTSOURCE
	supplier_id bigint NULL,
	address text NULL,
	contact_person varchar(100) NULL,
	contact_phone varchar(50) NULL,
	is_mrp_relevant boolean NOT NULL   DEFAULT true,
	active_status varchar(20) NOT NULL,    -- ACTIVE, INACTIVE
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.warehouses ADD CONSTRAINT warehouses_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.warehouses ADD CONSTRAINT uk_warehouses_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX IXFK_warehouses_suppliers ON lychee_erp.warehouses (supplier_id ASC)
;

ALTER TABLE lychee_erp.warehouses ADD CONSTRAINT fk_warehouses_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.warehouses ADD CONSTRAINT fk_warehouses_suppliers
	FOREIGN KEY (supplier_id) REFERENCES lychee_erp.suppliers (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.warehouses ADD CONSTRAINT fk_warehouses_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.warehouses.warehouse_type
	IS 'RAW_MATERIAL,WIP,FINISHED_GOODS,TRANSIT,SCRAP,OUTSOURCE'
;

COMMENT ON COLUMN lychee_erp.warehouses.active_status
	IS 'ACTIVE, INACTIVE'
;

 
 

DROP TABLE IF EXISTS lychee_erp.bill_of_materials CASCADE
;

CREATE TABLE lychee_erp.bill_of_materials
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	product_material_id bigint NOT NULL,
	version varchar(20) NOT NULL,
	valid_from date NOT NULL,
	valid_to date NULL,
	bom_status varchar(20) NOT NULL,
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.bill_of_materials ADD CONSTRAINT bill_of_materials_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.bill_of_materials ADD CONSTRAINT uk_bom_product_version UNIQUE (tenant_id,product_material_id,version)
;

CREATE INDEX idx_bom_explosion_lookup ON lychee_erp.bill_of_materials (tenant_id ASC,product_material_id ASC,valid_from ASC)
;

ALTER TABLE lychee_erp.bill_of_materials ADD CONSTRAINT fk_bom_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.bill_of_materials ADD CONSTRAINT fk_bom_product_material
	FOREIGN KEY (product_material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.bill_of_materials ADD CONSTRAINT fk_bom_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.bill_of_materials ADD CONSTRAINT fk_bom_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
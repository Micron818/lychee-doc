DROP TABLE IF EXISTS lychee_erp.material_images CASCADE
;

CREATE TABLE lychee_erp.material_images
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	material_id bigint NOT NULL,
	file_path varchar(500) NOT NULL,
	file_name varchar(255) NULL,
	file_size bigint NULL,
	is_primary boolean DEFAULT false,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.material_images ADD CONSTRAINT material_images_pkey
	PRIMARY KEY (id)
;

CREATE INDEX idx_material_images_tenant_material ON lychee_erp.material_images (tenant_id ASC, material_id ASC)
;

ALTER TABLE lychee_erp.material_images ADD CONSTRAINT fk_material_images_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_images ADD CONSTRAINT fk_material_images_material
	FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_images ADD CONSTRAINT fk_material_images_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_images ADD CONSTRAINT fk_material_images_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

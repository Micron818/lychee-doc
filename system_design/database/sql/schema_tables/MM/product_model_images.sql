DROP TABLE IF EXISTS lychee_erp.product_model_images CASCADE
;

CREATE TABLE lychee_erp.product_model_images
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	product_model_id bigint NOT NULL,
	color_id bigint NULL,
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

COMMENT ON TABLE lychee_erp.product_model_images IS
	'款色产品图。仅 is_fashion_variant = true 的物料共享；color_id 空表示本款不分色'
;

ALTER TABLE lychee_erp.product_model_images ADD CONSTRAINT product_model_images_pkey
	PRIMARY KEY (id)
;

CREATE INDEX idx_product_model_images_tenant_model_color
	ON lychee_erp.product_model_images (tenant_id ASC, product_model_id ASC, color_id ASC)
;

CREATE UNIQUE INDEX uk_product_model_images_primary_color
	ON lychee_erp.product_model_images (tenant_id ASC, product_model_id ASC, color_id ASC)
	WHERE is_primary = true AND color_id IS NOT NULL
;

CREATE UNIQUE INDEX uk_product_model_images_primary_nocolor
	ON lychee_erp.product_model_images (tenant_id ASC, product_model_id ASC)
	WHERE is_primary = true AND color_id IS NULL
;

ALTER TABLE lychee_erp.product_model_images ADD CONSTRAINT fk_product_model_images_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_images ADD CONSTRAINT fk_product_model_images_model
	FOREIGN KEY (product_model_id) REFERENCES lychee_erp.product_models (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_images ADD CONSTRAINT fk_product_model_images_color
	FOREIGN KEY (color_id) REFERENCES lychee_erp.colors (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_images ADD CONSTRAINT fk_product_model_images_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_images ADD CONSTRAINT fk_product_model_images_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

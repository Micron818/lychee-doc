 

DROP TABLE IF EXISTS lychee_erp.product_model_colors CASCADE
;

CREATE TABLE lychee_erp.product_model_colors
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	product_model_id bigint NOT NULL,
	color_id bigint NOT NULL,
	sku_code char(1) NOT NULL,
	sequence integer NOT NULL DEFAULT 0,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.product_model_colors ADD CONSTRAINT pk_product_model_colors
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.product_model_colors ADD CONSTRAINT uk_product_model_colors UNIQUE (tenant_id,product_model_id,color_id)
;

ALTER TABLE lychee_erp.product_model_colors ADD CONSTRAINT uk_product_model_colors_sku UNIQUE (tenant_id,product_model_id,sku_code)
;

ALTER TABLE lychee_erp.product_model_colors ADD CONSTRAINT ck_product_model_colors_sku CHECK (sku_code ~ '^[A-Z]$')
;

CREATE INDEX idx_product_model_colors_model ON lychee_erp.product_model_colors (product_model_id ASC)
;

ALTER TABLE lychee_erp.product_model_colors ADD CONSTRAINT fk_product_model_colors_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_colors ADD CONSTRAINT fk_product_model_colors_model
	FOREIGN KEY (product_model_id) REFERENCES lychee_erp.product_models (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_colors ADD CONSTRAINT fk_product_model_colors_color
	FOREIGN KEY (color_id) REFERENCES lychee_erp.colors (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_colors ADD CONSTRAINT fk_product_model_colors_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_colors ADD CONSTRAINT fk_product_model_colors_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 

DROP TABLE IF EXISTS lychee_erp.product_model_size_codes CASCADE
;

CREATE TABLE lychee_erp.product_model_size_codes
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	product_model_id bigint NOT NULL,
	color_id bigint NULL,
	product_size_id bigint NOT NULL,
	sku_code char(2) NOT NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.product_model_size_codes ADD CONSTRAINT pk_product_model_size_codes
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.product_model_size_codes ADD CONSTRAINT ck_pmsc_sku CHECK (sku_code ~ '^[0-9]{2}$' AND sku_code <> '00')
;

CREATE UNIQUE INDEX uk_pmsc_model_color_size
	ON lychee_erp.product_model_size_codes (tenant_id, product_model_id, color_id, product_size_id)
	WHERE color_id IS NOT NULL
;

CREATE UNIQUE INDEX uk_pmsc_model_color_sku
	ON lychee_erp.product_model_size_codes (tenant_id, product_model_id, color_id, sku_code)
	WHERE color_id IS NOT NULL
;

CREATE UNIQUE INDEX uk_pmsc_model_nocolor_size
	ON lychee_erp.product_model_size_codes (tenant_id, product_model_id, product_size_id)
	WHERE color_id IS NULL
;

CREATE UNIQUE INDEX uk_pmsc_model_nocolor_sku
	ON lychee_erp.product_model_size_codes (tenant_id, product_model_id, sku_code)
	WHERE color_id IS NULL
;

CREATE INDEX idx_pmsc_model ON lychee_erp.product_model_size_codes (product_model_id ASC)
;

ALTER TABLE lychee_erp.product_model_size_codes ADD CONSTRAINT fk_pmsc_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_size_codes ADD CONSTRAINT fk_pmsc_model
	FOREIGN KEY (product_model_id) REFERENCES lychee_erp.product_models (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_size_codes ADD CONSTRAINT fk_pmsc_color
	FOREIGN KEY (color_id) REFERENCES lychee_erp.colors (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_size_codes ADD CONSTRAINT fk_pmsc_size
	FOREIGN KEY (product_size_id) REFERENCES lychee_erp.product_sizes (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_size_codes ADD CONSTRAINT fk_pmsc_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_model_size_codes ADD CONSTRAINT fk_pmsc_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

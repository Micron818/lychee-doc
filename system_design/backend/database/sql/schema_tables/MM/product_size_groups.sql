 

DROP TABLE IF EXISTS lychee_erp.product_size_group_items CASCADE
;
DROP TABLE IF EXISTS lychee_erp.product_size_groups CASCADE
;

CREATE TABLE lychee_erp.product_size_groups
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(20) NOT NULL,
	name varchar(50) NULL,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.product_size_groups ADD CONSTRAINT pk_product_size_groups
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.product_size_groups ADD CONSTRAINT uk_product_size_groups_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_product_size_groups_status_option ON lychee_erp.product_size_groups (status_option_id ASC)
;

ALTER TABLE lychee_erp.product_size_groups ADD CONSTRAINT fk_product_size_groups_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_size_groups ADD CONSTRAINT fk_product_size_groups_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_size_groups ADD CONSTRAINT fk_product_size_groups_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_size_groups ADD CONSTRAINT fk_product_size_groups_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

CREATE TABLE lychee_erp.product_size_group_items
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	size_group_id bigint NOT NULL,
	product_size_id bigint NOT NULL,
	sequence integer NOT NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.product_size_group_items ADD CONSTRAINT pk_product_size_group_items
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.product_size_group_items ADD CONSTRAINT uk_size_group_items_group_size UNIQUE (tenant_id,size_group_id,product_size_id)
;

CREATE INDEX idx_size_group_items_group ON lychee_erp.product_size_group_items (size_group_id ASC)
;

ALTER TABLE lychee_erp.product_size_group_items ADD CONSTRAINT fk_size_group_items_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_size_group_items ADD CONSTRAINT fk_size_group_items_group
	FOREIGN KEY (size_group_id) REFERENCES lychee_erp.product_size_groups (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_size_group_items ADD CONSTRAINT fk_size_group_items_size
	FOREIGN KEY (product_size_id) REFERENCES lychee_erp.product_sizes (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_size_group_items ADD CONSTRAINT fk_size_group_items_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.product_size_group_items ADD CONSTRAINT fk_size_group_items_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

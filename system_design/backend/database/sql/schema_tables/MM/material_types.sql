 

DROP TABLE IF EXISTS lychee_erp.material_types CASCADE
;

CREATE TABLE lychee_erp.material_types
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(20) NOT NULL,
	name varchar(50) NOT NULL,
	is_inventoried boolean NOT NULL   DEFAULT true,
	is_purchased boolean NOT NULL   DEFAULT false,
	is_sold boolean NOT NULL   DEFAULT false,
	is_manufactured boolean NOT NULL   DEFAULT false,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.material_types ADD CONSTRAINT material_types_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.material_types ADD CONSTRAINT uk_material_types_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_material_types_status_option ON lychee_erp.material_types (status_option_id ASC)
;

ALTER TABLE lychee_erp.material_types ADD CONSTRAINT fk_material_types_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_types ADD CONSTRAINT fk_material_types_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_types ADD CONSTRAINT fk_material_types_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.material_types ADD CONSTRAINT fk_material_types_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
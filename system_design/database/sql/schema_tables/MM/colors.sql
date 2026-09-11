 

DROP TABLE IF EXISTS lychee_erp.colors CASCADE
;

CREATE TABLE lychee_erp.colors
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(20) NOT NULL,
	name varchar(50) NULL,
	hex_code varchar(9) NULL,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.colors ADD CONSTRAINT colors_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.colors ADD CONSTRAINT uk_colors_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_colors_status_option ON lychee_erp.colors (status_option_id ASC)
;

ALTER TABLE lychee_erp.colors ADD CONSTRAINT fk_colors_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.colors ADD CONSTRAINT fk_colors_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.colors ADD CONSTRAINT fk_colors_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.colors ADD CONSTRAINT fk_colors_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
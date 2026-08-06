 

DROP TABLE IF EXISTS lychee_erp.tenants CASCADE
;

CREATE TABLE lychee_erp.tenants
(
	id bigserial NOT NULL,
	name varchar(100) NULL,
	code varchar(50) NOT NULL,
	domain varchar(100) NULL,
	description text NULL,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.tenants ADD CONSTRAINT tenants_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.tenants ADD CONSTRAINT uk_tenant_code UNIQUE (code)
;

CREATE INDEX idx_tenants_status_option ON lychee_erp.tenants (status_option_id ASC)
;

ALTER TABLE lychee_erp.tenants ADD CONSTRAINT fk_tenants_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.tenants ADD CONSTRAINT fk_tenants_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.tenants ADD CONSTRAINT fk_tenants_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
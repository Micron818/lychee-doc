 

DROP TABLE IF EXISTS lychee_erp.role_permission_delegations CASCADE
;

CREATE TABLE lychee_erp.role_permission_delegations
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	delegator_id bigint NOT NULL,
	delegatee_id bigint NOT NULL,
	role_permission_id bigint NOT NULL,
	start_date timestamp without time zone NOT NULL,
	end_date timestamp without time zone NOT NULL,
	reason text NULL,
	status_option_id bigint NULL,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.role_permission_delegations ADD CONSTRAINT role_permission_delegations_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.role_permission_delegations ADD CONSTRAINT uk_role_permission_delegation UNIQUE (tenant_id,delegator_id,delegatee_id,role_permission_id,start_date,end_date)
;

CREATE INDEX idx_role_permission_delegations_delegatee ON lychee_erp.role_permission_delegations (delegatee_id ASC)
;

CREATE INDEX idx_role_permission_delegations_role_permission ON lychee_erp.role_permission_delegations (role_permission_id ASC)
;

CREATE INDEX idx_role_permission_delegations_delegator ON lychee_erp.role_permission_delegations (delegator_id ASC)
;

CREATE INDEX idx_role_permission_delegations_status_option ON lychee_erp.role_permission_delegations (status_option_id ASC)
;

ALTER TABLE lychee_erp.role_permission_delegations ADD CONSTRAINT fk_role_permission_delegations_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permission_delegations ADD CONSTRAINT fk_role_permission_delegations_delegator
	FOREIGN KEY (delegator_id) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permission_delegations ADD CONSTRAINT fk_role_permission_delegations_delegatee
	FOREIGN KEY (delegatee_id) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permission_delegations ADD CONSTRAINT fk_role_permission_delegations_role_permission
	FOREIGN KEY (role_permission_id) REFERENCES lychee_erp.role_permissions (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permission_delegations ADD CONSTRAINT fk_role_permission_delegations_status_option
	FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permission_delegations ADD CONSTRAINT fk_role_permission_delegations_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.role_permission_delegations ADD CONSTRAINT fk_role_permission_delegations_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

 
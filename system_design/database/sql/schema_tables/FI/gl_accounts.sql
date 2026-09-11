 

DROP TABLE IF EXISTS lychee_erp.gl_accounts CASCADE
;

CREATE TABLE lychee_erp.gl_accounts
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	code varchar(20) NOT NULL,
	name varchar(100) NOT NULL,
	account_type varchar(30) NOT NULL,    -- ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE, CASH
	parent_id bigint NULL,
	is_reconciliation boolean NOT NULL   DEFAULT false,
	is_active boolean NOT NULL   DEFAULT true,
	description text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.gl_accounts ADD CONSTRAINT gl_accounts_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.gl_accounts ADD CONSTRAINT uk_gl_accounts_tenant_code UNIQUE (tenant_id,code)
;

CREATE INDEX idx_gl_accounts_parent ON lychee_erp.gl_accounts (parent_id ASC)
;

CREATE INDEX idx_gl_accounts_account_type ON lychee_erp.gl_accounts (tenant_id ASC,account_type ASC)
;

ALTER TABLE lychee_erp.gl_accounts ADD CONSTRAINT fk_gl_accounts_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.gl_accounts ADD CONSTRAINT fk_gl_accounts_parent
	FOREIGN KEY (parent_id) REFERENCES lychee_erp.gl_accounts (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.gl_accounts ADD CONSTRAINT fk_gl_accounts_created_by
	FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.gl_accounts ADD CONSTRAINT fk_gl_accounts_updated_by
	FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.gl_accounts.account_type
	IS 'ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE, CASH'
;

 
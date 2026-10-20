
DROP TABLE IF EXISTS lychee_erp.user_role_scopes CASCADE
;

CREATE TABLE lychee_erp.user_role_scopes
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	user_role_id bigint NOT NULL,
	dimension varchar(20) NOT NULL,
	scope_type varchar(10) NOT NULL,
	value_id bigint NULL,
	created_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL   DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.user_role_scopes ADD CONSTRAINT user_role_scopes_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.user_role_scopes ADD CONSTRAINT fk_user_role_scopes_user_role
	FOREIGN KEY (user_role_id) REFERENCES lychee_erp.user_roles (id) ON DELETE Cascade ON UPDATE No Action
;

ALTER TABLE lychee_erp.user_role_scopes ADD CONSTRAINT ck_user_role_scopes_dimension
	CHECK (dimension IN ('COMPANY', 'FACTORY', 'WAREHOUSE'))
;

ALTER TABLE lychee_erp.user_role_scopes ADD CONSTRAINT ck_user_role_scopes_type
	CHECK (scope_type IN ('ALL', 'LIST'))
;

ALTER TABLE lychee_erp.user_role_scopes ADD CONSTRAINT ck_user_role_scopes_value
	CHECK ((scope_type = 'LIST') = (value_id IS NOT NULL))
;

CREATE INDEX idx_user_role_scopes_user_role ON lychee_erp.user_role_scopes (user_role_id ASC)
;

CREATE UNIQUE INDEX uk_user_role_scopes ON lychee_erp.user_role_scopes (
	user_role_id,
	dimension,
	scope_type,
	COALESCE(value_id, 0)
)
;

COMMENT ON TABLE lychee_erp.user_role_scopes IS '使用者角色指派上的資料範圍：公司、工廠、倉庫。存量指派回填公司 = 全部';
COMMENT ON COLUMN lychee_erp.user_role_scopes.dimension IS 'COMPANY, FACTORY, WAREHOUSE';
COMMENT ON COLUMN lychee_erp.user_role_scopes.scope_type IS 'ALL 或 LIST';
COMMENT ON COLUMN lychee_erp.user_role_scopes.value_id IS 'scope_type = LIST 時必填，指向該維度的公司、工廠或倉庫；ALL 時必須為空';


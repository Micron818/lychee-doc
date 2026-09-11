

DROP TABLE IF EXISTS lychee_erp.purchase_requisitions CASCADE
;

CREATE TABLE lychee_erp.purchase_requisitions
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	requisition_no varchar(50) NOT NULL,
	factory_id bigint NOT NULL,
	requisition_date date NOT NULL,
	requester_id bigint NULL,
	department_id bigint NULL,
	remarks text NULL,
	status varchar(20) NOT NULL,    -- DRAFT, APPROVED, PARTIAL,COMPLETED, CLOSED
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.purchase_requisitions ADD CONSTRAINT purchase_requisitions_pkey
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.purchase_requisitions ADD CONSTRAINT uk_purchase_requisitions_tenant UNIQUE (tenant_id,requisition_no)
;

CREATE INDEX IXFK_purchase_requisitions_departments ON lychee_erp.purchase_requisitions (department_id ASC)
;

CREATE INDEX IXFK_purchase_requisitions_factories ON lychee_erp.purchase_requisitions (factory_id ASC)
;

ALTER TABLE lychee_erp.purchase_requisitions ADD CONSTRAINT fk_purchase_requisitions_departments
	FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_requisitions ADD CONSTRAINT fk_purchase_requisitions_factories
	FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_requisitions ADD CONSTRAINT fk_purchase_requisitions_tenant
	FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action
;

ALTER TABLE lychee_erp.purchase_requisitions ADD CONSTRAINT fk_purchase_requisitions_requester
	FOREIGN KEY (requester_id) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action
;

COMMENT ON COLUMN lychee_erp.purchase_requisitions.status
	IS 'DRAFT, APPROVED, PARTIAL,COMPLETED, CLOSED'
;

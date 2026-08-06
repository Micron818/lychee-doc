 

DROP TABLE IF EXISTS lychee_erp.production_backflush_exceptions CASCADE
;

CREATE TABLE lychee_erp.production_backflush_exceptions
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	factory_id bigint NOT NULL,
	production_order_id bigint NOT NULL,
	production_report_id bigint NOT NULL,
	production_order_component_id bigint NOT NULL,
	product_material_id bigint NOT NULL,
	material_id bigint NOT NULL,
	issue_unit_id bigint NOT NULL,
	missing_quantity numeric(18,6) NOT NULL   DEFAULT 0,
	status varchar(20) NOT NULL   DEFAULT 'PENDING',    -- PENDING,RESOLVED,IGNORED
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.production_backflush_exceptions ADD CONSTRAINT production_backflush_exceptions_pkey
	PRIMARY KEY (id)
;

CREATE INDEX idx_prod_backflush_exc_report_id ON lychee_erp.production_backflush_exceptions (production_report_id ASC)
;

CREATE INDEX idx_prod_backflush_exc_order_id ON lychee_erp.production_backflush_exceptions (production_order_id ASC)
;

CREATE INDEX idx_prod_backflush_exc_tenant_id ON lychee_erp.production_backflush_exceptions (tenant_id ASC)
;

COMMENT ON COLUMN lychee_erp.production_backflush_exceptions.status
	IS 'PENDING,RESOLVED,IGNORED'
;

 
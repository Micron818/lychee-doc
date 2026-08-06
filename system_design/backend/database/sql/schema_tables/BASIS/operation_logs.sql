 

DROP TABLE IF EXISTS lychee_erp.operation_logs CASCADE
;

CREATE TABLE lychee_erp.operation_logs
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	document_type varchar(50) NOT NULL,
	document_id bigint NOT NULL,
	document_no varchar(50) NULL,
	operation_type varchar(50) NULL,    -- CREATE,UPDATE,DELETE,CLOSE,FORCE_CLOSE,CANCEL,APPROVE,REJECT,UNPUBLISH
	note text NULL,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.operation_logs ADD CONSTRAINT pk_operation_logs
	PRIMARY KEY (id)
;

CREATE INDEX idx_operation_logs ON lychee_erp.operation_logs (tenant_id ASC,document_type ASC,document_no ASC)
;

COMMENT ON COLUMN lychee_erp.operation_logs.operation_type
	IS 'CREATE,UPDATE,DELETE,CLOSE,FORCE_CLOSE,CANCEL,APPROVE,REJECT,UNPUBLISH'
;

 

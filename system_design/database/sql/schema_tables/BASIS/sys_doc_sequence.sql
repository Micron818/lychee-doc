 

DROP TABLE IF EXISTS lychee_erp.sys_doc_sequence CASCADE
;

CREATE TABLE lychee_erp.sys_doc_sequence
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	seq_key varchar(100) NOT NULL,
	current_value bigint NOT NULL
)
;

ALTER TABLE lychee_erp.sys_doc_sequence ADD CONSTRAINT pk_sys_doc_sequence
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.sys_doc_sequence ADD CONSTRAINT uk_sys_doc_sequence UNIQUE (tenant_id,seq_key)
;

 


DROP TABLE IF EXISTS lychee_erp.sys_doc_rule CASCADE
;

CREATE TABLE lychee_erp.sys_doc_rule
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	rule_code varchar(50) NOT NULL,
	date_format varchar(20) NULL,
	prefix varchar(10) NOT NULL,
	seq_length integer NOT NULL,
	reset_type varchar(50) NULL,
	item_first_no integer NOT NULL   DEFAULT 10,
	item_step integer NOT NULL   DEFAULT 10,
	is_item_manual_edit boolean NOT NULL   DEFAULT true,
	created_at timestamp without time zone NULL,
	updated_at timestamp without time zone NULL,
	created_by bigint NULL,
	updated_by bigint NULL
)
;

ALTER TABLE lychee_erp.sys_doc_rule ADD CONSTRAINT pk_sys_doc_rule
	PRIMARY KEY (id)
;

ALTER TABLE lychee_erp.sys_doc_rule ADD CONSTRAINT uk_sys_doc_rule UNIQUE (tenant_id,rule_code)
;

COMMENT ON COLUMN lychee_erp.sys_doc_rule.item_first_no
	IS '明细项次起始号码 (默认10)';
COMMENT ON COLUMN lychee_erp.sys_doc_rule.item_step
	IS '明细项次递增步长 (默认10)';
COMMENT ON COLUMN lychee_erp.sys_doc_rule.is_item_manual_edit
	IS '是否允许前端手动修改项次(插单)';


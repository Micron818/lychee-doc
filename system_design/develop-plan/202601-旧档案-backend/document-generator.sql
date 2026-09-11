-- 单据号码生成规则表
CREATE TABLE IF NOT EXISTS sys_doc_rule (
    id BIGSERIAL PRIMARY KEY,
    rule_code VARCHAR(32) NOT NULL UNIQUE,
    prefix VARCHAR(10) NOT NULL,
    date_format VARCHAR(20),
    seq_length INT NOT NULL DEFAULT 4,
    reset_type VARCHAR(10) DEFAULT 'DAILY',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);
COMMENT ON TABLE sys_doc_rule IS '单据号码生成规则表';

-- 单据流水号序列表（高频更新）
CREATE TABLE IF NOT EXISTS sys_doc_sequence (
    seq_key VARCHAR(64) PRIMARY KEY,
    current_value BIGINT NOT NULL
);
COMMENT ON TABLE sys_doc_sequence IS '单据流水号序列表';

-- 初始化基础数据 (SD销售订单, SCM采购申请, PP计划订单)
INSERT INTO sys_doc_rule (rule_code, prefix, date_format, seq_length, reset_type) 
VALUES
('SALES_ORDER', 'SO', 'yyyyMMdd', 4, 'DAILY'),
('FACTORY_ORDER', 'FO', 'yyyyMMdd', 4, 'DAILY'),
('MRP_RUN', 'MRP', 'yyyyMMdd', 4, 'DAILY'),
('PLANNED_ORDER', 'PL', 'yyyyMMdd', 4, 'DAILY'),
('PRODUCTION_ORDER', 'MO', 'yyyyMMdd', 4, 'DAILY'),
('PURCHASE_REQUISITION', 'PR', 'yyyyMMdd', 4, 'DAILY')
ON CONFLICT (rule_code) DO NOTHING;

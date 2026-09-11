DROP TABLE IF EXISTS lychee_erp.payslip_items CASCADE;

CREATE TABLE lychee_erp.payslip_items
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    payslip_id bigint NOT NULL,
    salary_component_option_id bigint NOT NULL, -- 'Basic', 'HousingAllowance', 'Tax', 'Insurance'
    amount numeric(18,2) NOT NULL DEFAULT 0,
    is_deduction boolean NOT NULL DEFAULT false, -- True=扣項, False=加項
    description text NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.payslip_items ADD CONSTRAINT payslip_items_pkey PRIMARY KEY (id);
CREATE INDEX idx_payslip_items_payslip ON lychee_erp.payslip_items (payslip_id ASC);

ALTER TABLE lychee_erp.payslip_items ADD CONSTRAINT fk_payslip_items_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payslip_items ADD CONSTRAINT fk_payslip_items_payslip FOREIGN KEY (payslip_id) REFERENCES lychee_erp.payslips (id) ON DELETE Cascade ON UPDATE No Action;
ALTER TABLE lychee_erp.payslip_items ADD CONSTRAINT fk_payslip_items_component FOREIGN KEY (salary_component_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payslip_items ADD CONSTRAINT fk_payslip_items_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payslip_items ADD CONSTRAINT fk_payslip_items_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


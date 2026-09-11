DROP TABLE IF EXISTS lychee_erp.payslips CASCADE;

CREATE TABLE lychee_erp.payslips
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    payroll_period_id bigint NOT NULL,
    employee_id bigint NOT NULL,
    basic_salary numeric(18,2) NOT NULL DEFAULT 0,
    total_earnings numeric(18,2) NOT NULL DEFAULT 0, -- 應發總額 (Basic + Allowances + Overtime)
    total_deductions numeric(18,2) NOT NULL DEFAULT 0, -- 應扣總額 (Tax + Insurance)
    net_salary numeric(18,2) NOT NULL DEFAULT 0, -- 實發金額
    status_option_id bigint NULL, -- 'Draft', 'Calculated', 'Approved', 'Paid'
    remarks text NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.payslips ADD CONSTRAINT payslips_pkey PRIMARY KEY (id);
ALTER TABLE lychee_erp.payslips ADD CONSTRAINT uk_payslips_period_employee UNIQUE (tenant_id, payroll_period_id, employee_id);

ALTER TABLE lychee_erp.payslips ADD CONSTRAINT fk_payslips_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payslips ADD CONSTRAINT fk_payslips_period FOREIGN KEY (payroll_period_id) REFERENCES lychee_erp.payroll_periods (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payslips ADD CONSTRAINT fk_payslips_employee FOREIGN KEY (employee_id) REFERENCES lychee_erp.employees (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payslips ADD CONSTRAINT fk_payslips_status FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payslips ADD CONSTRAINT fk_payslips_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payslips ADD CONSTRAINT fk_payslips_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


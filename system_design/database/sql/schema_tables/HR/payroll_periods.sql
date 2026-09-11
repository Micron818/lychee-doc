DROP TABLE IF EXISTS lychee_erp.payroll_periods CASCADE;

CREATE TABLE lychee_erp.payroll_periods
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    code varchar(50) NOT NULL, -- e.g., '2025-10'
    name varchar(100) NOT NULL, -- e.g., 'October 2025 Payroll'
    start_date date NOT NULL,
    end_date date NOT NULL,
    payment_date date NULL, -- 預計發薪日
    is_closed boolean NOT NULL DEFAULT false,
    remarks text NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.payroll_periods ADD CONSTRAINT payroll_periods_pkey PRIMARY KEY (id);
ALTER TABLE lychee_erp.payroll_periods ADD CONSTRAINT uk_payroll_periods_tenant_code UNIQUE (tenant_id, code);

ALTER TABLE lychee_erp.payroll_periods ADD CONSTRAINT fk_payroll_periods_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payroll_periods ADD CONSTRAINT fk_payroll_periods_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.payroll_periods ADD CONSTRAINT fk_payroll_periods_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


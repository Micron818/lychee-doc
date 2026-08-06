DROP TABLE IF EXISTS lychee_erp.employees CASCADE;

CREATE TABLE lychee_erp.employees
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    code varchar(50) NOT NULL, -- 員工編號
    first_name varchar(50) NOT NULL,
    last_name varchar(50) NOT NULL,
    email varchar(100) NULL,
    phone varchar(50) NULL,
    department_id bigint NULL, -- 所屬部門
    job_title_id bigint NULL,  -- 職稱
    manager_id bigint NULL,    -- 直屬主管
    user_id bigint NULL,       -- 關聯系統帳號
    hire_date date NOT NULL,   -- 入職日
    termination_date date NULL, -- 離職日
    status_option_id bigint NULL, -- 'Active', 'Resigned', 'OnLeave'
    address text NULL,
    birth_date date NULL,
    remarks text NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.employees ADD CONSTRAINT employees_pkey PRIMARY KEY (id);
ALTER TABLE lychee_erp.employees ADD CONSTRAINT uk_employees_tenant_code UNIQUE (tenant_id, code);
CREATE INDEX idx_employees_department ON lychee_erp.employees (department_id ASC);
CREATE INDEX idx_employees_user ON lychee_erp.employees (user_id ASC);

ALTER TABLE lychee_erp.employees ADD CONSTRAINT fk_employees_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.employees ADD CONSTRAINT fk_employees_department FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.employees ADD CONSTRAINT fk_employees_job_title FOREIGN KEY (job_title_id) REFERENCES lychee_erp.job_titles (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.employees ADD CONSTRAINT fk_employees_manager FOREIGN KEY (manager_id) REFERENCES lychee_erp.employees (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.employees ADD CONSTRAINT fk_employees_user FOREIGN KEY (user_id) REFERENCES lychee_erp.users (id) ON DELETE Set Null ON UPDATE No Action;
ALTER TABLE lychee_erp.employees ADD CONSTRAINT fk_employees_status FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.employees ADD CONSTRAINT fk_employees_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.employees ADD CONSTRAINT fk_employees_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


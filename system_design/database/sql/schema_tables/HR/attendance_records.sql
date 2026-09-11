DROP TABLE IF EXISTS lychee_erp.attendance_records CASCADE;

CREATE TABLE lychee_erp.attendance_records
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    employee_id bigint NOT NULL,
    record_date date NOT NULL,
    check_in_time timestamp without time zone NULL,
    check_out_time timestamp without time zone NULL,
    status_option_id bigint NULL, -- 'Present', 'Late', 'EarlyLeave', 'Absent'
    remarks text NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.attendance_records ADD CONSTRAINT attendance_records_pkey PRIMARY KEY (id);
ALTER TABLE lychee_erp.attendance_records ADD CONSTRAINT uk_attendance_employee_date UNIQUE (tenant_id, employee_id, record_date);
CREATE INDEX idx_attendance_date ON lychee_erp.attendance_records (record_date ASC);

ALTER TABLE lychee_erp.attendance_records ADD CONSTRAINT fk_attendance_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.attendance_records ADD CONSTRAINT fk_attendance_employee FOREIGN KEY (employee_id) REFERENCES lychee_erp.employees (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.attendance_records ADD CONSTRAINT fk_attendance_status FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.attendance_records ADD CONSTRAINT fk_attendance_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.attendance_records ADD CONSTRAINT fk_attendance_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


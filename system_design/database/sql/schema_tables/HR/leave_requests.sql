DROP TABLE IF EXISTS lychee_erp.leave_requests CASCADE;

CREATE TABLE lychee_erp.leave_requests
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    employee_id bigint NOT NULL,
    leave_type_option_id bigint NOT NULL, -- 'Annual', 'Sick', 'Personal', 'Unpaid'
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone NOT NULL,
    total_days numeric(5,2) NOT NULL,
    reason text NULL,
    status_option_id bigint NULL, -- 'Pending', 'Approved', 'Rejected'
    approver_id bigint NULL,
    approved_at timestamp without time zone NULL,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.leave_requests ADD CONSTRAINT leave_requests_pkey PRIMARY KEY (id);
CREATE INDEX idx_leave_requests_employee ON lychee_erp.leave_requests (employee_id ASC);
CREATE INDEX idx_leave_requests_date ON lychee_erp.leave_requests (start_date ASC);

ALTER TABLE lychee_erp.leave_requests ADD CONSTRAINT fk_leave_requests_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.leave_requests ADD CONSTRAINT fk_leave_requests_employee FOREIGN KEY (employee_id) REFERENCES lychee_erp.employees (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.leave_requests ADD CONSTRAINT fk_leave_requests_type FOREIGN KEY (leave_type_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.leave_requests ADD CONSTRAINT fk_leave_requests_status FOREIGN KEY (status_option_id) REFERENCES lychee_erp.option_values (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.leave_requests ADD CONSTRAINT fk_leave_requests_approver FOREIGN KEY (approver_id) REFERENCES lychee_erp.employees (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.leave_requests ADD CONSTRAINT fk_leave_requests_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.leave_requests ADD CONSTRAINT fk_leave_requests_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


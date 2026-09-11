DROP TABLE IF EXISTS lychee_erp.job_titles CASCADE;

CREATE TABLE lychee_erp.job_titles
(
    id bigserial NOT NULL,
    tenant_id bigint NOT NULL,
    code varchar(50) NOT NULL,
    name varchar(100) NOT NULL,
    description text NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone NULL,
    updated_at timestamp without time zone NULL,
    created_by bigint NULL,
    updated_by bigint NULL
);

ALTER TABLE lychee_erp.job_titles ADD CONSTRAINT job_titles_pkey PRIMARY KEY (id);
ALTER TABLE lychee_erp.job_titles ADD CONSTRAINT uk_job_titles_tenant_code UNIQUE (tenant_id, code);

ALTER TABLE lychee_erp.job_titles ADD CONSTRAINT fk_job_titles_tenant FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.job_titles ADD CONSTRAINT fk_job_titles_created_by FOREIGN KEY (created_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE lychee_erp.job_titles ADD CONSTRAINT fk_job_titles_updated_by FOREIGN KEY (updated_by) REFERENCES lychee_erp.users (id) ON DELETE No Action ON UPDATE No Action;


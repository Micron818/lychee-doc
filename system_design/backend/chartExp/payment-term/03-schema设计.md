# 03. Schema 设计

> 未上线：以 Liquibase changeset + `lychee-doc/.../schema_tables` 同步为准。  
> 直接替换 `payment_term_option_id`，不做双列过渡。

---

## 1. 改什么、不改什么

| 对象 | 动作 |
|------|------|
| `fi_payment_terms` | **新增** 条件头 |
| `fi_payment_term_lines` | **新增** 条件行 |
| `ap_invoice_schedules` / `ar_invoice_schedules` | **新增** 发票付款排程 |
| `business_partners` | `payment_term_option_id` **改为** `payment_term_id` → `fi_payment_terms` |
| `purchase_orders` / `sales_orders` | 同上 |
| `outsource_orders` | **新增** `payment_term_id` |
| `companies` | **新增** `default_payment_term_id`（可空） |
| `ap_invoices` / `ar_invoices` | **新增** `payment_term_id`、`base_date`；`due_date` **保留**（派生） |
| `payment_lines` | **新增** 可空 `invoice_schedule_id` |
| `customers` / `suppliers` | **不加** 列 |
| `purchase_requisition_*` / 发货 / GR | **不加** |
| 单据行 | **不加** 条件 |
| `option_values` | **不**加 metadata；删除 `PAYMENT_TERM` 类别及值 |
| `option_categories` | 删除 `PAYMENT_TERM`（或种子不再插入） |

`due_date` 注释改为：`MAX(invoice schedules.due_date); not a user-entered field`。

---

## 2. 付款条件头 `fi_payment_terms`

对标 `valuation_classes`：短码、租户唯一、启用标志。基准日类型与往来范围在头上，全行共用。

```sql
CREATE TABLE lychee_erp.fi_payment_terms
(
    id                  bigserial       NOT NULL,
    tenant_id           bigint          NOT NULL,
    code                varchar(50)     NOT NULL,
    name                varchar(100)    NOT NULL,
    base_date_type      varchar(20)     NOT NULL,    -- INVOICE_DATE, SOURCE_DATE
    partner_scope       varchar(20)     NOT NULL DEFAULT 'BOTH', -- BOTH, CUSTOMER, SUPPLIER
    is_active           boolean         NOT NULL DEFAULT true,
    description         text            NULL,
    created_at          timestamp       NULL,
    updated_at          timestamp       NULL,
    created_by          bigint          NULL,
    updated_by          bigint          NULL,
    CONSTRAINT pk_fi_payment_terms PRIMARY KEY (id),
    CONSTRAINT uk_fi_payment_terms UNIQUE (tenant_id, code)
);

CREATE INDEX ix_fi_payment_terms_scope
    ON lychee_erp.fi_payment_terms (tenant_id, partner_scope, is_active);

ALTER TABLE lychee_erp.fi_payment_terms
    ADD CONSTRAINT fk_fi_payment_terms_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
```

建议种子（code 稳定，name 实施可改）：

| code | name | base_date_type | partner_scope | 行（见 §3） |
|------|------|----------------|---------------|-------------|
| `COD` | 货到付款 / 立即 | `INVOICE_DATE` | `BOTH` | IMMEDIATE 100% |
| `NET15` | 票到 15 天 | `INVOICE_DATE` | `BOTH` | NET_DAYS 15 |
| `NET30` | 票到 30 天 | `INVOICE_DATE` | `BOTH` | NET_DAYS 30 |
| `NET60` | 票到 60 天 | `INVOICE_DATE` | `BOTH` | NET_DAYS 60 |
| `EOM0` | 当月月结 | `INVOICE_DATE` | `BOTH` | EOM_PLUS_DAYS 0 |
| `EOM30` | 月结 30 天 | `INVOICE_DATE` | `BOTH` | EOM_PLUS_DAYS 30 |
| `PAY25` | 次月 25 日付款 | `INVOICE_DATE` | `BOTH` | FIXED_DAY 25，`extra_months=1` |
| `210NET30` | 2/10 Net 30 | `INVOICE_DATE` | `BOTH` | NET_DAYS 30 + 折扣 2/10 |
| `SPLIT3070` | 30/70 分两期 | `INVOICE_DATE` | `BOTH` | 30%+30d，70%+60d |
| `GR-NET30` | 收货后 30 天 | `SOURCE_DATE` | `SUPPLIER` | NET_DAYS 30 |

---

## 3. 条件行 `fi_payment_term_lines`

```sql
CREATE TABLE lychee_erp.fi_payment_term_lines
(
    id                  bigserial       NOT NULL,
    tenant_id           bigint          NOT NULL,
    payment_term_id     bigint          NOT NULL,
    line_no             integer         NOT NULL,
    percent             numeric(5,2)    NOT NULL,    -- 30.00 = 30%
    calc_method         varchar(20)     NOT NULL,    -- NET_DAYS, EOM_PLUS_DAYS, FIXED_DAY, IMMEDIATE
    days                integer         NOT NULL DEFAULT 0,
    extra_months        integer         NOT NULL DEFAULT 0,
    fixed_day           integer         NULL,
    discount_percent    numeric(5,2)    NOT NULL DEFAULT 0,
    discount_days       integer         NOT NULL DEFAULT 0,
    created_at          timestamp       NULL,
    updated_at          timestamp       NULL,
    created_by          bigint          NULL,
    updated_by          bigint          NULL,
    CONSTRAINT pk_fi_payment_term_lines PRIMARY KEY (id),
    CONSTRAINT uk_fi_payment_term_lines UNIQUE (tenant_id, payment_term_id, line_no)
);

CREATE INDEX ix_fi_payment_term_lines_term
    ON lychee_erp.fi_payment_term_lines (payment_term_id);

ALTER TABLE lychee_erp.fi_payment_term_lines
    ADD CONSTRAINT fk_fi_ptl_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.fi_payment_term_lines
    ADD CONSTRAINT fk_fi_ptl_term
        FOREIGN KEY (payment_term_id) REFERENCES lychee_erp.fi_payment_terms (id);
ALTER TABLE lychee_erp.fi_payment_term_lines
    ADD CONSTRAINT ck_fi_ptl_percent
        CHECK (percent > 0 AND percent <= 100);
ALTER TABLE lychee_erp.fi_payment_term_lines
    ADD CONSTRAINT ck_fi_ptl_days
        CHECK (days >= 0);
ALTER TABLE lychee_erp.fi_payment_term_lines
    ADD CONSTRAINT ck_fi_ptl_extra_months
        CHECK (extra_months >= 0);
ALTER TABLE lychee_erp.fi_payment_term_lines
    ADD CONSTRAINT ck_fi_ptl_fixed_day
        CHECK (fixed_day IS NULL OR (fixed_day >= 1 AND fixed_day <= 31));
ALTER TABLE lychee_erp.fi_payment_term_lines
    ADD CONSTRAINT ck_fi_ptl_discount
        CHECK (discount_percent >= 0 AND discount_percent <= 100 AND discount_days >= 0);
```

应用层（保存头+行时一次校验，不要只靠 CHECK）：

- 至少一行；`SUM(percent) = 100.00`（`compareTo`）。
- `calc_method = FIXED_DAY` ⇒ `fixed_day` 必填；其余 ⇒ `fixed_day` 必须空。
- `calc_method = IMMEDIATE` ⇒ `days`、`extra_months` 必须为 0。
- `calc_method = NET_DAYS` ⇒ `days >= 0`（0 合法，等于当天净额）。
- `discount_percent > 0` ⇒ 视为启用折扣；`discount_days` 允许 0（当天付）。
- `discount_percent = 0` ⇒ `discount_days` 存 0。

种子行对应 §2 表。`ON DELETE` 头对行：应用层先删行再删头；库用默认 Restrict，避免误删被排程引用的头。

---

## 4. 发票排程

AP / AR 各一张，结构相同（不要合成一张靠 type 区分，与发票头拆表一致）。

```sql
CREATE TABLE lychee_erp.ap_invoice_schedules
(
    id                      bigserial       NOT NULL,
    tenant_id               bigint          NOT NULL,
    invoice_id              bigint          NOT NULL,
    line_no                 integer         NOT NULL,
    payment_term_line_id    bigint          NULL,     -- 主档行；主档改行后仍可空保留快照
    percent                 numeric(5,2)    NOT NULL, -- 生成时快照
    amount                  numeric(18,2)   NOT NULL,
    due_date                date            NOT NULL,
    due_date_overridden     boolean         NOT NULL DEFAULT false,
    discount_percent        numeric(5,2)    NOT NULL DEFAULT 0,
    discount_days           integer         NOT NULL DEFAULT 0,
    discount_until          date            NULL,
    discount_amount         numeric(18,2)   NOT NULL DEFAULT 0,
    created_at              timestamp       NULL,
    updated_at              timestamp       NULL,
    created_by              bigint          NULL,
    updated_by              bigint          NULL,
    CONSTRAINT pk_ap_invoice_schedules PRIMARY KEY (id),
    CONSTRAINT uk_ap_invoice_schedules UNIQUE (tenant_id, invoice_id, line_no)
);

CREATE INDEX ix_ap_invoice_schedules_due
    ON lychee_erp.ap_invoice_schedules (tenant_id, due_date);
CREATE INDEX ix_ap_invoice_schedules_invoice
    ON lychee_erp.ap_invoice_schedules (invoice_id);

ALTER TABLE lychee_erp.ap_invoice_schedules
    ADD CONSTRAINT fk_ap_sch_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.ap_invoice_schedules
    ADD CONSTRAINT fk_ap_sch_invoice
        FOREIGN KEY (invoice_id) REFERENCES lychee_erp.ap_invoices (id);
ALTER TABLE lychee_erp.ap_invoice_schedules
    ADD CONSTRAINT fk_ap_sch_term_line
        FOREIGN KEY (payment_term_line_id) REFERENCES lychee_erp.fi_payment_term_lines (id);
```

`ar_invoice_schedules` 对称，`invoice_id` → `ar_invoices`。

`percent` / 折扣数字是 **生成时快照**：以后改主档行不影响已开发票。`payment_term_line_id` 可空（主档行被实施删除测试数据时），算法不再回读主档。

DRAFT 重建：删除未覆写策略见 `02` §4——改条件则物理删全部排程再插入；只改金额则 UPDATE `amount`/`discount_amount`，保留 `due_date` 若 `due_date_overridden`。

未上线无回填：现有测试发票在 changeset 后若缺排程，过账/保存 DRAFT 时按新规则生成；缺 `payment_term_id` 的测试票 **拒绝过账**（与税码专题「缺税码拒过账」一致）。

---

## 5. 发票头加列

```sql
ALTER TABLE lychee_erp.ap_invoices
    ADD COLUMN payment_term_id bigint NOT NULL,
    ADD COLUMN base_date date NOT NULL;

ALTER TABLE lychee_erp.ap_invoices
    ADD CONSTRAINT fk_ap_invoices_payment_term
        FOREIGN KEY (payment_term_id) REFERENCES lychee_erp.fi_payment_terms (id);

CREATE INDEX ix_ap_invoices_payment_term ON lychee_erp.ap_invoices (payment_term_id);

-- ar_invoices 相同
```

未上线：若库里已有测试发票，changeset 先加可空 → 用种子 `NET30` + `base_date = invoice_date` 回填 → 再 `NOT NULL`。**不要**用 30 天公式回填 `due_date` 充数而不写排程；回填后必须跑一遍 `resolveSchedule` 写排程。

`due_date` 保持 `NOT NULL`，由服务写入 max(排程)。

---

## 6. 往来 / 业务单 / 公司 FK 替换

```sql
-- business_partners
ALTER TABLE lychee_erp.business_partners
    DROP CONSTRAINT IF EXISTS fk_business_partners_payment_term;
ALTER TABLE lychee_erp.business_partners
    DROP COLUMN payment_term_option_id;
ALTER TABLE lychee_erp.business_partners
    ADD COLUMN payment_term_id bigint NULL;
ALTER TABLE lychee_erp.business_partners
    ADD CONSTRAINT fk_business_partners_payment_term
        FOREIGN KEY (payment_term_id) REFERENCES lychee_erp.fi_payment_terms (id);

-- purchase_orders、sales_orders：同样 drop option 列，加 payment_term_id NULL
-- 开单应用层必填；schema 可空以免阻断未完成的草稿测试（保存 API 仍 400）

ALTER TABLE lychee_erp.outsource_orders
    ADD COLUMN payment_term_id bigint NULL;
ALTER TABLE lychee_erp.outsource_orders
    ADD CONSTRAINT fk_outsource_orders_payment_term
        FOREIGN KEY (payment_term_id) REFERENCES lychee_erp.fi_payment_terms (id);

ALTER TABLE lychee_erp.companies
    ADD COLUMN default_payment_term_id bigint NULL;
ALTER TABLE lychee_erp.companies
    ADD CONSTRAINT fk_companies_default_payment_term
        FOREIGN KEY (default_payment_term_id) REFERENCES lychee_erp.fi_payment_terms (id);
```

`schema_tables` 同步：`FI/business_partners.sql`、`FI/ap_invoices.sql`、`FI/ar_invoices.sql`、`SCM/purchase_orders.sql`、`SCM/outsource_orders.sql`、`SD/sales_orders.sql`、`BASIS/companies.sql`，并新增：

- `FI/fi_payment_terms.sql`
- `FI/fi_payment_term_lines.sql`
- `FI/ap_invoice_schedules.sql`
- `FI/ar_invoice_schedules.sql`

---

## 7. 收付预留

```sql
ALTER TABLE lychee_erp.payment_lines
    ADD COLUMN invoice_schedule_id bigint NULL;

ALTER TABLE lychee_erp.payment_lines
    ADD CONSTRAINT fk_payment_lines_invoice_schedule
        FOREIGN KEY (invoice_schedule_id) REFERENCES lychee_erp.ap_invoice_schedules (id);
```

AR 核销不能指向 AP 排程。两种做法（锁定 **方案 B**）：

- A：一列 + 应用层校验类型（易指错表）。  
- **B：两列** `ap_invoice_schedule_id` / `ar_invoice_schedule_id`，与现网 `ap_invoice_id` / `ar_invoice_id` 对称。

```sql
ALTER TABLE lychee_erp.payment_lines
    ADD COLUMN ap_invoice_schedule_id bigint NULL,
    ADD COLUMN ar_invoice_schedule_id bigint NULL;

ALTER TABLE lychee_erp.payment_lines
    ADD CONSTRAINT fk_payment_lines_ap_schedule
        FOREIGN KEY (ap_invoice_schedule_id) REFERENCES lychee_erp.ap_invoice_schedules (id);
ALTER TABLE lychee_erp.payment_lines
    ADD CONSTRAINT fk_payment_lines_ar_schedule
        FOREIGN KEY (ar_invoice_schedule_id) REFERENCES lychee_erp.ar_invoice_schedules (id);
```

应用层：`INVOICE` 分配时若填了 schedule，必须与同行的 `ap_invoice_id` / `ar_invoice_id` 同属一张票。本波 UI 可不填。

---

## 8. 下线 ADM 选项

```sql
-- 在 FK 都改完之后
DELETE FROM lychee_erp.option_values ov
 USING lychee_erp.option_categories oc
 WHERE ov.category_id = oc.id AND oc.code = 'PAYMENT_TERM';

DELETE FROM lychee_erp.option_categories WHERE code = 'PAYMENT_TERM';
```

种子脚本、`initial_data`、权限若写死该 category，一并删。前端 `api.typings.ts` 的 `'PAYMENT_TERM'` 联合类型去掉。

---

## 9. 枚举

| 枚举 | 值 |
|------|-----|
| `PaymentTermBaseDateType` | `INVOICE_DATE`, `SOURCE_DATE` |
| `PaymentTermPartnerScope` | `BOTH`, `CUSTOMER`, `SUPPLIER` |
| `PaymentTermCalcMethod` | `NET_DAYS`, `EOM_PLUS_DAYS`, `FIXED_DAY`, `IMMEDIATE` |

进 `lychee-erp-common`，`EnumController` 同步。不要把天数放进枚举。

---

## 10. 模块归属

| 表 / API | 模块 |
|----------|------|
| `fi_payment_terms` / lines CRUD、`resolve-schedule` | `lychee-erp-fi` |
| `RemotePaymentTermService` | 契约 `lychee-erp-common`；实现 FI |
| `PaymentTermScheduleService`（纯函数 + 写排程） | FI；算法单测放 FI |
| `ap/ar_invoice_schedules` | FI |
| `companies.default_payment_term_id` | `lychee-erp-basis` |
| BP `payment_term_id` | FI |
| PO / 委外 | SCM |
| SO | SD |
| 前端主数据 | `lychee-frontend/src/pages/fi/payment-terms` |

跨模块禁止 SCM 直接 import FI 实体。

---

## 11. 数据流（从收货开一张 AP）

```text
1. 读 GR → PO.payment_term_id（空则 partner.payment_term_id，再空则失败）
2. scope 必须 BOTH 或 SUPPLIER
3. base_date = 条件.base_date_type == SOURCE_DATE ? min(GR.receiptDate) : invoice_date
4. 创建发票头：payment_term_id, base_date, due_date 占位（= base_date）
5. 写行、recalculate totals → total_amount
6. resolveSchedule(term, base_date, total) → 插入 ap_invoice_schedules
7. header.due_date = max(schedules)
```

手工票：步骤 3 的 SOURCE_DATE 退化为 `invoice_date`。  
改 DRAFT 合计：从步骤 6 重来（覆写规则见 `02`）。

---

## 12. 文档与过期描述对齐

实施时同步：

- `schema_tables`：§6 清单。
- `FI_schema_design.md`：付款条件子域；BP / 发票栏位；排程；过期「option_values」表述。
- `SCM_schema_design.md` / `SD_schema_design.md`：PO/SO/委外 FK 改指向 `fi_payment_terms`。
- `CRM_schema_design.md` 等仍写 `payment_term_option_id` 的段落。
- Liquibase：`lychee-erp/src/main/resources/db/changelog/v1/2026/`（格式见 `0710-001-valuation-class-account-determination.sql`）。
- `All_menu_design.md` 的 `default_payment_term` 落到 `companies.default_payment_term_id`。

---

## 13. 与税码 / 收付 / 采购工作台

- 税码专题改行税额会改表头 `total_amount` → 必须触发排程金额重摊（同一保存事务）。  
- 采购来源清单、末次价 **不改**。  
- 工作台只带 `paymentTermId`，不算到期日。  
- 收付核销、付款建议 UI **不在本波改交互**；只加 schedule FK。

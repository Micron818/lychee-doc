# 03. Schema 设计

> 未上线：以 Liquibase changeset + `lychee-doc/.../schema_tables` 同步为准。  
> 命名一律 **应付贷项 / `AP_CREDIT_MEMO`**。

---

## 1. 改什么、不改什么

| 对象 | 动作 |
|------|------|
| `ap_credit_memos` / `ap_credit_memo_lines` | **新增**（FI） |
| `ap_invoices.credited_amount` | **新增**：已过账未作废贷项合计 |
| `DocumentTypeEnum.AP_CREDIT_MEMO` | **新增** |
| `ap_invoices` 加类型位 / 负数量 | **不** |
| 贷项排程表 | **不加** |
| 贷项核销中间表 | **不加**（1:1 原票 + 行上 `original_ap_invoice_line_id`） |
| `goods_receipt_items` 新列 | **不加**；占用仍用 `invoiced_quantity` |
| 采购退货表 | **不改** |

---

## 2. 表头 `ap_credit_memos`

```sql
CREATE TABLE lychee_erp.ap_credit_memos
(
    id                          bigserial       NOT NULL,
    tenant_id                   bigint          NOT NULL,
    company_id                  bigint          NOT NULL,
    code                        varchar(50)     NOT NULL,
    external_credit_note_no     varchar(50)     NOT NULL,
    original_ap_invoice_id      bigint          NOT NULL,
    credit_date                 date            NOT NULL,
    partner_id                  bigint          NOT NULL,
    partner_code                varchar(50)     NOT NULL,
    partner_name                varchar(100)    NOT NULL,
    currency_option_id          bigint          NOT NULL,
    exchange_rate               numeric(18,6)   NOT NULL DEFAULT 1,
    subtotal_amount             numeric(18,2)   NOT NULL DEFAULT 0,
    tax_amount                  numeric(18,2)   NOT NULL DEFAULT 0,
    total_amount                numeric(18,2)   NOT NULL DEFAULT 0,
    invoice_status              varchar(20)     NOT NULL DEFAULT 'DRAFT',
    -- DRAFT, PENDING_APPROVAL, APPROVED, POSTED, VOIDED
    journal_entry_id            bigint          NULL,
    approved_at                 timestamp       NULL,
    approved_by                 bigint          NULL,
    posted_at                   timestamp       NULL,
    posted_by                   bigint          NULL,
    voided_at                   timestamp       NULL,
    voided_by                   bigint          NULL,
    remarks                     text            NULL,
    created_at                  timestamp       NULL,
    updated_at                  timestamp       NULL,
    created_by                  bigint          NULL,
    updated_by                  bigint          NULL,
    CONSTRAINT pk_ap_credit_memos PRIMARY KEY (id),
    CONSTRAINT uk_ap_credit_memos_code UNIQUE (tenant_id, company_id, code),
    CONSTRAINT uk_ap_credit_memos_ext_no
        UNIQUE (tenant_id, company_id, partner_id, external_credit_note_no)
);

CREATE INDEX idx_ap_credit_memos_original
    ON lychee_erp.ap_credit_memos (original_ap_invoice_id);
CREATE INDEX idx_ap_credit_memos_status
    ON lychee_erp.ap_credit_memos (tenant_id, company_id, invoice_status);
CREATE INDEX idx_ap_credit_memos_partner
    ON lychee_erp.ap_credit_memos (partner_id);
CREATE INDEX idx_ap_credit_memos_journal
    ON lychee_erp.ap_credit_memos (journal_entry_id);
CREATE INDEX idx_ap_credit_memos_date
    ON lychee_erp.ap_credit_memos (credit_date);

ALTER TABLE lychee_erp.ap_credit_memos
    ADD CONSTRAINT fk_ap_credit_memos_company
        FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id);
ALTER TABLE lychee_erp.ap_credit_memos
    ADD CONSTRAINT fk_ap_credit_memos_original
        FOREIGN KEY (original_ap_invoice_id) REFERENCES lychee_erp.ap_invoices (id);
ALTER TABLE lychee_erp.ap_credit_memos
    ADD CONSTRAINT fk_ap_credit_memos_partner
        FOREIGN KEY (partner_id) REFERENCES lychee_erp.business_partners (id);
ALTER TABLE lychee_erp.ap_credit_memos
    ADD CONSTRAINT fk_ap_credit_memos_currency
        FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id);
ALTER TABLE lychee_erp.ap_credit_memos
    ADD CONSTRAINT fk_ap_credit_memos_journal
        FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id);
```

| 栏位 | 说明 |
|------|------|
| `code` | 单号，`DocumentTypeEnum.AP_CREDIT_MEMO`。建议前缀 `CM`、按月重置，对标 `AP_INVOICE` |
| `external_credit_note_no` | 供应商贷项号；草稿用 `PENDING-`+UUID 占位符（对标 AP），提交后必填且按伙伴唯一 |
| `original_ap_invoice_id` | 一张贷项只对一张已过账 AP |
| `credit_date` | 凭证 `postDate`；已关期间由过账服务拦截。本波不强制 ≥ 原票 `invoice_date` |
| `partner_*` / 币别 / 汇率 | 原票快照，不可改 |
| `invoice_status` | 与 AP 同一套 `FiDocumentStatus`。无 `payment_status`（过账即全额核销） |
| `journal_entry_id` | 本单凭证；VOID 后置空 |

不加 `payment_term_id` / `due_date` / `remaining_amount`。

---

## 3. 明细 `ap_credit_memo_lines`

```sql
CREATE TABLE lychee_erp.ap_credit_memo_lines
(
    id                              bigserial       NOT NULL,
    tenant_id                       bigint          NOT NULL,
    credit_memo_id                  bigint          NOT NULL,
    line_no                         integer         NOT NULL,
    original_ap_invoice_line_id     bigint          NOT NULL,
    description                     varchar(255)    NOT NULL,
    quantity                        numeric(18,6)   NOT NULL DEFAULT 1,
    unit_price                      numeric(18,4)   NOT NULL DEFAULT 0,
    line_amount                     numeric(18,2)   NOT NULL DEFAULT 0,
    source_amount                   numeric(18,2)   NULL,
    tax_code_id                     bigint          NULL,
    tax_rate                        numeric(5,2)    NOT NULL DEFAULT 0,
    tax_amount                      numeric(18,2)   NOT NULL DEFAULT 0,
    tax_amount_overridden           boolean         NOT NULL DEFAULT false,
    total_amount                    numeric(18,2)   NOT NULL DEFAULT 0,
    gl_account_id                   bigint          NULL,
    department_id                   bigint          NULL,
    source_doc_type                 varchar(50)     NOT NULL,
    source_doc_id                   bigint          NULL,
    source_doc_no                   varchar(50)     NOT NULL,
    source_line_id                  bigint          NULL,
    source_line_no                  integer         NULL,
    material_id                     bigint          NULL,
    material_code                   varchar(50)     NULL,
    material_name                   varchar(200)    NULL,
    uom_code                        varchar(20)     NULL,
    remarks                         text            NULL,
    created_at                      timestamp       NULL,
    updated_at                      timestamp       NULL,
    created_by                      bigint          NULL,
    updated_by                      bigint          NULL,
    CONSTRAINT pk_ap_credit_memo_lines PRIMARY KEY (id),
    CONSTRAINT uk_ap_credit_memo_lines_no
        UNIQUE (tenant_id, credit_memo_id, line_no),
    CONSTRAINT uk_ap_credit_memo_lines_original
        UNIQUE (tenant_id, credit_memo_id, original_ap_invoice_line_id)
);

CREATE INDEX ix_ap_credit_memo_lines_header
    ON lychee_erp.ap_credit_memo_lines (credit_memo_id);
CREATE INDEX ix_ap_credit_memo_lines_original
    ON lychee_erp.ap_credit_memo_lines (original_ap_invoice_line_id);
CREATE INDEX ix_ap_credit_memo_lines_source
    ON lychee_erp.ap_credit_memo_lines (source_doc_type, source_doc_id, source_line_id);

ALTER TABLE lychee_erp.ap_credit_memo_lines
    ADD CONSTRAINT fk_ap_credit_memo_lines_header
        FOREIGN KEY (credit_memo_id)
        REFERENCES lychee_erp.ap_credit_memos (id);
ALTER TABLE lychee_erp.ap_credit_memo_lines
    ADD CONSTRAINT fk_ap_credit_memo_lines_original
        FOREIGN KEY (original_ap_invoice_line_id)
        REFERENCES lychee_erp.ap_invoice_lines (id);
ALTER TABLE lychee_erp.ap_credit_memo_lines
    ADD CONSTRAINT fk_ap_credit_memo_lines_gl
        FOREIGN KEY (gl_account_id) REFERENCES lychee_erp.gl_accounts (id);
ALTER TABLE lychee_erp.ap_credit_memo_lines
    ADD CONSTRAINT fk_ap_credit_memo_lines_tax
        FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id);
ALTER TABLE lychee_erp.ap_credit_memo_lines
    ADD CONSTRAINT fk_ap_credit_memo_lines_dept
        FOREIGN KEY (department_id) REFERENCES lychee_erp.departments (id);
```

| 栏位 | 说明 |
|------|------|
| `original_ap_invoice_line_id` | 必须属于表头原票；同单不重复 |
| `quantity` / `unit_price` / 金额 | 正数；单价来自原行 |
| `source_amount` | 原行暂估按数量比例；过账用来贷 GR/IR |
| `source_doc_*` | 从原 AP 行复制，过账回减占用时用 `RECEIPT` + `source_line_id` |
| `gl_account_id` | 从原行复制（GRIR / CIP / EXPENSE） |

可贷数量跨单用 SUM(POSTED 行) + 其他草稿，不要在 AP 行上加 `credited_quantity`（单据单位无双单位换算问题，避免双写）。

---

## 4. AP 表头 `credited_amount`

```sql
ALTER TABLE lychee_erp.ap_invoices
    ADD COLUMN credited_amount numeric(18,2) NOT NULL DEFAULT 0;

COMMENT ON COLUMN lychee_erp.ap_invoices.credited_amount
    IS '已过账未作废应付贷项合计。remaining = total − paid − credited_amount';
```

付款核销、贷项过账/VOID、重算剩余都用该注释公式。  
`paid_amount` 语义不变（仅资金核销）。

---

## 5. 枚举与凭证

### 5.1 `DocumentTypeEnum`

新增 `AP_CREDIT_MEMO`。单号、行号、操作日志用此值。种子 `sys_doc_rule`（`prefix = CM`，`yyyyMM`，4 位，MONTHLY）。

### 5.2 凭证

```text
source_module    = AP
source_doc_type  = AP_CREDIT_MEMO
source_doc_id    = ap_credit_memos.id
```

`journal_entries.source_doc_type` 注释补上该值。

不新增 `JournalSourceModule`、不新增 `FiPostingKey`。

`ApInvoiceLineSourceDocType` **不**加 `PURCHASE_RETURN`（贷项来源是 AP 行，不是退货单）。

---

## 6. 模块归属

| 表 / API | 模块 |
|----------|------|
| `ap_credit_memos` CRUD / 过账 / VOID | `lychee-erp-fi` |
| `credited_amount` | FI 过账回写 |
| 占用 | 现有 WM `updateInvoicedQuantity` |
| 已过账退货查询 | WM `RemotePurchaseReturnService`（新方法） |
| 前端 | `lychee-frontend/src/pages/fi/ap-credit-memos` |
| 菜单 | `/fi/ap-credit-memos`（建议代码 `FI3025`，排序 803025，夹在应付发票与付款之间） |

---

## 7. 落库顺序（过账）

```text
1. 锁 ap_credit_memos、原 ap_invoices、原 ap_invoice_lines
2. 校验 POSTED 原票、APPROVED 本单、creditableQty、total ≤ remaining、未成卡
3. 生成凭证（借贷对调）→ journal_entry_id
4. 原票 credited_amount += total；remaining = total − paid − credited；刷新 payment_status
5. RECEIPT 行 updateInvoicedQuantity(−qty)
6. invoice_status = POSTED；posted_by / posted_at
```

VOID：先 `existsPostedByOriginalReceiptItemIds`；通过则冲凭证、+占用、−credited_amount。  
+占用若超 cap（后续 AP 已重新占用，或粗闸漏过的退货），事务回滚。

并发：两张草稿同时过账同一 AP 时，步骤 1–2 锁原票，第二笔 remaining / creditableQty 失败回滚。  
占用回写：`updateInvoicedQuantity` 现网对收货行是 `findById` 无锁；采购退货过账已用 `findAllByIdForUpdate`。本波过账/VOID 必须锁收货行——**优先改 WM `updateInvoicedQuantity` 内部**（AP 现网同路径一并受益），不要在 FI 再抄一套无锁写。

---

## 8. 文档与 schema_tables 对齐（实施时）

与 [04 §4.5](./04-实施清单.md) 同一清单。

- Liquibase：建表、`credited_amount`、单号规则（`lychee-erp/.../db/changelog/v1/2026/`）
- `schema_tables/FI/ap_credit_memos.sql`、`ap_credit_memo_lines.sql`；`ap_invoices.sql` 加列
- `journal_entries.sql` 注释补 `AP_CREDIT_MEMO`
- 菜单 `/fi/ap-credit-memos`（`FI3025`，803025）
- `database/FI_schema_design.md`：新增应付贷项；AP 表补 `credited_amount`
- 采购退货 `02` §7、`03`「AP 贷项表不加」、`04` 决策 3 改为指向本目录
- `财务/06.3.固定資產MVP.md`：成卡行禁止贷项（本波落地的最小闸，仍不做原值调整）
- `财务/02.1-API端点与状态矩阵.md` §十：关帐未过账单据清单补应付贷项（按 `credit_date`）

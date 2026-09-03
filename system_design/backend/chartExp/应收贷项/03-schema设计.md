# 03. Schema 设计

> 未上线：以 Liquibase changeset + `schema_tables` 同步为准。  
> 命名一律 **应收贷项 / `AR_CREDIT_MEMO`**。  
> 拆分字段与应付贷项当前库对齐（含待退款），不要分两次加列。

---

## 1. 改什么、不改什么

| 对象 | 动作 |
|------|------|
| `ar_credit_memos` / `ar_credit_memo_lines` | **新增**（FI） |
| `ar_invoices.credited_amount` | **新增** |
| `ar_invoices.applied_credit_amount` | **新增** |
| `DocumentTypeEnum.AR_CREDIT_MEMO` | **新增** |
| `ar_invoices` 加类型位 / 负数量 | **不** |
| 贷项排程表 | **不加** |
| `delivery_items` 新列 | **不加**；占用仍用 `invoiced_quantity` |
| 客户退货表 | **不改** |

---

## 2. 表头 `ar_credit_memos`

```sql
CREATE TABLE lychee_erp.ar_credit_memos
(
    id                          bigserial       NOT NULL,
    tenant_id                   bigint          NOT NULL,
    company_id                  bigint          NOT NULL,
    code                        varchar(50)     NOT NULL,
    tax_credit_note_no          varchar(50)     NOT NULL,
    original_ar_invoice_id      bigint          NOT NULL,
    credit_date                 date            NOT NULL,
    partner_id                  bigint          NOT NULL,
    partner_code                varchar(50)     NOT NULL,
    partner_name                varchar(100)    NOT NULL,
    currency_option_id          bigint          NOT NULL,
    exchange_rate               numeric(18,6)   NOT NULL DEFAULT 1,
    subtotal_amount             numeric(18,2)   NOT NULL DEFAULT 0,
    tax_amount                  numeric(18,2)   NOT NULL DEFAULT 0,
    total_amount                numeric(18,2)   NOT NULL DEFAULT 0,
    applied_amount              numeric(18,2)   NOT NULL DEFAULT 0,
    refundable_amount           numeric(18,2)   NOT NULL DEFAULT 0,
    applied_base_amount         numeric(18,2)   NOT NULL DEFAULT 0,
    refundable_base_amount      numeric(18,2)   NOT NULL DEFAULT 0,
    refunded_amount             numeric(18,2)   NOT NULL DEFAULT 0,
    refund_remaining_amount     numeric(18,2)   NOT NULL DEFAULT 0,
    refund_status               varchar(20)     NOT NULL DEFAULT 'NOT_REQUIRED',
    invoice_status              varchar(20)     NOT NULL DEFAULT 'DRAFT',
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
    CONSTRAINT pk_ar_credit_memos PRIMARY KEY (id),
    CONSTRAINT uk_ar_credit_memos_code UNIQUE (tenant_id, company_id, code),
    CONSTRAINT uk_ar_credit_memos_tax_no
        UNIQUE (tenant_id, company_id, partner_id, tax_credit_note_no)
);
```

索引：`original_ar_invoice_id`、`(tenant_id, company_id, invoice_status)`、`partner_id`、`journal_entry_id`、`credit_date`。  
部分索引：`POSTED && refund_remaining_amount > 0`（供可退款查询）。

CHECK：金额非负；`refunded_amount ≤ refundable_amount`。等式由服务层在锁内校验。

| 栏位 | 说明 |
|------|------|
| `code` | `DocumentTypeEnum.AR_CREDIT_MEMO`。前缀 `RM`，`yyyyMM` + 4 位月重置 |
| `tax_credit_note_no` | 开给客户的税务贷项号；草稿 `PENDING-`+UUID；提交后必填且按伙伴唯一。**不是** `external_credit_note_no` |
| `original_ar_invoice_id` | 一张贷项只对一张已过账 AR |
| `invoice_status` | 与 AR 同一套 `FiDocumentStatus` |
| `refund_status` | `NOT_REQUIRED, UNREFUNDED, PARTIAL, REFUNDED` |

不加 `payment_term_id` / `due_date` / `remaining_amount`。

外键：company、original AR、partner、currency、journal。

---

## 3. 明细 `ar_credit_memo_lines`

结构对标 `ap_credit_memo_lines`：

- `original_ar_invoice_line_id`（同单唯一）
- 正数 `quantity` / `unit_price` / 金额 / 税
- `source_doc_type` / `source_doc_id` / `source_line_id` 从原 AR 行复制（过账回减占用用 `SHIPMENT` + `source_line_id`）
- `gl_account_id` 从原行复制（收入科目）
- 唯一：`(tenant_id, credit_memo_id, line_no)`、`(tenant_id, credit_memo_id, original_ar_invoice_line_id)`

---

## 4. AR 发票

```sql
ALTER TABLE lychee_erp.ar_invoices
    ADD COLUMN credited_amount numeric(18,2) NOT NULL DEFAULT 0,
    ADD COLUMN applied_credit_amount numeric(18,2) NOT NULL DEFAULT 0;

COMMENT ON COLUMN lychee_erp.ar_invoices.credited_amount
    IS '已过账未作废应收贷项总额';
COMMENT ON COLUMN lychee_erp.ar_invoices.applied_credit_amount
    IS '上述贷项中实际冲减本票未收金额的合计';
COMMENT ON COLUMN lychee_erp.ar_invoices.remaining_amount
    IS 'remaining = total_amount − received_amount − applied_credit_amount';
```

```text
0 ≤ applied_credit_amount ≤ credited_amount ≤ total_amount
remaining_amount = total − received − applied_credit ≥ 0
```

现网无历史贷项，两列默认 0，不必回填。过账后校验 remaining 公式，有差异则中止，禁止 `max(0, ...)`。

---

## 5. 模块归属

| 表 / API | 模块 |
|----------|------|
| `ar_credit_memos` CRUD + 过账 | `lychee-erp-fi` |
| 交货占用 | 现有 SD remote |
| 已过账客户退货查询 | WM `RemoteCustomerReturnService` |
| 前端 | `pages/fi/ar-credit-memos` |
| 菜单 | `/fi/ar-credit-memos`（建议 `FI3026`，803026，挂 `/fi/ar-ap`） |

---

## 6. 落库顺序（过账）

```text
1. 锁贷项、原 AR、原 AR 行
2. 重算 quantity 与 grossCreditAvailable
3. 拆 applied / refundableGross
4. 校验实收现金上限
5. 写交易币与重乘本位币快照
6. 完整贷项凭证
7. AR credited / appliedCredit / remaining / receipt_status
8. SHIPMENT 行 updateInvoicedQuantity(−qty)（锁交货行）
9. 贷项 → POSTED
```

---

## 7. 文档同步（代码落地后）

- Liquibase + `schema_tables/FI/ar_credit_memos.sql`、`ar_credit_memo_lines.sql`、`ar_invoices.sql`
- `database/FI_schema_design.md`
- `财务/02.1-API端点与状态矩阵.md`
- 客户退货 `02` §7 指向本目录
- `journal_entries` 注释补 `AR_CREDIT_MEMO`

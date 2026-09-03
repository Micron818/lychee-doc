# 03. Schema 设计

> 未上线：以 Liquibase changeset + `lychee-doc/.../schema_tables` 同步为准。  
> 命名一律 **客户退货 / `CUSTOMER_RETURN`**。

---

## 1. 改什么、不改什么

| 对象 | 动作 |
|------|------|
| `customer_returns` / `customer_return_items` | **新增**（WM） |
| `delivery_items.returned_quantity` | **新增**：已过账客户退货单据单位合计 |
| `stock_issue_items.returned_quantity` | **复用**：`SALES_DELIVERY` 行改为已过账客户退货基本单位合计；内部领料行语义不变 |
| `GoodsReceiptSourceDocType.CUSTOMER_RETURN_ITEM` | **删除**（未实现、无数据） |
| `StockTransactionType.CUSTOMER_RETURN` | **保留**，仅客户退货单过账 / 冲销写入 |
| `deliveries.delivery_type = RETURN` | **不启用** |
| `stock_issue_returns` 覆盖销售出库 | **不** |
| `goods_receipts` 当退货单 | **不** |
| AR 贷项表 | **不加**（独立专题 [应收贷项](../应收贷项/03-schema设计.md)） |
| `sales_order_items.returned_quantity` | **不加**；退货回减 `delivered_quantity` |
| pegging 新类型 | **不加**；用 `original_issue_item_id` |

---

## 2. 表头 `customer_returns`

```sql
CREATE TABLE lychee_erp.customer_returns
(
    id                          bigserial       NOT NULL,
    tenant_id                   bigint          NOT NULL,
    code                        varchar(50)     NOT NULL,
    factory_id                  bigint          NOT NULL,
    return_date                 date            NOT NULL,
    customer_id                 bigint          NOT NULL,
    original_stock_issue_id     bigint          NOT NULL,
    status                      varchar(20)     NOT NULL,    -- DRAFT, POSTED, REVERSED
    currency_option_id          bigint          NULL,
    exchange_rate               numeric(18,6)   NOT NULL DEFAULT 1,
    remarks                     text            NULL,
    journal_entry_id            bigint          NULL,
    approved_by                 bigint          NULL,
    approved_at                 timestamp       NULL,
    created_at                  timestamp       NULL,
    updated_at                  timestamp       NULL,
    created_by                  bigint          NULL,
    updated_by                  bigint          NULL,
    CONSTRAINT pk_customer_returns PRIMARY KEY (id),
    CONSTRAINT uk_customer_returns UNIQUE (tenant_id, code)
);

CREATE INDEX idx_customer_returns_date
    ON lychee_erp.customer_returns (return_date);
CREATE INDEX idx_customer_returns_customer
    ON lychee_erp.customer_returns (customer_id);
CREATE INDEX idx_customer_returns_original_issue
    ON lychee_erp.customer_returns (original_stock_issue_id);
CREATE INDEX idx_customer_returns_journal_entry
    ON lychee_erp.customer_returns (journal_entry_id);

ALTER TABLE lychee_erp.customer_returns
    ADD CONSTRAINT fk_customer_returns_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.customer_returns
    ADD CONSTRAINT fk_customer_returns_factory
        FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id);
ALTER TABLE lychee_erp.customer_returns
    ADD CONSTRAINT fk_customer_returns_customer
        FOREIGN KEY (customer_id) REFERENCES lychee_erp.customers (id);
ALTER TABLE lychee_erp.customer_returns
    ADD CONSTRAINT fk_customer_returns_original_issue
        FOREIGN KEY (original_stock_issue_id) REFERENCES lychee_erp.stock_issues (id);
ALTER TABLE lychee_erp.customer_returns
    ADD CONSTRAINT fk_customer_returns_journal_entry
        FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id);
ALTER TABLE lychee_erp.customer_returns
    ADD CONSTRAINT fk_customer_returns_currency
        FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id);
```

| 栏位 | 说明 |
|------|------|
| `code` | 单号，`DocumentTypeEnum.CUSTOMER_RETURN`。前缀 `CRT`，对标 `PRT` / `SIR`（`yyyyMMdd` + 3 位日重置） |
| `factory_id` | 从原领料复制，不可改 |
| `customer_id` | 从关联交货复制，不可改 |
| `original_stock_issue_id` | 一张退货单只对一张已过账 `SALES_DELIVERY` 领料 |
| `status` | `DRAFT` / `POSTED` / `REVERSED`。无独立审批流 |
| `approved_by` / `approved_at` | 过账人 / 过账时间，不是审批节点 |
| `currency_option_id` / `exchange_rate` | 过账前从交货冻结 |
| `journal_entry_id` | 本单 COGS 冲回凭证；不回写原领料。冲销后退货单此列置空 |

不加 `return_type`、不加 `original_delivery_id`（交货追溯在明细）。一张领料若混客户则不准建单，见 `02` §3.1。

---

## 3. 明细 `customer_return_items`

```sql
CREATE TABLE lychee_erp.customer_return_items
(
    id                          bigserial       NOT NULL,
    tenant_id                   bigint          NOT NULL,
    customer_return_id          bigint          NOT NULL,
    item_no                     integer         NOT NULL,
    original_issue_item_id      bigint          NOT NULL,
    delivery_item_id            bigint          NOT NULL,
    material_id                 bigint          NOT NULL,
    warehouse_id                bigint          NOT NULL,
    batch_no                    varchar(50)     NOT NULL DEFAULT '',
    unit_price                  numeric(18,4)   NOT NULL DEFAULT 0,
    tax_code_id                 bigint          NULL,
    tax_rate                    numeric(5,2)    NULL DEFAULT 0,
    transaction_unit_id         bigint          NOT NULL,
    transaction_quantity        numeric(18,6)   NOT NULL DEFAULT 0,
    base_unit_id                bigint          NOT NULL,
    base_quantity               numeric(18,6)   NOT NULL DEFAULT 0,
    stock_type                  varchar(20)     NOT NULL DEFAULT 'UNRESTRICTED',
    reason_code                 varchar(50)     NULL,
    remarks                     text            NULL,
    created_at                  timestamp       NULL,
    updated_at                  timestamp       NULL,
    created_by                  bigint          NULL,
    updated_by                  bigint          NULL,
    CONSTRAINT pk_customer_return_items PRIMARY KEY (id),
    CONSTRAINT uk_customer_return_items_item_no
        UNIQUE (tenant_id, customer_return_id, item_no),
    CONSTRAINT uk_customer_return_items_original
        UNIQUE (tenant_id, customer_return_id, original_issue_item_id)
);

CREATE INDEX ix_customer_return_items_header
    ON lychee_erp.customer_return_items (customer_return_id);
CREATE INDEX ix_customer_return_items_original
    ON lychee_erp.customer_return_items (original_issue_item_id);
CREATE INDEX ix_customer_return_items_delivery
    ON lychee_erp.customer_return_items (delivery_item_id);
CREATE INDEX ix_customer_return_items_material
    ON lychee_erp.customer_return_items (material_id);

ALTER TABLE lychee_erp.customer_return_items
    ADD CONSTRAINT fk_customer_return_items_header
        FOREIGN KEY (customer_return_id)
        REFERENCES lychee_erp.customer_returns (id) ON DELETE CASCADE;
ALTER TABLE lychee_erp.customer_return_items
    ADD CONSTRAINT fk_customer_return_items_original
        FOREIGN KEY (original_issue_item_id)
        REFERENCES lychee_erp.stock_issue_items (id);
ALTER TABLE lychee_erp.customer_return_items
    ADD CONSTRAINT fk_customer_return_items_delivery
        FOREIGN KEY (delivery_item_id)
        REFERENCES lychee_erp.delivery_items (id);
ALTER TABLE lychee_erp.customer_return_items
    ADD CONSTRAINT fk_customer_return_items_material
        FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id);
ALTER TABLE lychee_erp.customer_return_items
    ADD CONSTRAINT fk_customer_return_items_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id);
ALTER TABLE lychee_erp.customer_return_items
    ADD CONSTRAINT fk_customer_return_items_tax_code
        FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id);
```

| 栏位 | 说明 |
|------|------|
| `original_issue_item_id` | 必须属于表头原领料；同单不重复 |
| `delivery_item_id` | 从原领料行 `source_doc_item_id` 复制并校验，不可改。开票占用与已退交货量用此列 |
| `warehouse_id` / `batch_no` | 从原领料行复制，应用层锁定 |
| `unit_price` / `tax_*` | 交货行快照 |
| `stock_type` | 默认 `UNRESTRICTED`，允许改 |
| `transaction_*` / `base_*` | 双单位；库存 / 领料 `returned_quantity` 用基本单位；可退 vs 开票、回写交货已发用单据单位 |

跨单部分退由领料行 `returned_quantity` + 交货行 `returned_quantity` + 草稿加总控制。

---

## 4. 领料行 / 交货行数量账

```sql
COMMENT ON COLUMN lychee_erp.stock_issue_items.returned_quantity
    IS '已过账反向入库基本单位合计。内部领料=退料；SALES_DELIVERY=客户退货。草稿另按查询加总';

ALTER TABLE lychee_erp.delivery_items
    ADD COLUMN returned_quantity numeric(18,6) NOT NULL DEFAULT 0;

COMMENT ON COLUMN lychee_erp.delivery_items.returned_quantity
    IS '已过账客户退货单据单位合计。可开票 = txn − invoiced − returned；可退还受领料未退量约束';
```

- 仅 `POSTED` 客户退货累加；冲销退货单时减少
- 草稿不写这两列
- `invoiced_quantity` 含义不变（单据单位，含 AR 草稿占用）
- 过账 / 冲销后退货后刷新该交货行与表头 `invoice_status`（总量 = `txn − returned`）

不要在领料行再加 `customer_returned_quantity`。`SALES_DELIVERY` 与内部退料互斥，一列够用。

---

## 5. 枚举与流水账

### 5.1 `StockTransactionType`

`CUSTOMER_RETURN` 已存在，不改名。  
收货冲销回取类型列表：**删除** `CUSTOMER_RETURN`（退货不再走收货单）。  
冲销客户退货单：类型仍为 `CUSTOMER_RETURN`，进出方向对调。

`source_doc_type` / `source_doc_id` 写 `CUSTOMER_RETURN` + 客户退货主档 id；`source_doc_item_id` 写明细 id。

`DELIVERY` 枚举值本波仍不使用，不要用它写客户退货。

### 5.2 `DocumentTypeEnum`

新增 `CUSTOMER_RETURN`。单号规则、行号分配、操作日志用此值。种子对标 `PURCHASE_RETURN` / `STOCK_ISSUE_RETURN`。

### 5.3 删除 `CUSTOMER_RETURN_ITEM`

删除：

- `GoodsReceiptSourceDocType.CUSTOMER_RETURN_ITEM`
- `typeForGoodsReceiptLine` 对应分支
- `GoodsReceiptGenerationServiceImpl` 的 unsupported 分支
- 前端 `SourceDocType` 联合类型中的该值
- `goods_receipt_items.source_doc_type` 注释中的该值

### 5.4 流水账类型清单（改定）

```text
GOODS_RECEIPT, PRODUCTION_RECEIPT, PURCHASE_RETURN, DELIVERY,
CUSTOMER_RETURN, STOCK_ISSUE, STOCK_ISSUE_RETURN,
ADJUSTMENT, STOCK_TRANSFER, BACKFLUSH
```

`CUSTOMER_RETURN`：仅客户退货单过账 / 冲销。不是收货，不是退料，不是采购退货。

---

## 6. 模块归属

| 表 / API | 模块 |
|----------|------|
| `customer_returns` CRUD + 过账 | `lychee-erp-wm` |
| `stock_issue_items.returned_quantity` | WM 过账回写（仅 SALES_DELIVERY） |
| `delivery_items.returned_quantity` + 已发 / SO 已交 | 现有 / 扩展 `RemoteDeliveryService` |
| COGS 冲回 | FI `RemoteCustomerReturnFinanceService` |
| 未开票断言 | FI `RemoteCustomerReturnCreditMemoService`（V1；贷项见 [应收贷项](../应收贷项/README.md)） |
| 前端 | `lychee-frontend/src/pages/wm/customer-returns` |
| 菜单 | `/wm/customer-returns`（建议代码 `WM12`，排序靠采购退货之后如 7030） |

---

## 7. 落库顺序（过账）

```text
1. 锁 customer_returns、原 stock_issue_items、关联 delivery_items
2. CreditMemoService.assertReturnableAgainstInvoice（V1：未开票占用，按交货行共享池）
3. 库存入库 + 写 stock_transactions（CUSTOMER_RETURN）；unit_cost = 原领料流水
4. UPDATE stock_issue_items.returned_quantity
5. UPDATE delivery_items.returned_quantity；刷新 invoice_status
6. RemoteDeliveryService.issueCallback(−txn)（含 SO 负向状态）
7. CreditMemoService.afterPosted（no-op；贷项在 FI 独立过账）
8. postCustomerReturn 凭证（传入冻结 unit_cost + 清尾行金额）→ journal_entry_id
9. approved_by / approved_at；status = POSTED
```

并发：两张草稿同时过账同一领料行或同一交货行未开票池时，步骤 1–2 校验失败回滚。

---

## 8. 文档与 schema_tables 对齐（实施时）

- `database/WM_schema_design.md`：新增 3.x 客户退货；收货来源去掉 `CUSTOMER_RETURN_ITEM`；流水账注明仅客户退货单
- `database/SD_schema_design.md`：交货行补 `returned_quantity`；出货段补一句「客户退货回减已发 / SO 已交」
- `schema_tables/WM/customer_returns.sql`、`customer_return_items.sql`
- `delivery_items.sql`、`stock_issue_items.sql`、`stock_transactions.sql`、`goods_receipt_items.sql` 注释
- Liquibase：`lychee-erp/src/main/resources/db/changelog/v1/2026/`

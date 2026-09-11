# 03. Schema 设计

> 未上线：以 Liquibase changeset + `lychee-doc/.../schema_tables` 同步为准。  
> 命名一律 **采购退货 / `PURCHASE_RETURN`**。

---

## 1. 改什么、不改什么

| 对象 | 动作 |
|------|------|
| `purchase_returns` / `purchase_return_items` | **新增**（WM） |
| `goods_receipt_items.returned_quantity` | **新增**：已过账采购退货基本单位合计 |
| `StockTransactionType.VENDOR_RETURN` | **改名为** `PURCHASE_RETURN` |
| `DocumentTypeEnum.PURCHASE_RETURN` | **新增** |
| `GoodsReceiptSourceDocType.PURCHASE_RETURN_ITEM` | **删除**（未实现、无数据） |
| `goods_receipts` 当退货单 | **不** |
| AP 贷项表 | **不加**（独立专题 [应付贷项](../应付贷项/03-schema设计.md)） |
| `purchase_order_items.returned_quantity` | **不加**；退货回减 `received_quantity` |
| pegging 新类型 | **不加**；用 `original_receipt_item_id` |

---

## 2. 表头 `purchase_returns`

```sql
CREATE TABLE lychee_erp.purchase_returns
(
    id                          bigserial       NOT NULL,
    tenant_id                   bigint          NOT NULL,
    code                        varchar(50)     NOT NULL,
    factory_id                  bigint          NOT NULL,
    return_date                 date            NOT NULL,
    supplier_id                 bigint          NOT NULL,
    original_goods_receipt_id   bigint          NOT NULL,
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
    CONSTRAINT pk_purchase_returns PRIMARY KEY (id),
    CONSTRAINT uk_purchase_returns UNIQUE (tenant_id, code)
);

CREATE INDEX idx_purchase_returns_date
    ON lychee_erp.purchase_returns (return_date);
CREATE INDEX idx_purchase_returns_supplier
    ON lychee_erp.purchase_returns (supplier_id);
CREATE INDEX idx_purchase_returns_original_receipt
    ON lychee_erp.purchase_returns (original_goods_receipt_id);
CREATE INDEX idx_purchase_returns_journal_entry
    ON lychee_erp.purchase_returns (journal_entry_id);

ALTER TABLE lychee_erp.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_factory
        FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id);
ALTER TABLE lychee_erp.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_supplier
        FOREIGN KEY (supplier_id) REFERENCES lychee_erp.suppliers (id);
ALTER TABLE lychee_erp.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_original_receipt
        FOREIGN KEY (original_goods_receipt_id) REFERENCES lychee_erp.goods_receipts (id);
ALTER TABLE lychee_erp.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_journal_entry
        FOREIGN KEY (journal_entry_id) REFERENCES lychee_erp.journal_entries (id);
ALTER TABLE lychee_erp.purchase_returns
    ADD CONSTRAINT fk_purchase_returns_currency
        FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id);
```

| 栏位 | 说明 |
|------|------|
| `code` | 单号，`DocumentTypeEnum.PURCHASE_RETURN` |
| `factory_id` / `supplier_id` | 从原收货复制，不可改 |
| `original_goods_receipt_id` | 一张退货单只对一张已过账采购收货 |
| `status` | `DRAFT` / `POSTED` / `REVERSED`。无独立审批流 |
| `approved_by` / `approved_at` | 过账人 / 过账时间（对标 `stock_issue_returns`），不是审批节点 |
| `currency_option_id` / `exchange_rate` | 过账前从收货冻结 |
| `journal_entry_id` | 本单 GR/IR 冲回凭证；不回写原收货。冲销后退货单此列置空 |

不加 `return_type`：V1 只有采购收货。委外退货以后另开，不要提前枚举。

---

## 3. 明细 `purchase_return_items`

```sql
CREATE TABLE lychee_erp.purchase_return_items
(
    id                          bigserial       NOT NULL,
    tenant_id                   bigint          NOT NULL,
    purchase_return_id          bigint          NOT NULL,
    item_no                     integer         NOT NULL,
    original_receipt_item_id    bigint          NOT NULL,
    material_id                 bigint          NOT NULL,
    warehouse_id                bigint          NULL,
    batch_no                    varchar(50)     NOT NULL DEFAULT '',
    is_foc                      boolean         NOT NULL DEFAULT false,
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
    CONSTRAINT pk_purchase_return_items PRIMARY KEY (id),
    CONSTRAINT uk_purchase_return_items_item_no
        UNIQUE (tenant_id, purchase_return_id, item_no),
    CONSTRAINT uk_purchase_return_items_original
        UNIQUE (tenant_id, purchase_return_id, original_receipt_item_id)
);

CREATE INDEX ix_purchase_return_items_header
    ON lychee_erp.purchase_return_items (purchase_return_id);
CREATE INDEX ix_purchase_return_items_original
    ON lychee_erp.purchase_return_items (original_receipt_item_id);
CREATE INDEX ix_purchase_return_items_material
    ON lychee_erp.purchase_return_items (material_id);

ALTER TABLE lychee_erp.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_header
        FOREIGN KEY (purchase_return_id)
        REFERENCES lychee_erp.purchase_returns (id) ON DELETE CASCADE;
ALTER TABLE lychee_erp.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_original
        FOREIGN KEY (original_receipt_item_id)
        REFERENCES lychee_erp.goods_receipt_items (id);
ALTER TABLE lychee_erp.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_material
        FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id);
ALTER TABLE lychee_erp.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_warehouse
        FOREIGN KEY (warehouse_id) REFERENCES lychee_erp.warehouses (id);
ALTER TABLE lychee_erp.purchase_return_items
    ADD CONSTRAINT fk_purchase_return_items_tax_code
        FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id);
```

| 栏位 | 说明 |
|------|------|
| `original_receipt_item_id` | 必须属于表头原收货；同单不重复 |
| `warehouse_id` / `batch_no` | 从原行复制，应用层锁定 |
| `is_foc` / `unit_price` / `tax_*` | 收货快照 |
| `stock_type` | 默认原行，允许改 |
| `transaction_*` / `base_*` | 双单位；库存 / `returned_quantity` 用基本单位；可退 vs 开票、回写 PO 用单据单位。已退单据量 = `SUM(POSTED 同行.transaction_quantity)`，不要把 `returned_quantity` 反换算 |

跨单部分退由 `goods_receipt_items.returned_quantity` + 草稿加总控制，不要在收货行上放「当前草稿 id」。

---

## 4. 收货行数量账

```sql
ALTER TABLE lychee_erp.goods_receipt_items
    ADD COLUMN returned_quantity numeric(18,6) NOT NULL DEFAULT 0;

COMMENT ON COLUMN lychee_erp.goods_receipt_items.returned_quantity
    IS '已过账采购退货基本单位合计。可退单据量 = min(txn − SUM(已过账退货txn) − 草稿txn, txn − invoiced)；FOC 只用未退';
```

- 仅 `POSTED` 采购退货累加；冲销退货单时减少
- 草稿不写本列
- `invoiced_quantity` 含义不变（单据单位，含 AP 草稿占用）
- 过账 / 冲销后退货后刷新该行与表头 `invoice_status`（总量 = `txn − SUM(已过账退货 txn)`）

---

## 5. 枚举与流水账

### 5.1 `StockTransactionType`

```text
VENDOR_RETURN  →  PURCHASE_RETURN
```

同步：Java 枚举、`stock_transactions` 列注释、OpenAPI、前端 `stock-transaction/model.ts`。  
收货冲销回取类型列表：**删除** `VENDOR_RETURN`，**不要**加入 `PURCHASE_RETURN`（退货不再走收货单，正常冲销收货只回取 `GOODS_RECEIPT` / 生产入库等）。  
未上线、无业务数据，直接改名，不做值迁移。

冲销采购退货单：类型仍为 `PURCHASE_RETURN`，进出方向对调（与退料冲销相同）。

`source_doc_type` / `source_doc_id` 写 `PURCHASE_RETURN` + 采购退货主档 id；`source_doc_item_id` 写明细 id。

### 5.2 `DocumentTypeEnum`

新增 `PURCHASE_RETURN`。单号规则、行号分配、操作日志用此值。种子 `document_number_rules`（格式对标 `STOCK_ISSUE_RETURN`）。

### 5.3 删除 `PURCHASE_RETURN_ITEM`

删除：

- `GoodsReceiptSourceDocType.PURCHASE_RETURN_ITEM`
- `typeForGoodsReceiptLine` 对应分支
- `GoodsReceiptGenerationServiceImpl` 的 unsupported 分支
- 前端 `SourceDocType` 联合类型中的该值
- `goods_receipt_items.source_doc_type` 注释中的该值

客户退货 `CUSTOMER_RETURN_ITEM` **保留**（仍未实现）。

### 5.4 流水账类型清单（改定）

```text
GOODS_RECEIPT, PRODUCTION_RECEIPT, PURCHASE_RETURN, DELIVERY,
CUSTOMER_RETURN, STOCK_ISSUE, STOCK_ISSUE_RETURN,
ADJUSTMENT, STOCK_TRANSFER, BACKFLUSH
```

`PURCHASE_RETURN`：仅采购退货单过账 / 冲销。不是客户退货，不是退料。

---

## 6. 模块归属

| 表 / API | 模块 |
|----------|------|
| `purchase_returns` CRUD + 过账 | `lychee-erp-wm` |
| `goods_receipt_items.returned_quantity` | WM 过账回写 |
| PO `received_quantity` | 现有 SCM remote |
| GR/IR 冲回 | FI `RemotePurchaseReturnFinanceService` |
| 未开票断言 | FI `RemotePurchaseReturnCreditMemoService`（V1；贷项见 [应付贷项](../应付贷项/README.md)） |
| 前端 | `lychee-frontend/src/pages/wm/purchase-returns` |
| 菜单 | `/wm/purchase-returns`（代码 / 排序见 `04` §4.6） |

---

## 7. 落库顺序（过账）

```text
1. 锁 purchase_returns、原 goods_receipt_items
2. CreditMemoService.assertReturnableAgainstInvoice（V1：未开票占用）
3. 库存出库 + 写 stock_transactions（PURCHASE_RETURN）；unit_cost = 原收货流水
4. UPDATE goods_receipt_items.returned_quantity；刷新 invoice_status
5. RemotePurchaseOrderItemReceiveService.updateReceivedQuantity(−txn)
   （CLOSED：只改数量不改状态）
6. CreditMemoService.afterPosted（no-op；贷项在 FI 独立过账）
7. postPurchaseReturn 凭证（传入冻结 unit_cost + 清尾行金额）→ journal_entry_id
8. approved_by / approved_at；status = POSTED
```

并发：两张草稿同时过账同一收货行时，步骤 1–2 校验 `returnableTxn` / `unreturnedBase`，第二笔失败回滚。

---

## 8. 文档与 schema_tables 对齐（实施时）

- `database/WM_schema_design.md`：新增 3.x 采购退货；流水账 `VENDOR_RETURN` 改为 `PURCHASE_RETURN`；收货来源去掉 `PURCHASE_RETURN_ITEM`
- `schema_tables/WM/purchase_returns.sql`、`purchase_return_items.sql`
- `goods_receipt_items.sql`、`stock_transactions.sql`、`goods_receipts` 文件路径对照表
- `SCM_schema_design.md`：GR 段补一句「采购退货回减 PO 已收」
- Liquibase：`lychee-erp/src/main/resources/db/changelog/v1/2026/`
- 财务 `08.成本方法实现计划.md` 分析口径仍不含退货，可加指向本目录的一句

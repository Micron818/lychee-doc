# 03. Schema 设计

> 未上线：以 Liquibase changeset + `lychee-doc/.../schema_tables` 同步为准。  
> 溯源继续只用 `order_peggings`，不恢复文档里未落地的 `source_mrp_result_id` / `source_pr_item_id`。

---

## 1. 改什么、不改什么

| 对象 | 动作 |
|------|------|
| `material_suppliers`（新表） | **新增**：厂+料+供应商来源清单 |
| `purchase_orders.source_type` / `mrp_run_id` | **新增**：`MRP` / `PURCHASE_REQUISITION` / `MANUAL`；仅 MRP 记 `mrp_run_id`。**不加**泛型 `source_id` |
| `purchase_requisitions.source_type` / `mrp_run_id` | **删除**（请购不再承接 MRP；单据本身即请购） |
| `mrp_results` | **加** `converted_quantity`；**`is_converted` 改为** `convert_status`（`OPEN` / `PARTIAL` / `CONVERTED`） |
| `purchase_requisitions` / `items` | **保留**，MRP 路径停止写入 |
| `purchase_order_items` | **不加** `source_mrp_result_id` |
| `materials.default_supplier_id` | **不加**（多厂多供应商） |
| `material_factories` | **不加**采购来源栏（该表是仓/倒扣/公差） |
| `order_peggings` | **沿用**；MRP 路径 supply 改为 `PURCHASE_ORDER` |

`mrp_parameters` 继续管批量/提前期/安全库存，不管谁供货。

---

## 2. 物料供应商主档 `material_suppliers`

采购信息记录（Source List + 简版 Info Record）：解决工作台预填供应商与 PO 带价。

### 2.1 DDL（设计稿）

```sql
CREATE TABLE lychee_erp.material_suppliers
(
    id                      bigserial       NOT NULL,
    tenant_id               bigint          NOT NULL,
    factory_id              bigint          NOT NULL,
    material_id             bigint          NOT NULL,
    supplier_id             bigint          NOT NULL,
    is_default              boolean         NOT NULL DEFAULT false,
    purchase_unit_id        bigint          NULL,
    min_order_quantity      numeric(18,6)   NOT NULL DEFAULT 0,
    lead_time_days          numeric(10,2)   NOT NULL DEFAULT 0,
    last_price              numeric(18,4)   NULL,
    currency_option_id      bigint          NULL,
    valid_from              date            NULL,
    valid_to                date            NULL,
    remarks                 text            NULL,
    created_at              timestamp       NULL,
    updated_at              timestamp       NULL,
    created_by              bigint          NULL,
    updated_by              bigint          NULL,
    CONSTRAINT pk_material_suppliers PRIMARY KEY (id),
    CONSTRAINT uk_material_suppliers UNIQUE (tenant_id, factory_id, material_id, supplier_id)
);

CREATE INDEX ix_material_suppliers_material ON lychee_erp.material_suppliers (material_id);
CREATE INDEX ix_material_suppliers_supplier ON lychee_erp.material_suppliers (supplier_id);
CREATE INDEX ix_material_suppliers_factory  ON lychee_erp.material_suppliers (factory_id);

ALTER TABLE lychee_erp.material_suppliers
    ADD CONSTRAINT fk_material_suppliers_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.material_suppliers
    ADD CONSTRAINT fk_material_suppliers_factory
        FOREIGN KEY (factory_id) REFERENCES lychee_erp.factories (id);
ALTER TABLE lychee_erp.material_suppliers
    ADD CONSTRAINT fk_material_suppliers_material
        FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id);
ALTER TABLE lychee_erp.material_suppliers
    ADD CONSTRAINT fk_material_suppliers_supplier
        FOREIGN KEY (supplier_id) REFERENCES lychee_erp.suppliers (id);
ALTER TABLE lychee_erp.material_suppliers
    ADD CONSTRAINT fk_material_suppliers_purchase_unit
        FOREIGN KEY (purchase_unit_id) REFERENCES lychee_erp.material_units (id);
ALTER TABLE lychee_erp.material_suppliers
    ADD CONSTRAINT fk_material_suppliers_currency
        FOREIGN KEY (currency_option_id) REFERENCES lychee_erp.option_values (id);
```

同一 `(tenant, factory, material)` **最多一个** `is_default = true`。用部分唯一索引（PostgreSQL）：

```sql
CREATE UNIQUE INDEX uk_material_suppliers_one_default
    ON lychee_erp.material_suppliers (tenant_id, factory_id, material_id)
    WHERE is_default = true;
```

应用层：保存时若新行 `is_default`，先把同厂同料其他行的默认关掉。

### 2.2 字段说明

| 栏位 | 说明 |
|------|------|
| `factory_id` + `material_id` + `supplier_id` | 来源清单业务键 |
| `is_default` | 工作台预填；转单未传供应商时补齐 |
| `purchase_unit_id` | 空则回退 `materials.purchase_unit_id` / `base_unit_id` |
| `min_order_quantity` | 转单数量校验（0 = 不限制） |
| `lead_time_days` | 仅供展示/参考；MRP 提前期仍读 `mrp_parameters` |
| `last_price` + `currency_option_id` | 生成 PO 明细默认单价；收货后可由服务回写（非本阶段必做） |
| `valid_from` / `valid_to` | 空 = 长期有效；工作台与转单只取当前有效行 |

### 2.3 不放进本表的内容

- 配额比例、多个价格阶梯：以后加子表，不堵上线。  
- 供应商付款条件：仍在 `suppliers` / PO 主档。  
- Lot-sizing：仍在 `mrp_parameters`。

### 2.4 CRUD 与引用保护

- 标准分页 CRUD，模块 **SCM**（或 MM，与供应商维护同角色即可）。  
- 删除前：`exists` 被 DRAFT/OPEN PO 引用不是硬 FK（PO 只存 `supplier_id`+`material_id`），不做级联。停用靠删行或后续加 `active`；V1 用删除 + 转单时查不到则要求手选供应商。  
- 供应商停用（`suppliers.active_status`）时：工作台不预填，转单校验失败。

### 2.5 解析默认供应商

```text
1. material_suppliers WHERE factory + material + is_default + 在有效期内
2. 若无 → 工作台 suggestedSupplierId 为空，提交必须带 supplierId
3. 禁止静默用「任意一条」来源行
```

---

## 3. 采购单主档扩展

```sql
ALTER TABLE lychee_erp.purchase_orders
    ADD COLUMN source_type varchar(20) NOT NULL DEFAULT 'MANUAL';

ALTER TABLE lychee_erp.purchase_orders
    ADD COLUMN mrp_run_id bigint NULL;

COMMENT ON COLUMN lychee_erp.purchase_orders.source_type IS 'MRP, PURCHASE_REQUISITION, MANUAL';

CREATE INDEX ix_purchase_orders_mrp_run ON lychee_erp.purchase_orders (mrp_run_id);

ALTER TABLE lychee_erp.purchase_orders
    ADD CONSTRAINT fk_purchase_orders_mrp_run
        FOREIGN KEY (mrp_run_id) REFERENCES lychee_erp.mrp_runs (id) ON DELETE SET NULL;
```

- 已有数据（若有）`source_type` 默认 `MANUAL`，`mrp_run_id` 为空。
- 枚举：`PurchaseOrderSourceType { MRP, PURCHASE_REQUISITION, MANUAL }`。三种**诞生方式**，创建后不改。不要泛型 `source_id`（PR 与 PO 是 M:N；MRP 用专用 `mrp_run_id`）。
- **为什么要 `source_type`，不能只靠 `mrp_run_id`：**
  1. 请购工作台与空白开单都没有 Run，必须靠枚举区分，并决定明细能否汇入 PR。
  2. FK 为 `ON DELETE SET NULL`：Run 被删后 `mrp_run_id` 变空，若无 `source_type` 会误判成手工单。
  3. 列表/权限要筛「MRP 转出 / 请购转出 / 自开单」。
- **保存 `mrp_run_id`：** 仅 `MRP`；`from-mrp-results` 写入转单当时的 Run。`ON DELETE SET NULL`。
- 约束（应用层）：`MRP` 创建时 `mrp_run_id IS NOT NULL`（Run 删除后允许变空）；`PURCHASE_REQUISITION` / `MANUAL` ⇒ 始终 `mrp_run_id IS NULL`。
- **不加在明细上，也不加 `source_pr_id`。** 行级来源用 pegging。

`from-mrp-results`：`MRP` + `mrp_run_id`。  
`from-pr-items`：`PURCHASE_REQUISITION` 的**唯一建单入口**。  
列表「新增」：固定 `MANUAL`（先主档，再手键）。  
`POST .../{id}/items/from-pr`：仅已有请购类型 DRAFT **补行**。  
手键明细：仅 `MANUAL` + `DRAFT`。

---

## 4. Pegging 约定（MRP 路径）

转 PO 成功后：

| 字段 | 值 |
|------|-----|
| `demand_type` | `MRP_RESULT` |
| `demand_id` | `mrp_results.id` |
| `supply_type` | `PURCHASE_ORDER` |
| `supply_id` | `purchase_order_items.id`（与今日 PR 一样用**明细 id**） |
| `pegged_quantity` | 本次转换量 |
| `material_id` | 建议物料 |

手工 PR → PO **不变**：`PURCHASE_REQUISITION`（item id）→ `PURCHASE_ORDER`（item id）。

剩余量查询：

```text
remaining = required_quantity − converted_quantity
```

`converted_quantity` 与 pegging 在同一事务增减（对标 PR `ordered_quantity`）。转单校验以列为准，pegging 合计应相等；删 DRAFT PO 行时减列并删 pegging，再按数量重算 `convert_status`。

**不要**再写 `MRP_RESULT → PURCHASE_REQUISITION`（原物料路径）。`PeggingOrderType.PURCHASE_REQUISITION` 枚举保留给手工 PR。

---

## 5. `mrp_results`：`converted_quantity` + `convert_status`

### 5.0 为什么要改掉 `is_converted`

As-Is 转 PR **全量、不可部分转**：一行要么没转、要么整行转完。布尔够用：

| `is_converted` | 含义 |
|----------------|------|
| `false` | 从未转；清理时删除 |
| `true` | 已整行转 PR；保留 |

To-Be 允许一行建议拆多次、拆多供应商转 PO。`false` 会叠两种完全不同的行：

| 实际状态 | 布尔怎么写 | 重算该不该删 | 工作台该不该还能转 |
|----------|------------|--------------|-------------------|
| 从未转 | `false` | 删 | 要（若属最新 Run） |
| 已转 40 / 建议 100 | `false` | **不能删**（挂着 PO pegging） | 最新 Run 上还能转剩余；**历史 Run 上不能** |
| 已转满 | `true` | 不删 | 不能 |

现网 `findUnconvertedResultIds` 只看 `is_converted = false`，部分转后会把「已挂 PO 的结果」当未转删掉，并拆 pegging。这不是实现疏漏，是 **布尔定义在部分转后已经不够用**。

只加 `converted_quantity`、继续留布尔，也能算剩余量，但查询/前端/清理仍要把 `false` 再拆一次（`converted_quantity = 0` vs `> 0`）。建议 **删掉布尔，改成三态**，和请购明细「数量账 + 状态」同一模式。

### 5.1 数量账 + 转换状态（对标 PR 明细）

| | PR 明细 | MrpResult（改定） |
|--|---------|-------------------|
| 需求量 | `required_quantity` | `required_quantity` |
| 已转出量 | `ordered_quantity` | **`converted_quantity`** |
| 剩余 | required − ordered | required − converted |
| 进度 | item `status`（含 DRAFT/APPROVED/CLOSED） | **`convert_status`**（仅转换进度） |
| 分到哪张下游单 | pegging `PR → PO` | pegging `MRP_RESULT → PO` |

**不要**复用 `PurchaseRequisitionStatus`（DRAFT / APPROVED / CLOSED 是单据生命周期，MrpResult 没有审核/结案）。  
**不要**复用 `PlannedOrderStatus`（FIRMED 是计划锁定，和「已转多少 PO」不是一回事）。

新枚举 `MrpResultConvertStatus`（列名 `convert_status`）：

| 值 | 判定（同一事务由数量派生，禁止手改） | 重算清理 | 工作台 |
|----|--------------------------------------|----------|--------|
| `OPEN` | `converted_quantity = 0` | **删除** | 仅当属于该厂最新 Run：可转 |
| `PARTIAL` | `0 < converted < required` | **保留** | 仅当属于该厂最新 Run：可转剩余；历史 Run 的 PARTIAL 不进工作台 |
| `CONVERTED` | `converted ≥ required`（与 `remaining ≈ 0` 同一公差） | **保留** | 不可转 |

重算之后旧 `PARTIAL`/`CONVERTED` 行留下作审计，缺口由新 Run 的 `OPEN` 行覆盖。

```sql
ALTER TABLE lychee_erp.mrp_results
    ADD COLUMN converted_quantity numeric(18,6) NOT NULL DEFAULT 0,
    ADD COLUMN convert_status varchar(20) NOT NULL DEFAULT 'OPEN';

ALTER TABLE lychee_erp.mrp_results
    DROP COLUMN IF EXISTS is_converted;

COMMENT ON COLUMN lychee_erp.mrp_results.converted_quantity
    IS '已转入未关闭 PO 的数量；与 MRP_RESULT→PURCHASE_ORDER pegging 合计对齐';
COMMENT ON COLUMN lychee_erp.mrp_results.convert_status
    IS 'OPEN / PARTIAL / CONVERTED；由 converted_quantity 与 required_quantity 派生';
```

新 Run 写入：`converted_quantity = 0`，`convert_status = OPEN`。`suggested_supplier_id` 仍不加。

派生函数（转单、回退共用，禁止只改其一）：

```text
if converted_quantity ≈ 0        → OPEN
else if remainingQty > 0         → PARTIAL
else                             → CONVERTED
```

**同一事务规则（对标 `updateOrderedQuantity`）：**

1. 转 PO：`converted_quantity += convertQty`（不得超过 remaining）；写 pegging；按上式写 `convert_status`。
2. 删 DRAFT PO 行：`converted_quantity -= peggedQty`（下限 0）；删 pegging；按上式写 `convert_status`（可能从 PARTIAL/CONVERTED 回到 OPEN）。
3. 禁止只改列不写 pegging，或只写 pegging 不改列。
4. 禁止把 `convert_status` 当成独立工作流字段去 PATCH。

pegging 回答「哪张 PO 行拿了多少」；`converted_quantity` 回答「这行还剩多少」；`convert_status` 回答「列表/清理该用哪条分支」，避免把「从未转」和「部分转」都叫 false。

### 5.2 部分转 + 重算：会不会删掉这条 MrpResult？

**按 To-Be：不会删。** 删除条件是 **`convert_status = OPEN`**（断言 `converted_quantity = 0`，且无 PO pegging）。

```text
R1 建议 100，先转 40 到 PO
  converted_quantity = 40
  remaining = 60
  convert_status = PARTIAL
重算清理：PARTIAL → 保留 R1
新 Run 另写 R2（OPEN）覆盖缺口（DRAFT PO 开量已计入供给）
```

**按现网引擎：会删，且会拆 pegging。** `findUnconvertedResultIds` 只看 `is_converted = false`。

清理改为：

```text
删除：convert_status = OPEN
      （converted_quantity = 0；可用 NOT EXISTS PO pegging 作断言）
保留：PARTIAL、CONVERTED
且不得删除这些结果上的 PURCHASE_ORDER pegging
```

不要靠把部分转标成 `CONVERTED` 来躲清理。

---

## 6. 请购表：去掉 MRP 来源列

请购只保留「内部申请」语义，不再承接 MRP。未上线，直接删列：

```sql
ALTER TABLE lychee_erp.purchase_requisitions DROP COLUMN IF EXISTS mrp_run_id;
ALTER TABLE lychee_erp.purchase_requisitions DROP COLUMN IF EXISTS source_type;
```

同步删除枚举 `PurchaseRequisitionSourceType`、建 MRP PR 的 remote API、引擎清理 DRAFT MRP PR。  
`suggested_supplier_id`、审核、`ordered_quantity` 保留，供请购类型 PO 汇入使用。

---

## 7. 文档与过期描述对齐

实施时同步改：

- `database/SCM_schema_design.md`：去掉「请购明细必须有 `source_mrp_result_id`」；改为 Pegging；补充 `material_suppliers` 与 `purchase_orders.source_type`。  
- `system_design/mrp/01-current-capability.md` §5.2：转单目标改为 PO，清理对象不再含 DRAFT MRP PR。  
- `system_design/mrp/02-evolution-plan.md`：图中 `MrpResult → 人工转 PLO/PR` 改为 `PLO / PO`。  
- `schema_tables/SCM/`：新增 `material_suppliers.sql`；`purchase_orders.sql` 加 `source_type`/`mrp_run_id`；`purchase_requisitions.sql` 删除 `source_type`/`mrp_run_id`。  
- `schema_tables/PP/mrp_results.sql`：加 `converted_quantity`、`convert_status`；删除 `is_converted`。

---

## 8. 模块归属

| 表 / API | 模块 |
|----------|------|
| `material_suppliers` CRUD | `lychee-erp-scm`（靠近 `suppliers`） |
| `POST .../purchase-orders/from-mrp-results` | `lychee-erp-scm` |
| `POST .../purchase-orders/from-pr-items` | `lychee-erp-scm`（请购一键建单） |
| `POST .../purchase-orders/{id}/items/from-pr` | `lychee-erp-scm`；仅请购类型 DRAFT |
| 待转建议查询 | SCM 调 `RemoteMrpResultService`（`lychee-erp-common` 契约） |
| MRP 清理不再删 PR | `lychee-erp-pp` `MrpCalculationEngine` |
| 前端工作台 | `lychee-frontend/src/pages/scm/purchase-proposals`（或 PO 下抽屉） |

跨模块禁止 PP 直接依赖 SCM 实体：继续走 `Remote*`，与现有转 PR 相同。

---

## 9. 数据流（落库顺序）

一次 `from-mrp-results` 成功提交：

```text
1. 锁 MrpResult 行（或等价乐观校验 remaining）
2. INSERT purchase_orders（每组一张）
3. INSERT purchase_order_items
4. INSERT order_peggings（MRP_RESULT → PURCHASE_ORDER item）
5. UPDATE mrp_results.converted_quantity、convert_status
6. recalculateOrderTotals
```

并发：同一建议被两个会话同时转满时，步骤 1 校验 remaining，第二笔失败回滚。

---

## 10. 与收货 / 财务

本改造不改 `goods_receipts`、AP。GR 仍挂 `purchase_order_item_id`。  
末次价回写 `material_suppliers.last_price` 作为后续增强（可在 GR 过账后更新），不阻塞 V1。

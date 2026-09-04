# 03. Schema 设计

> 未上线：以本文件为设计依据。实施时再同步 Liquibase changeset + `schema_tables/SD/`。  
> 命名一律 **预告订单 / `SALES_FORECAST`**。  
> 旧单表草稿 **不是**依据，见 §8。

---

## 1. 改什么、不改什么

| 对象 | 动作 |
|------|------|
| `sales_forecasts` | **删除重建**为表头（单据） |
| `sales_forecast_items` | **新增**明细 |
| `DocumentTypeEnum.SALES_FORECAST` | **新增**；单号前缀 `SFO` |
| `PeggingOrderType.SALES_FORECAST` | **新增**；id 一律指向 **明细** `sales_forecast_items.id` |
| `FactoryOrderSourceType.FORECAST` | **新增** |
| `order_peggings` 注释 | **扩充**类型清单 |
| `uk_order_peggings` | **重建**为含 `demand_type` / `supply_type`（见 §5.1） |
| `sales_order_items` | **不加** `forecast_item_id` / `consumed_forecast_quantity` |
| `delivery_items.source_doc_type` | **不**加 `SALES_FORECAST` |
| 价税 / 付款 / 地址 / 币别 | **不加**（预告不是商业承诺） |
| `factory_id` | **不加**在预告上（转 FO 时与 SO 一样由生管选厂） |
| MRP 直连播种 `MrpSourceType.FORECAST` | **本波不加**；未转 FO 的预告不算独立需求 |
| 消耗流水子表 | **不加**；消耗量落明细列，追溯用 pegging |
| `status_option_id` | **不用**；状态走枚举列 |

`allocated_quantity` 与 `consumed_quantity` 是两本账，不要合成一列。

---

## 2. 实体关系

```text
customers 1───* sales_forecasts 1───* sales_forecast_items *───1 materials
                     │                         │
                     │                         ├── unit_id → material_units
                     │                         │
                     │                         └── pegging
                     │                               demand SALES_FORECAST → supply FACTORY_ORDER
                     │                               demand SALES_FORECAST → supply SALES_ORDER   （消耗）
                     └── supersedes_id ──► 上一张同客户预告（滚动换版）
```

Pegging 与正式单相同：行级、数量在 `pegged_quantity`，不在预告行上写死下游 FK。

---

## 3. 表头 `sales_forecasts`

一张预告 = 某一客户、某一版本、覆盖若干时间桶的计划单据。

```sql
DROP TABLE IF EXISTS lychee_erp.sales_forecast_items CASCADE;
DROP TABLE IF EXISTS lychee_erp.sales_forecasts CASCADE;

CREATE TABLE lychee_erp.sales_forecasts
(
    id                      bigserial       NOT NULL,
    tenant_id               bigint          NOT NULL,
    company_id              bigint          NOT NULL,
    forecast_no             varchar(50)     NOT NULL,
    forecast_date           date            NOT NULL,
    customer_id             bigint          NOT NULL,
    customer_name           varchar(200)    NULL,
    customer_forecast_no    varchar(50)     NULL,
    version                 varchar(50)     NOT NULL,
    bucket_type             varchar(20)     NOT NULL,    -- DAY, WEEK, MONTH
    sales_person_id         bigint          NULL,
    forecast_status         varchar(20)     NOT NULL,    -- DRAFT, ACTIVE, CLOSED, CANCELLED
    supersedes_id           bigint          NULL,
    confirmed_at            timestamp       NULL,
    confirmed_by            bigint          NULL,
    remarks                 text            NULL,
    created_at              timestamp       NULL,
    updated_at              timestamp       NULL,
    created_by              bigint          NULL,
    updated_by              bigint          NULL,
    CONSTRAINT pk_sales_forecasts PRIMARY KEY (id),
    CONSTRAINT uk_sales_forecasts_no UNIQUE (tenant_id, forecast_no)
);

CREATE UNIQUE INDEX uk_sales_forecasts_one_active
    ON lychee_erp.sales_forecasts (tenant_id, company_id, customer_id)
    WHERE forecast_status = 'ACTIVE';

CREATE UNIQUE INDEX uk_sales_forecasts_customer_version
    ON lychee_erp.sales_forecasts (tenant_id, company_id, customer_id, version)
    WHERE forecast_status IN ('DRAFT', 'ACTIVE');

CREATE INDEX idx_sales_forecasts_date
    ON lychee_erp.sales_forecasts (forecast_date);
CREATE INDEX idx_sales_forecasts_customer
    ON lychee_erp.sales_forecasts (customer_id);
CREATE INDEX idx_sales_forecasts_company
    ON lychee_erp.sales_forecasts (company_id);
CREATE INDEX idx_sales_forecasts_status
    ON lychee_erp.sales_forecasts (forecast_status);
CREATE INDEX idx_sales_forecasts_supersedes
    ON lychee_erp.sales_forecasts (supersedes_id);

ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_company
        FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id);
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_customer
        FOREIGN KEY (customer_id) REFERENCES lychee_erp.customers (id);
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_sales_person
        FOREIGN KEY (sales_person_id) REFERENCES lychee_erp.users (id);
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_confirmed_by
        FOREIGN KEY (confirmed_by) REFERENCES lychee_erp.users (id);
ALTER TABLE lychee_erp.sales_forecasts
    ADD CONSTRAINT fk_sales_forecasts_supersedes
        FOREIGN KEY (supersedes_id) REFERENCES lychee_erp.sales_forecasts (id)
        ON DELETE SET NULL;

COMMENT ON TABLE lychee_erp.sales_forecasts
    IS '客户预告订单表头。计划需求，不可交货/开票';
COMMENT ON COLUMN lychee_erp.sales_forecasts.forecast_no
    IS '系统单号，DocumentTypeEnum.SALES_FORECAST，前缀 SFO';
COMMENT ON COLUMN lychee_erp.sales_forecasts.company_id
    IS 'Selling company（与 sales_orders.company_id 同语义）。ACTIVE/版本唯一键含本列，消耗不得跨公司';
COMMENT ON COLUMN lychee_erp.sales_forecasts.customer_forecast_no
    IS '客户侧预告/Booking 单号，不对系统唯一';
COMMENT ON COLUMN lychee_erp.sales_forecasts.version
    IS '滚动版本号，如 2026W36。同一公司+客户 DRAFT/ACTIVE 内唯一';
COMMENT ON COLUMN lychee_erp.sales_forecasts.bucket_type
    IS 'DAY, WEEK, MONTH。本单全部明细共用';
COMMENT ON COLUMN lychee_erp.sales_forecasts.forecast_status
    IS 'DRAFT, ACTIVE, CLOSED, CANCELLED';
COMMENT ON COLUMN lychee_erp.sales_forecasts.supersedes_id
    IS '本单取代的上一张预告（通常为刚关闭的同客户 ACTIVE）';
```

| 栏位 | 说明 |
|------|------|
| `forecast_no` | 系统单号。`DocumentTypeEnum.SALES_FORECAST`，前缀 `SFO`，规则对标 SO：`yyyyMMdd` + 4 位、日重置 |
| `forecast_date` | 单据日（客户发出日 / 录入日），不是需求日 |
| `company_id` | 必填。与现网 SO 一致，创建时带出，确认后不可改 |
| `customer_id` | 必填。创建后不可改。与 `company_id` 一起构成 ACTIVE / 版本唯一键 |
| `customer_name` | 建档时从客户主档快照，主档改名不回溯 |
| `customer_forecast_no` | 客户自己的预告号；可空；**不加**唯一约束 |
| `version` | 必填。滚动预测版本标签。同一公司+客户在 `DRAFT`/`ACTIVE` 下不可重复（部分唯一索引） |
| `bucket_type` | 必填。本单时间桶粒度，确认后不可改。默认建议 `WEEK` |
| `sales_person_id` | 可空；选客户时可带出主档负责人 |
| `forecast_status` | 见 §6。不用 `option_values` |
| `supersedes_id` | 可空。新版本确认并关闭旧 ACTIVE 时写入，形成换版链 |
| `confirmed_at` / `confirmed_by` | 进入 `ACTIVE` 的人时；不是审批流。取消/关闭不清这两列 |

### 3.1 不放进表头的内容

- 币别、汇率、付款条件、账单/送货地址、价税合计：预告无商业承诺。
- `factory_id`：转 FO 时选厂，与 SO → FO 相同。
- `horizon_start` / `horizon_end`：由明细 `bucket_date` 聚合，不落列。
- 行级 `version`：版本在头上，明细不重复存。

### 3.2 滚动换版（应用层，靠索引兜底）

```text
同一 (tenant, company, customer) 最多一张 ACTIVE
（部分唯一索引 uk_sales_forecasts_one_active）

新版本确认时：
  1. 锁定旧 ACTIVE
  2. 旧单 status = CLOSED（行跟随；不要求开量或 allocated 清零，见 §6）
  3. 新单 supersedes_id = 旧单 id
  4. 新单 status = ACTIVE
```

未关旧单就确认新单 → 唯一索引拒绝。  
`CLOSED` / `CANCELLED` 的历史版本可长期保留，版本号可与新单相同（部分索引不含这两态）。  
两家销售公司对同一客户可以各有一张 ACTIVE，消耗不得跨 `company_id`。

---

## 4. 明细 `sales_forecast_items`

一行 = 本预告单内「一个物料 + 一个时间桶」的计划量。

```sql
CREATE TABLE lychee_erp.sales_forecast_items
(
    id                      bigserial       NOT NULL,
    tenant_id               bigint          NOT NULL,
    sales_forecast_id       bigint          NOT NULL,
    item_no                 integer         NOT NULL,
    material_id             bigint          NOT NULL,
    unit_id                 bigint          NOT NULL,
    bucket_date             date            NOT NULL,
    required_date           date            NOT NULL,
    forecast_quantity       numeric(18,6)   NOT NULL,
    allocated_quantity      numeric(18,6)   NOT NULL DEFAULT 0,
    consumed_quantity       numeric(18,6)   NOT NULL DEFAULT 0,
    customer_item_ref_no    varchar(50)     NULL,
    line_status             varchar(20)     NOT NULL,    -- DRAFT, ACTIVE, CLOSED, CANCELLED
    remarks                 text            NULL,
    created_at              timestamp       NULL,
    updated_at              timestamp       NULL,
    created_by              bigint          NULL,
    updated_by              bigint          NULL,
    CONSTRAINT pk_sales_forecast_items PRIMARY KEY (id),
    CONSTRAINT uk_sales_forecast_items_item_no
        UNIQUE (tenant_id, sales_forecast_id, item_no),
    CONSTRAINT uk_sales_forecast_items_material_bucket
        UNIQUE (tenant_id, sales_forecast_id, material_id, bucket_date),
    CONSTRAINT ck_sales_forecast_items_qty_positive
        CHECK (forecast_quantity > 0),
    CONSTRAINT ck_sales_forecast_items_qty_nonneg
        CHECK (allocated_quantity >= 0 AND consumed_quantity >= 0),
    CONSTRAINT ck_sales_forecast_items_qty_cover
        CHECK (allocated_quantity + consumed_quantity <= forecast_quantity)
);

CREATE INDEX idx_sales_forecast_items_header
    ON lychee_erp.sales_forecast_items (sales_forecast_id);
CREATE INDEX idx_sales_forecast_items_material
    ON lychee_erp.sales_forecast_items (material_id);
CREATE INDEX idx_sales_forecast_items_bucket
    ON lychee_erp.sales_forecast_items (tenant_id, material_id, bucket_date);
CREATE INDEX idx_sales_forecast_items_status
    ON lychee_erp.sales_forecast_items (line_status);

ALTER TABLE lychee_erp.sales_forecast_items
    ADD CONSTRAINT fk_sales_forecast_items_header
        FOREIGN KEY (sales_forecast_id)
        REFERENCES lychee_erp.sales_forecasts (id) ON DELETE CASCADE;
ALTER TABLE lychee_erp.sales_forecast_items
    ADD CONSTRAINT fk_sales_forecast_items_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.sales_forecast_items
    ADD CONSTRAINT fk_sales_forecast_items_material
        FOREIGN KEY (material_id) REFERENCES lychee_erp.materials (id);
ALTER TABLE lychee_erp.sales_forecast_items
    ADD CONSTRAINT fk_sales_forecast_items_unit
        FOREIGN KEY (unit_id) REFERENCES lychee_erp.material_units (id);

COMMENT ON TABLE lychee_erp.sales_forecast_items
    IS '客户预告订单明细。一行 = 物料 + 时间桶';
COMMENT ON COLUMN lychee_erp.sales_forecast_items.bucket_date
    IS '时间桶锚点：DAY=required_date；WEEK=该周 ISO 周一；MONTH=该月 1 日';
COMMENT ON COLUMN lychee_erp.sales_forecast_items.required_date
    IS '需求日，转 FO 时写入 factory_order_items.due_date';
COMMENT ON COLUMN lychee_erp.sales_forecast_items.forecast_quantity
    IS '本行预告数量（单据单位）';
COMMENT ON COLUMN lychee_erp.sales_forecast_items.allocated_quantity
    IS '已转 FactoryOrderItem 且仍挂在本预告上的数量';
COMMENT ON COLUMN lychee_erp.sales_forecast_items.consumed_quantity
    IS '已被正式 sales_order_items 消耗的数量';
COMMENT ON COLUMN lychee_erp.sales_forecast_items.line_status
    IS 'DRAFT, ACTIVE, CLOSED, CANCELLED';
```

| 栏位 | 说明 |
|------|------|
| `item_no` | 行号。`DocumentItemNoAllocator`，对标 SO / FO |
| `material_id` / `unit_id` | 必填。单位取物料销售单位，保存后不随主档变 |
| `bucket_date` | 必填。按表头 `bucket_type` 归一化后的桶起点，**消耗匹配键**之一 |
| `required_date` | 必填。必须落在该 `bucket_date` 所属桶内（应用层校验）。转 FO 的 due date |
| `forecast_quantity` | 必填，`> 0` |
| `allocated_quantity` | 已转 FO、且 Pegging 需求端仍是本行的数量。默认 0。SO 接管 FO 后要从本列减掉 |
| `consumed_quantity` | 已被正式 SO 吃掉的数量。默认 0。只增（取消 SO / 纠错时按流程回减） |
| `customer_item_ref_no` | 客户行参考号，可空 |
| `line_status` | 见 §6。确认后头行联动；允许单行关闭剩余量 |

同一张单、同一物料、同一桶 **只能一行**（`uk_sales_forecast_items_material_bucket`）。要拆多个交期：把 `bucket_type` 设细，或接受桶内只有一个 `required_date`。

跨单 ACTIVE 重复不会发生（每公司每客户一张 ACTIVE）。消耗时：

- 吃未转开量：只扫 **该公司该客户当前 ACTIVE** 且行 `ACTIVE` 的明细。
- 接管：当前 ACTIVE 上 `allocated > 0` 的行（含已单行 CLOSED），以及沿 `supersedes_id` 的 **CLOSED 前序单** 上同料同桶且 `allocated > 0` 的行。回溯终止见 `02` §3.3.1（while + 破环；`allocated` 全 0 的前序单不锁但仍继续走）。

### 4.1 数量账（不落派生列）

```text
open_to_allocate = forecast_quantity − allocated_quantity − consumed_quantity
                 = 还可转 FO 的开量

open_to_consume  = forecast_quantity − consumed_quantity
                 = SO 还可消耗的开量（含已转 FO、待接管的部分）

约束：allocated_quantity + consumed_quantity <= forecast_quantity
```

| 事件 | `allocated` | `consumed` | Pegging |
|------|-------------|------------|---------|
| 转 FO `qty` | +qty | — | `SALES_FORECAST` → `FACTORY_ORDER` |
| 删/退 DRAFT FO 行 `qty` | −qty | — | 删对应 pegging |
| SO 确认消耗 `qty`，该量尚未转 FO | — | +qty | `SALES_FORECAST` → `SALES_ORDER` |
| SO 确认消耗 `qty`，该量已在 FO 上（接管） | −qty | +qty | 原 `FORECAST→FO` 的 pegged 减少；新增 `SALES_ORDER→FO`；新增 `FORECAST→SO` |
| SO 取消并回滚消耗 `qty` | 按接管反向 | −qty | 回滚上述 pegging |

转 FO 校验：`qty ≤ open_to_allocate`，且表头 `ACTIVE`、行 `ACTIVE`。  
SO 吃未转开量：仅 ACTIVE 头行，`qty ≤` 该行当时 `open_to_allocate`。  
SO 接管：ACTIVE 或 CLOSED（换版链上仍有 `allocated`），`t ≤ allocated`。CLOSED 的未转开量视为 0。  
接管时 `allocated` / `consumed` **同一条 UPDATE 改两列**。不要在明细再加 `remaining_quantity`。前端开量按 `02` §5.1 派生；行/头已关闭时显示 0。

### 4.2 `bucket_date` 归一化

| `bucket_type` | `bucket_date` | `required_date` |
|---------------|---------------|-----------------|
| `DAY` | = `required_date` | 任意日 |
| `WEEK` | 该日所在 ISO 周的周一 | 必须落在该周一～周日 |
| `MONTH` | 该月 1 日 | 必须落在该月 |

保存时由服务写入 `bucket_date`，禁止客户端随便填一个与 `required_date` 不一致的桶。消耗 SO 时：用 SO 行 `expected_delivery_date`（空则用表头 `expected_delivery_date`）按 **被匹配那张预告单自己的 `bucket_type`** 算桶，再找 `company_id + customer_id + material_id + bucket_date`。换版链上新旧单 `bucket_type` 可以不同，各自归一化。

---

## 5. Pegging 与外围枚举

### 5.1 `PeggingOrderType`

新增 `SALES_FORECAST`。`demand_id` / `supply_id` 在预告侧 **永远是明细 id**（对标 SO item / FO item）。

`order_peggings` 注释改为包含 `SALES_FORECAST`。**不加**预告专用 FK。

现网唯一键 `(tenant_id, material_id, demand_id, supply_id)` **不够用**：`demand_id` / `supply_id` 是各表自增主键，预告行与 SO/FO 行会撞号。例如同一预告行同时存在 `FORECAST→FO(supply=8)` 与 `FORECAST→SO(supply=8)`，或接管后 `FORECAST→FO` 与 `SO→FO` 的 `demand_id` 数值相同，都会撞 `uk_order_peggings`。本波 **必须** 重建：

```sql
ALTER TABLE lychee_erp.order_peggings DROP CONSTRAINT uk_order_peggings;
ALTER TABLE lychee_erp.order_peggings
    ADD CONSTRAINT uk_order_peggings
    UNIQUE (tenant_id, material_id, demand_type, demand_id, supply_type, supply_id);
```

同一预告行被多张 SO 消耗：多行 pegging，`supply_id` 不同，新唯一键仍允许。

| 场景 | demand | supply |
|------|--------|--------|
| 预告转 FO | `SALES_FORECAST` + item id | `FACTORY_ORDER` + fo item id |
| 预告被 SO 消耗 | `SALES_FORECAST` + item id | `SALES_ORDER` + so item id |
| 正式单转 FO（现网不变） | `SALES_ORDER` + so item id | `FACTORY_ORDER` + fo item id |

接管后：同一 FO 行可以同时存在「SO→FO」（已接管量）与「FORECAST→FO」（尚未被 SO 认领的余量），或只剩 SO→FO。不要用 FO 行上的来源 FK，继续只靠 pegging。

### 5.2 消耗匹配键（应用层，无 SO 新列）

```text
company_id           = SO.company_id = 预告.company_id
customer_id          = SO.customer_id = 预告.customer_id
material_id          = SO item.material_id
bucket_date          = normalize(SO item 交期, 该张预告.bucket_type)

吃未转开量：头 ACTIVE 且行 ACTIVE
接管：该行 allocated > 0，行可以是 ACTIVE 或 CLOSED（单行关闭后仍认领 FO）
      头 ACTIVE，或头 CLOSED 且在当前 ACTIVE 的 supersedes_id 链上
```

多行命中同一键：一张单内已被 `uk_..._material_bucket` 挡住。跨公司、跨客户不会匹配。  
SO 量大于可消耗/可接管合计：重叠部分扣预告，超出不碰预告，按现网 SO→FO。  
**禁止** SO 行增加 `forecast_item_id`（会把 N:1 / 1:N 写死）。

### 5.3 `FactoryOrderSourceType`

```text
SALES_ORDER | MANUAL | FORECAST
```

- 仅从预告转出的 FO：`FORECAST`
- 接管后表头 `source_type` **不改**（诞生方式）；行级需求以 pegging 为准
- 混单（一张 FO 先挂预告再接管成 SO）允许；打印/进度按 pegging 取上游，不要只信表头 `source_type`

`factory_orders.so_count` 本波 **不改名**。预告转入时仍可把该计数当「来源行数」用，或暂只统计 SO pegging；语义澄清放到 FO 专题，不堵预告建表。

### 5.4 `DocumentTypeEnum`

新增 `SALES_FORECAST`。种子对标 `SALES_ORDER`：

```text
rule_code = SALES_FORECAST
prefix    = SFO
date_format = yyyyMMdd
seq_length  = 4
reset_type  = DAILY
```

行号分配同样走 `SALES_FORECAST`。

### 5.5 交货 / 发票

`DeliverySourceDocType`、AR 来源 **不加** 预告。预告生产入库后，靠库存 + 正式 SO 开 DN。

---

## 6. 状态机

### 6.1 表头 `forecast_status`

```text
DRAFT ──确认──► ACTIVE ──关闭──► CLOSED
  │               │
  └──取消──► CANCELLED     └──取消──► 不允许（已进计划须先退 FO / 回滚消耗后再关）
```

| 状态 | 可改头/行量 | 可转 FO | SO 吃未转开量 | SO 接管已转 FO | 可删 |
|------|-------------|---------|----------------|-----------------|------|
| `DRAFT` | 是 | 否 | 否 | 否 | 是（无下游） |
| `ACTIVE` | 否（备注除外） | 是 | 是 | 是 | 否 |
| `CLOSED` | 否 | 否 | 否（开量作废） | 是（换版链上 `allocated>0`） | 否 |
| `CANCELLED` | 否 | 否 | 否 | 否 | 否 |

`CLOSED`：滚动换版或手工关单。**不**要求 `open_to_allocate = 0`，**不**要求 `allocated = 0`。未转开量作废；已转未接管的 FO 留在账上供后续 SO 接管。  
已 `allocated > 0` 或 `consumed > 0` 不能直接 `CANCELLED`。

没有 `DELIVERED`。进度看下游 FO / SO，不在预告头上滚交货态。

### 6.2 明细 `line_status`

与表头同四态。规则：

- 头 `DRAFT` → 所有行 `DRAFT`；不允许行单独 ACTIVE
- 头确认 → 所有行 `ACTIVE`
- 允许单行 `ACTIVE → CLOSED`（该行未转开量作废，不再转 FO、不再吃未转部分；`allocated > 0` 仍可被 SO 接管），头仍 `ACTIVE`
- 头 `CLOSED` / `CANCELLED` → 仍为 `ACTIVE` 的行跟随
- 行已 `allocated > 0` 或 `consumed > 0` 时不可单行取消

头状态不由行聚合推导（避免与「部分行已关」冲突）。列表筛选以头状态为主。

---

## 7. 模块归属

| 表 / 能力 | 模块 |
|-----------|------|
| `sales_forecasts` / items CRUD、确认、关闭、取消 | `lychee-erp-sd` |
| 转 FO、allocated 回写、`FORECAST→FO` pegging | `lychee-erp-pp` 调 SD Remote（对标 `updateAllocatedQuantities`） |
| SO 确认时消耗 + 接管 | SD `consume`（预告账 + `FORECAST→SO`）→ PP `takeoverFromForecast`（只改 FO pegging）→ SD 写 SO allocated |
| MRP | **不**直接读预告表；只读 FO |
| 前端 | `lychee-frontend/src/pages/sd/sales-forecasts`（实施时） |
| 菜单 | `/sd/sales-forecasts`，权限 `:read/:create/:update/:delete`（确认/关取消走 update，与 `04` §7 一致） |

### 7.1 Remote / 同模块签名（建表波可先出接口，转单波实现）

`consume` 给 **SD 同模块**（`SalesOrderServiceImpl` → `SalesForecastService`），不要做成 Remote 再绕一圈。`ForecastConsumeRequest` / `ForecastConsumptionResult` 放在 `lychee-erp-sd` 即可。PP 只看到预告 Remote 的读 + allocated 增量；`ForecastTakeoverRequest` 放 `lychee-erp-common`。

```java
public interface RemoteSalesForecastService {
    List<RemoteSalesForecastItemDTO> getForecastItems(Long tenantId, Set<Long> itemIds);

    /** 转 FO / 删 FO 行回滚：map 值为增量（可负）。落库后违反 CHECK → ValidationException */
    void updateAllocatedQuantities(Long tenantId, Map<Long, BigDecimal> forecastItemIdToDelta);
}

public record RemoteSalesForecastItemDTO(
    Long id,
    Long salesForecastId,
    String forecastNo,
    Long companyId,
    Long customerId,
    Long materialId,
    Long unitId,
    LocalDate bucketDate,
    LocalDate requiredDate,
    BigDecimal forecastQuantity,
    BigDecimal allocatedQuantity,
    BigDecimal consumedQuantity,
    String headerStatus,
    String lineStatus
) {}

/** SD 同模块：锁行、改账、写 FORECAST→SO。delta 语义在实现里：正=确认，负=反确认回滚 */
public record ForecastConsumeRequest(
    Long salesOrderId,
    Long salesOrderItemId,
    Long companyId,
    Long customerId,
    Long materialId,
    Long unitId,
    LocalDate deliveryDate,   // 已按「行空则头」解析；null = 该行跳过
    BigDecimal quantity
) {}

public record ForecastConsumptionResult(
    Long salesOrderItemId,
    Long forecastItemId,
    Long salesForecastId,
    BigDecimal consumedUnallocated,  // u，未转 FO
    BigDecimal takenOver             // t，须接管的已转 FO；0 则 PP 不用动该行
) {}

/**
 * PP。只改 pegging，不回写 SO.allocated。
 * 按 forecastItemId 找 FORECAST→FO，due_date 升序、pegging id 升序扣 t。
 */
public interface RemoteFactoryOrderService {
    void takeoverFromForecast(Long tenantId, List<ForecastTakeoverRequest> requests);

    void revertTakeoverFromForecast(Long tenantId, List<ForecastTakeoverRequest> requests);
}

public record ForecastTakeoverRequest(
    Long salesOrderItemId,
    Long forecastItemId,
    Long materialId,
    BigDecimal quantity
) {}
```

`consume` 返回的 `takenOver` 合计，由 SO 确认方写入 `sales_order_items.allocated_quantity`。  
FI 不依赖本表。

---

## 8. 旧草稿废弃

现网 / 文档中的单表实现 **全部作废**，实施 changeset 必须 `DROP TABLE ... CASCADE` 后按 §3–§4 新建，**禁止** `ALTER` 打补丁。

| 废稿 | 问题 |
|------|------|
| `schema_tables/SD/sales_forecasts.sql` | 无表头；唯一键缺客户；`status` 与代码不一致 |
| `changelog/v1/2026/0620-002-sales_forecasts.sql` | 同上 |
| `SalesForecast` Entity | 行级 `version`、`status_option_id`、无 `consumed_quantity` |
| CRUD API | 无确认、无数量账、无转单 |

旧表若有数据视为测试垃圾，不迁移。

---

## 9. 落库顺序（实施时）

```text
1. DROP sales_forecasts CASCADE（会一并干掉旧 FK）
2. CREATE sales_forecasts + 部分唯一索引（含 company_id）+ FK
3. CREATE sales_forecast_items + CHECK + FK
4. 重建 uk_order_peggings = (tenant, material, demand_type, demand_id, supply_type, supply_id)
5. 种子 DocumentTypeEnum.SALES_FORECAST / 单号规则 SFO
6. 枚举：PeggingOrderType、FactoryOrderSourceType、SalesForecastStatus、SalesForecastBucketType
7. 更新 order_peggings 列注释（含 SALES_FORECAST）
8. 覆盖 schema_tables/SD/sales_forecasts.sql，新增 sales_forecast_items.sql；改 BASIS/order_peggings.sql 唯一键
9. SD_schema_design.md 增加 3.1.2 预告订单
```

不要在本波改 MRP 引擎种子、不要改 `DeliverySourceDocType`。

---

## 10. 文档与 schema_tables 对齐（实施时）

- `database/SD_schema_design.md`：新增预告表头/明细；标明不可交货
- `schema_tables/SD/sales_forecasts.sql`（覆盖）
- `schema_tables/SD/sales_forecast_items.sql`（新建）
- `schema_tables/BASIS/order_peggings.sql`：注释 + **唯一键含 type**
- Liquibase：`lychee-erp/src/main/resources/db/changelog/v1/2026/`  
  建议文件名：`YYYYMMDD-00n-rebuild-sales-forecasts.sql`（含 DROP + CREATE + 单号种子 + pegging 唯一键）

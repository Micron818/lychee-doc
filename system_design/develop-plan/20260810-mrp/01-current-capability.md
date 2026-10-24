# MRP 现有功能盘点（As-Is）

> 依据：`lychee-erp-pp` / `lychee-erp-scm` / `lychee-frontend` 当前代码。  
> 不引用历史草稿文档。
>
> **原物料转单改造（To-Be）** 以 [`chartExp/Purchase`](../backend/chartExp/Purchase/README.md) 为准（开发入口 `04-实施清单.md`）。**本节正文仍是改造前行为**，避免和目标流程混写。

---

## 1. 定位与主流程

当前 MRP 是**全量再生式（Regenerative）**运算：

```text
前端手动创建 MrpRun
  → 落库 status=RUNNING
  → AFTER_COMMIT 发布 MrpRunCreatedEvent
  → @Async 监听器调用 MrpCalculationEngine
  → 清理上轮未固化建议 → 净算 → 写入 MrpResult + OrderPegging
  → status=COMPLETED | FAILED
  → 计划员勾选结果转 PLO / PR（人工确认，不自动产单）
```

核心原则（已实现）：

- 运算产出的是**建议**（`MrpResult`），不是执行单
- 转单需人工调用 API：`convert-to-planned-orders` / `convert-to-purchase-requisitions`
- 溯源走统一 `order_peggings`，不在 `MrpResult` 上存 source/converted 外键

---

## 2. 数据模型

### 2.1 `mrp_runs`

| 字段 | 说明 |
|------|------|
| `run_code` | 单据号（`DocumentTypeEnum.MRP_RUN`） |
| `run_date` | 运算基准日（计划期间从这一天起算；BOM 是否有效看各建议的计划开工日） |
| `description` | 可选说明 |
| `factory_id` | 可选；空=全租户工厂 |
| `planning_horizon_days` | 可选计划期间（天）；空=不截断初始需求 |
| `trigger_source` | `MANUAL` / `SCHEDULED` / `NET_CHANGE` / `API` |
| `triggered_by` | 触发人用户 id |
| `run_mode` | `OPERATIVE` / `SIMULATION`（SIMULATION 暂拒创建） |
| `run_status` | `RUNNING` / `COMPLETED` / `FAILED` / `CANCELLED` |
| `error_message` | 失败信息（截断 500） |
| `execution_time_ms` | 完成耗时 |

**并发：** 同范围仅允许一个 `RUNNING`（全厂与任意单厂互斥；单厂之间按厂互斥）。

### 2.2 `mrp_results`

| 字段 | 说明 |
|------|------|
| `mrp_run_id` | 所属 Run |
| `material_id` / `factory_id` | 建议对象（工厂在结果层，不在 Run 层） |
| `required_date` / `required_quantity` | 需求日与建议量 |
| `planned_start_date` / `planned_end_date` | 提前期倒推后的计划起止 |
| `suggested_action_type` | `PRODUCTION` / `PURCHASE`；由物料类型 `isManufactured` 决定，不看 BOM |
| `has_bom` | 运算快照：自制件在计划开工日是否有有效的 APPROVED BOM |
| `is_converted` | 是否已转单 |

### 2.3 `mrp_parameters`

按 `(tenant, factory_id, material_id)` 唯一，支持分层解析：

1. 工厂 + 物料  
2. 仅物料  
3. 仅工厂  
4. 全局行（两者皆空）  
5. 系统硬编码默认（LFL / lead=0 / safety=0 / rounding=1）

字段：`lot_sizing_procedure`（LFL/FOQ/POQ）、`min/max_lot_size`、`rounding_value`、`fixed_lot_size`、`period_days`、`lead_time_days`、`safety_stock_quantity`。

### 2.4 关联枚举（代码中实际使用情况）

| 枚举 | 值 | 实际使用 |
|------|-----|----------|
| `MrpRunStatus` | RUNNING/COMPLETED/FAILED/CANCELLED | CANCELLED 无写入路径 |
| `MrpActionType` | PRODUCTION/PURCHASE | `isManufactured`→PRODUCTION，否则 PURCHASE；BOM 只负责展开 |
| `MrpSourceType` | FACTORY_ORDER/FORECAST/SAFETY_STOCK/MANUAL | 引擎种子需求仅 FO；其余未参与计算 |
| `LotSizingProcedure` | LFL/FOQ/POQ | 已实现策略类 |
| `PlannedOrderStatus` | PROPOSED/FIRMED/CONVERTED | 清理与保护逻辑依赖此状态 |

---

## 3. API 与权限

### 3.1 `/api/v1/pp/mrp-runs`

| 方法 | 路径 | 权限 | 行为 |
|------|------|------|------|
| POST | `/page` | `:read` | Run 分页 |
| POST | `/` | `:create` | 创建 Run 并异步计算 |
| DELETE | `/bulk-delete` | `:delete` | 批量删除（已转单结果存在则拒绝） |
| POST | `/{id}/results/page` | `:read` | 结果分页 |
| POST | `/{id}/results/convert-to-planned-orders` | `:update` | 转计划订单 |
| POST | `/{id}/results/convert-to-purchase-requisitions` | `:update` | 转采购申请 |

创建请求体：`runDate`（必填）、`description`、`factoryId`（可选）、`planningHorizonDays`（可选）、`triggerSource` / `runMode`（可选，默认 MANUAL / OPERATIVE）。

### 3.2 `/api/v1/pp/mrp-parameters`

标准 CRUD：`/page`、`GET /{id}`、`POST`、`PUT /{id}`、`DELETE /bulk-delete`。

### 3.3 溯源

`GET /api/v1/common/order-peggings/{upstream-tree|downstream-tree|full-chain-tree}`。

---

## 4. 计算引擎行为

入口：`MrpCalculationEngine.executeCalculationInTransaction` → `calculateMrp`。

### 4.1 运行前清理（再生式）

每次运算开始会清理上一轮**未固化**产物；若 Run 带 `factoryId`，清理范围收窄到该工厂：

| 清理对象 | 条件 |
|----------|------|
| `MrpResult` | `is_converted=false`（可按厂） |
| `MrpResult` | 已转单但关联 PLO 仍为 `PROPOSED`（可按厂） |
| MRP 生成的 PR | DRAFT 类旧申请（可按厂） |
| `PlannedOrder` | `mrpRunId IS NOT NULL` 且 `PROPOSED`（可按厂） |

无建议行的 `COMPLETED` / `FAILED` 运算保留，用来标识该范围的最新运算。

**保留：** FIRMED/CONVERTED 的 PLO、采购订单（`DRAFT` / `APPROVED` / `PARTIAL`）、已审批/部分执行的 PR，以及对应已固化结果。采购订单不在本次清理范围内。

### 4.2 需求来源（已接入）

1. **厂订单 FO**  
   - 状态：`CONFIRMED` / `IN_PROGRESS`  
   - 开量：`quantity - allocatedQuantity`  
   - Pegging demand：`FACTORY_ORDER` + FO item id  
   - 日期：item `dueDate`

2. **在制工单组件（MO component open qty）**  
   - MO：`CREATED` / `RELEASED` / `IN_PROGRESS`（转工单时已增加厂订单已分配量，未下达的工单也要继续供料）  
   - 开量：`requiredQuantity - issuedQuantity`  
   - Pegging demand：`PRODUCTION_ORDER` + 工单头 id

3. **已确定计划工单的子件**  
   - 仅 `FIRMED` 且 `MAKE`；`CONVERTED` 已变成工单，不再展开  
   - 按计划开工日的有效 BOM 展开启用子件，需求日为开工日  
   - Pegging demand：`PLANNED_ORDER` + 计划工单 id

**未接入计算：** 销售订单直接需求、预测、独立安全库存需求行、手工需求。  
安全库存以参数 `safety_stock_quantity` 作为净算下限，不是独立需求行。

### 4.3 供给来源（已接入）

| 供给 | 取数要点 |
|------|----------|
| 现有库存 | `RemoteStockOnHandService.getTotalAvailableQuantity` |
| 已确认计划订单 | `PlannedOrderStatus.FIRMED` |
| 采购申请 | `APPROVED` / `PARTIAL`，开量 = 申请 − 已订。`DRAFT` 申请由 §4.1 清掉，不进入供给 |
| 采购订单 | `DRAFT` / `APPROVED` / `PARTIAL`，开量 = 订购 − 已收。`COMPLETED` / `CLOSED` 不进入供给。草稿单转出后会留下来，计入供给后，下次再生运算只建议差额 |
| 生产工单成品 | `CREATED` / `RELEASED` / `IN_PROGRESS`；已由 FO→MRP→PLO→MO 挂钩的部分不重复计入，批量结余仍作为供给 |
| 委外单 | ISSUED/PARTIAL；同样只排除厂订单已挂钩的数量，结余仍作为供给 |

### 4.4 净算 / 批量 / 展开

按 `(factoryId, materialId)`，LLC 自低到高：

1. 运行前 `lowLevelCodeService.recalculateForCurrentTenant()`（APPROVED BOM）
2. 按事件日净算：先加上当日及之前的预计入库，再扣当日需求。LFL/FOQ 只覆盖当天缺口；POQ 在缺料日汇总 `[缺料日, 缺料日 + periodDays)` 内按时点算出的净需求
3. 低于安全库存才产生净需求。建议日是这次缺料日，也是该张建议实际 peg 到的最早需求日
4. `materialType.isManufactured=true` → `PRODUCTION`，否则 `PURCHASE`（采购件即使误挂 BOM 也不展开）
5. 提前期按天向上取整：`plannedEndDate = 建议日`，`plannedStartDate = 建议日 − ceil(leadTimeDays)`
6. Lot-Sizing 策略：`LotForLot` / `FixedQuantity` / `PeriodicQuantity`（含 rounding/min/max）。最大批量可拆成多张建议；批量结果不能缩小缺口时运算失败
7. 写 `MrpResult`（`hasBom` 表示计划开工日有批准的 BOM）+ pegging。仅 PRODUCTION 且该开工日有有效 BOM 才展开**启用**子件（含 scrap，数量保留 6 位小数）。低阶码循环随新子件升高，不设固定层数上限

### 4.5 状态机

```text
RUNNING → COMPLETED
       └→ FAILED
CANCELLED：枚举存在，无业务写入
```

无需求时引擎直接返回，监听器仍标为 `COMPLETED`。

---

## 5. 转单

### 5.1 → Planned Order

- 仅 `PRODUCTION` 且未转单
- 若 FO pegging 需求侧已有 FIRMED/CONVERTED PLO，则跳过（`hasProtectedOrder`）
- 新建 PLO：`orderType=MAKE`，`orderStatus=PROPOSED`，带 `mrpRunId`
- Pegging：`MRP_RESULT → PLANNED_ORDER`；`isConverted=true`
- PLO→MO：无有效 BOM 时允许转工单（`bomId` 空、无组件），用于仅制程件

### 5.2 → Purchase Requisition

> To-Be：删除本路径，改为采购订单页 MRP 待转 Tab 转 PO。见 Purchase/02、04。

- 仅 `PURCHASE` 且未转单
- 已有 PR pegging 则跳过
- 经 `RemotePurchaseRequisitionService` 按工厂分组建 DRAFT PR（`sourceType=MRP`）
- Pegging：`MRP_RESULT → PURCHASE_REQUISITION(item)`；`isConverted=true`

### 5.3 回退

`RemoteMrpResultService.revertMrpResults` 将 `isConverted` 置回 `false`（由 PR 删除/取消等路径调用），MRP Controller 无公开 revert 接口。

---

## 6. 前端能力

| 页面 | 能力 |
|------|------|
| MRP Runs | 列表；存在 RUNNING 时每 3s 轮询；创建（runDate/description）；批量删除；详情抽屉 |
| Results | 按 PRODUCTION/PURCHASE 过滤；勾选转 PLO/PR；Pegging 抽屉 |
| MRP Parameters | 完整 CRUD |
| MRP Schedules | 完整 CRUD；立即执行（按排程参数创建 SCHEDULED Run） |

**没有：** 取消运算、模拟模式逻辑、例外清单、供需投影视图、Net Change。

---

## 7. 关键代码路径

| 区域 | 路径 |
|------|------|
| Run 服务 | `.../pp/service/impl/MrpServiceImpl.java` |
| 计算引擎 | `.../pp/service/impl/MrpCalculationEngine.java` |
| 预计入库 | `.../pp/service/impl/MrpScheduledReceiptServiceImpl.java` |
| 转单 | `.../pp/service/impl/MrpConversionServiceImpl.java` |
| 参数 | `.../pp/service/impl/MrpParameterServiceImpl.java` |
| 事件 | `.../pp/event/listener/MrpRunEventListener.java` |
| API | `.../pp/controller/MrpController.java` |
| 批量策略 | `.../pp/strategy/lotsizing/*` |
| FE Runs | `lychee-frontend/src/pages/pp/mrp-runs/**` |
| FE Params | `lychee-frontend/src/pages/pp/mrp-parameters/**` |

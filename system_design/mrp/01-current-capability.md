# MRP 现有功能盘点（As-Is）

> 依据：`lychee-erp-pp` / `lychee-erp-scm` / `lychee-frontend` 当前代码。  
> 不引用历史草稿文档。

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
| `run_date` | 运算基准日（兼作 BOM 有效日） |
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
| `suggested_action_type` | `PRODUCTION` / `PURCHASE` |
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
| `MrpActionType` | PRODUCTION/PURCHASE | 有 BOM→PRODUCTION，否则 PURCHASE |
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
| 空 Run | 非 RUNNING 且无结果 |

**保留：** FIRMED/CONVERTED 的 PLO、已审批/部分执行的 PR、以及对应已固化结果。

### 4.2 需求来源（已接入）

1. **厂订单 FO**  
   - 状态：`CONFIRMED` / `IN_PROGRESS`  
   - 开量：`quantity - allocatedQuantity`  
   - Pegging demand：`FACTORY_ORDER` + FO item id  
   - 日期：item `dueDate`

2. **在制工单组件（MO component open qty）**  
   - MO：`RELEASED` / `IN_PROGRESS`  
   - 开量：`requiredQuantity - issuedQuantity`  
   - Pegging demand：`PRODUCTION_ORDER` + component id

**未接入计算：** 销售订单直接需求、预测、独立安全库存需求行、手工需求。  
安全库存以参数 `safety_stock_quantity` 作为净算下限，不是独立需求行。

### 4.3 供给来源（已接入）

| 供给 | 取数要点 |
|------|----------|
| 现有库存 | `RemoteStockOnHandService.getTotalAvailableQuantity` |
| 已确认计划订单 | `PlannedOrderStatus.FIRMED` |
| 采购申请 | APPROVED/PARTIAL，开量 = 申请 − 已订 |
| 采购订单 | APPROVED/PARTIAL，开量 = 订购 − 已收 |
| 生产工单成品 | RELEASED/IN_PROGRESS；若已由 FO→MRP→PLO→MO 链路 pegging 则跳过防双重计入 |
| 委外单 | ISSUED/PARTIAL；同样有 FO-peg 跳过逻辑 |

### 4.4 净算 / 批量 / 展开

按 `(factoryId, materialId)`，LLC 自低到高：

1. 运行前 `lowLevelCodeService.recalculateForCurrentTenant()`（APPROVED BOM）
2. 按批量规则分桶：LFL/FOQ 按日；POQ 按 `period_days`
3. 套用到期预计入库 → 扣毛需求 → 低于安全库存则产生净需求
4. 有有效 BOM（相对 `runDate`）→ `PRODUCTION`，否则 `PURCHASE`
5. 提前期：`plannedEndDate = 最早需求日`，`plannedStartDate = 需求日 − leadTimeDays`
6. Lot-Sizing 策略：`LotForLot` / `FixedQuantity` / `PeriodicQuantity`（含 rounding/min/max）
7. 写 `MrpResult` + pegging；若 PRODUCTION 则 BOM 展开组件（含 scrap）作为下层需求

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

### 5.2 → Purchase Requisition

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

**没有：** 取消运算、模拟模式、例外清单、供需投影视图、排程配置。

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

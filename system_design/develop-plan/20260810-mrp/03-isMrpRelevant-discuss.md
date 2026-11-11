在规范的 ERP 系统中，**非常需要此设定，它是仓库/库位主数据的标准核心属性**。

主流 ERP 都有完全对应的设计：
- **SAP S/4HANA**：库存地点（Storage Location）的 *MRP Indicator*（`MARD-DISKZ` / 后台配置 `OMIR`，控制该库位库存是否纳入工厂级 MRP 净需求计算）。
- **Oracle EBS / Cloud**：子库存（Subinventory）的 **Nettable（可净算）** 开关。
- **鼎捷 (T100 / Workflow) / 金蝶云星空 / 用友 U9**：仓库主档上的 **「纳入可用量计算 / 参与 MRP 运算」** 勾选框。

---

### 一、当前代码现状

目前 Lychee 前后端与数据库都已完整定义了该字段（前端中文名即为 **「MRP计算扣减库存」**），但计算引擎尚未接入过滤：

1. **MRP 引擎调用处**：
```188:191:lychee-backend/lychee-erp-pp/src/main/java/com/lychee/erp/pp/service/impl/MrpCalculationEngine.java
        MrpParameter mrpParam = mrpParameterService.getEffectiveParameter(tenantId, factoryId, materialId);
        TreeMap<LocalDate, BigDecimal> receipts = receiptsByKey.getOrDefault(key, new TreeMap<>());
        BigDecimal onHand = nullToZero(remoteStockOnHandService.getTotalAvailableQuantity(factoryId, materialId));
        List<MrpTimePhasedPlanner.PlannedSupply> supplies = MrpTimePhasedPlanner.plan(
```
2. **WM 库存汇总实现处**：直接按 `factoryId + materialId` 汇总了该工厂下**所有仓库**的可用量，未关联 `Warehouse.isMrpRelevant`：
```46:51:lychee-backend/lychee-erp-wm/src/main/java/com/lychee/erp/wm/repository/StockOnHandRepository.java
    @Query("""
            select coalesce(sum(s.physicalQuantity - s.reservedQuantity - s.blockedQuantity - s.qaQuantity), 0) 
            from StockOnHand s 
            where s.factoryId = :factoryId and s.materialId = :materialId
            """)
    BigDecimal sumAvailableQuantity(@Param("factoryId") Long factoryId, @Param("materialId") Long materialId);
```

---

### 二、标准 ERP 中 `isMrpRelevant = false` 的典型业务场景

即使单笔库存的库存状态是 `UNRESTRICTED`（非冻结 `blocked`、非待检 `qa`），在以下场景中也**不能**当作全厂通用可用库存去抵扣新订单的净需求（否则会导致少买料、车间断料或重复计算）：

#### 1. 废品仓 / 呆滞待报废仓（对应 `WarehouseType.SCRAP`）
不良品、边角料、呆滞料移入废品仓等待集中销毁或变卖时，在废品仓内的账面可能是非冻结的实物数量，但**绝不能参与正常生产需求抵扣**，否则 MRP 会误以为还有合格原料而少下采购建议。

#### 2. 委外加工商仓（对应 `WarehouseType.OUTSOURCE`）—— 最易产生库存虚增的场景
结合本系统 `OutsourceInventoryServiceImpl` 的实现：发料给委外商时，物料调拨进入绑定特定供应商的 `OUTSOURCE` 仓（账面仍属于当前 `factoryId` 的 `stock_on_hand`，直到委外完工收货才倒扣核销）。
- 这批料物理上已在外部供应商处，且专用于特定委外订单；
- 若 `OUTSOURCE` 仓参与全厂 MRP 现存量扣减（而委外单未耗用组件又未同步作为需求对冲，或不同委外商之间库存不可混用），MRP 会把**已经发给甲委外厂的原料，再次当作厂内自由库存去抵扣本厂工单或其他订单**，导致采购量偏少。

#### 3. 车间线边仓 / 在制品仓（对应 `WarehouseType.WIP`）—— 防止「双重抵扣」
在倒冲（Backflush）模式下，仓库把料发到车间线边仓（`WIP`）：
- 如果业务上「调拨/发料至线边仓」的同时已经扣减了工单组件的未发需求（`issuedQuantity` 增加，工单剩余需求减少），此时实物仍躺在 `WIP` 仓等待完工倒扣；
- 如果 `WIP` 仓同时设为 `isMrpRelevant = true`，就会发生 **「工单需求已被核销 + 线边仓余料又被算作可用库存」的双重计算（Double Counting）**。将此类 `WIP` 仓设为 `false` 即可避免重复算作供给。

#### 4. 专料专用仓（研发仓 / 样品室 / 售后备件仓 / 客退仓）
- **研发试制仓 / 打样仓（Sample Room）**：工程部或开发部购买的面辅料/元器件，虽然属于常规 `RAW_MATERIAL` 原料仓类型，但专供打样，大货生产不能挪用。
- **客户退货待处理仓 / 售后维修备件仓**：退回的成品虽然是 `FINISHED_GOODS` 类型，但未翻新前不能直接抵扣新销售订单/工厂订单（Factory Order）需求。
- 这也是**为什么不能只靠 `WarehouseType` 硬编码判断，而必须保留独立 `isMrpRelevant` 开关**的原因：同为 `RAW_MATERIAL` 或 `FINISHED_GOODS` 类型，企业也会区分「大货仓（`true`）」与「样品仓/客退仓（`false`）」。

#### 5. 跨仓/跨厂在途仓（对应 `WarehouseType.TRANSIT`）
如果调拨在途单据本身已被计入预计入库（Scheduled Receipts），或者在途物资归属尚未到达接收方可用状态，在途仓的 `stock_on_hand` 若再计入现存量会导致供给重复计算或提前可用。

---

### 三、如果后续要在系统中启用该逻辑的注意事项

`getTotalAvailableQuantity` 目前在全后端**仅有 `MrpCalculationEngine` 第 190 行一处调用**，因此在 `StockOnHandRepository.sumAvailableQuantity` 中关联 `Warehouse` 增加 `w.isMrpRelevant = true` 条件即可生效，改动边界非常清晰。

但启用前有**两个细节必须同步处理**：

1. **前后端新增仓库默认值不一致（重点隐患）**：
   - 后端 `Warehouse.java` 与数据库 schema 默认值均为 `true`，但前端新增仓库时硬编码了 `false`：
```27:32:lychee-frontend/src/pages/wm/warehouses/index.tsx
  const handleAdd = () => {
    setCurrentRow({
      factoryId,
      activeStatus: 'ACTIVE',
      isMrpRelevant: false,
    });
```
   - 这意味着目前通过前端界面新建的原料仓、成品仓，如果用户没手动打开开关，数据库里存的很可能是 `false`。**一旦后端直接加上 `isMrpRelevant = true` 过滤，这些仓库的库存会立刻从 MRP 中消失**。
2. **建议的最佳实践**：
   - **前端联动默认值**：新建仓库选择 `warehouseType` 时自动给出合理默认值——`RAW_MATERIAL`、`FINISHED_GOODS` 默认设为 `true`；`SCRAP`、`OUTSOURCE`、`TRANSIT` 默认设为 `false`（`WIP` 视工单发料逻辑而定），仍允许人工手动调整。
   - **数据迁移清洗**：启用 SQL 过滤条件的同时，配一条 Liquibase 脚本排查/刷新存量正常仓（如 `RAW_MATERIAL` / `FINISHED_GOODS`）的 `is_mrp_relevant` 状态。

   ### 一、半成品仓应如何设置？

**半成品仓应当设置为 `isMrpRelevant = true`（参与 MRP 库存扣减）。**

在规范的 ERP 系统中，判断一个仓库是否应设为 `isMrpRelevant = true`，核心依据是 **「MRP 供需守恒定律」**：只要某物料在该仓库存放期间，**上游预计供给已经核销减少，而下游毛需求尚未核销减少**，该仓库的现存量就**必须**纳入 MRP 可用库存，否则会出现供需断档、导致重复生单。

结合当前系统代码（`ProductionReportServiceImpl` 与 `MrpScheduledReceiptServiceImpl`），我们可以完整推演 **100 件成品（FG）需要 100 件半成品（SFG）** 的全过程账务变化：

1. **阶段 1：工单下达，尚未报工**
   - **下游需求**（成品工单组件未发量）：`requiredQuantity(100) - issuedQuantity(0) = 100`
   - **上游供给**（半成品工单预计入库）：`plannedQuantity(100) - completedQuantity(0) = 100`
   - **半成品仓现存量**：`0`
   - **MRP 净需求**：`100 - 100 - 0 = 0`（供需平衡）

2. **阶段 2：半成品回报产量 40 件，入库「半成品仓」（下道工序尚未领用/倒扣）**
   在 `ProductionReportServiceImpl.postProductionReport` 过账时，系统同时做了两件事：
   - 生成入库单进入半成品仓 → 半成品仓 `StockOnHand` **+40**；
   - 更新半成品工单 `completedQuantity` **+40** → 下次跑 MRP 时，半成品工单的剩余预计入库量（`ScheduledReceipt`）自动降为 `100 - 40 = 60`：
```81:83:lychee-backend/lychee-erp-pp/src/main/java/com/lychee/erp/pp/service/impl/MrpScheduledReceiptServiceImpl.java
            BigDecimal completed = mo.getCompletedQuantity() != null ? mo.getCompletedQuantity() : BigDecimal.ZERO;
            BigDecimal openQty = mo.getPlannedQuantity().subtract(completed);
```
   - 与此同时，父阶成品工单组件的 `issuedQuantity` 仍为 `0`（因为要等下道工序领料或回报产量时才扣减），所以成品工单对半成品的未发需求**仍然是 `100`**。
   - **此时跑 MRP**：
     - 若半成品仓 `isMrpRelevant = true`：`需求(100) - 半成品工单未完工量(60) - 半成品仓现存量(40) = 0`（**完全平衡**）。
     - 若半成品仓 `isMrpRelevant = false`：`需求(100) - 半成品工单未完工量(60) - 现存量(0) = 40`（**MRP 看不到已入库的 40 件半成品，会误判缺料并多生出一张 40 件的半成品计划单**）。

3. **阶段 3：半成品从「半成品仓」调拨至「下道工序线边仓」（未扣减父阶工单需求）**
   - 半成品仓 `-40`，线边仓 `+40`，父阶成品工单未发需求仍为 `100`。
   - 因为半成品仓与线边仓均为 `isMrpRelevant = true`，合计可用现存量仍为 `40`，`100 - 60 - 40 = 0`（**依然平衡**）。

4. **阶段 4：下道工序（成品工单）回报产量并倒扣半成品**
   - 线边仓（或半成品仓）库存 `-40`（变为 `0`）；
   - 父阶成品工单组件 `issuedQuantity` `+40`，未发需求降为 `100 - 40 = 60`：
```282:287:lychee-backend/lychee-erp-pp/src/main/java/com/lychee/erp/pp/service/impl/ProductionReportServiceImpl.java
            for (ProductionReportComponent component : components) {
                ProductionOrderComponent orderComponent = orderComponentRepository.findById(component.getProductionOrderComponentId())
                        .orElseThrow(() -> new ValidationException("validation.common.not.found"));
                orderComponent.setIssuedQuantity(orderComponent.getIssuedQuantity().add(component.getIssueQuantity()));
                orderComponentRepository.save(orderComponent);
            }
```
   - **此时跑 MRP**：`需求(60) - 半成品工单未完工量(60) - 现存量(0) = 0`（**全链路闭环**）。

> **总结各类仓库在该模式下的标准配置：**
> - **`isMrpRelevant = true`**：原物料仓、半成品仓、车间线边仓（调拨不扣工单需求、报工倒扣模式）、大货成品仓。
> - **`isMrpRelevant = false`**：废品/不良品仓（`SCRAP`）、委外供应商仓（`OUTSOURCE`）、研发打样/样品仓、客退待处理仓、在途仓（`TRANSIT`）。

---

### 二、MRP 计算时应如何处理 `isMrpRelevant` 注记？

在规范的 ERP 架构及本系统的代码模型下，MRP 引擎围绕该注记需按以下规则处理：

#### 1. 期初可用现存量（On-Hand Inventory）—— 核心过滤点
在 `MrpTimePhasedPlanner.plan(...)` 中，期初库存 `onHand` 是时间分段净需求计算的起点（同时用于判断是否跌破安全库存 `safetyStock`）：
```66:67:lychee-backend/lychee-erp-pp/src/main/java/com/lychee/erp/pp/service/impl/MrpTimePhasedPlanner.java
        BigDecimal projected = onHand == null ? BigDecimal.ZERO : onHand;
        BigDecimal safety = safetyStock(param);
```
处理规则：
- **仅汇总 `Warehouse.isMrpRelevant = true` 的仓库可用量**：
  即在 `StockOnHandRepository.sumAvailableQuantity`（或专供 MRP 的批量查询方法）中关联 `Warehouse` 表，限定 `w.isMrpRelevant = true`（通常建议同时限定 `w.activeStatus = 'ACTIVE'`）：
  \[
  \text{MRP OnHand} = \sum_{w.\text{isMrpRelevant}=\text{true}} (\text{physicalQuantity} - \text{reservedQuantity} - \text{blockedQuantity} - \text{qaQuantity})
  \]
- **`isMrpRelevant = false` 的仓库完全透明**：其库存既**不能**用来抵扣毛需求，也**不能**用来充当安全库存（例如废品仓里有 100 件不良品，不能认为已满足 100 件安全库存）。
- **性能优化建议**：目前 `MrpCalculationEngine.processMaterial` 在循环内按单个物料逐次调用 `remoteStockOnHandService.getTotalAvailableQuantity(factoryId, materialId)`。接入 `Warehouse` 关联过滤时，也可考虑按 `(factoryId, materialIds)` 一次性批量分组查出 Map，减少多物料运算时的 SQL 往返。

#### 2. 预计入库量（Scheduled Receipts）与毛需求（Demands）—— 视单据颗粒度而定
在标准 ERP（如 SAP）中，有一条配套防抖动规则：**如果某张采购单（PO）或工单（MO）在单据上明确指定了收货入库到 `isMrpRelevant = false` 的仓库（例如专门为研发部采购并指定入「样品仓」的 PO），则该笔 PO 的未交量也不能计入 MRP 的预计入库（`ScheduledReceipts`）**——否则收货前被算作全厂可用供给，一收货入样品仓反而从 MRP 可用量中消失，会导致 MRP 结果前后跳变。

- **对照本系统现状**：
  目前系统内的 `PurchaseRequisition`、`PurchaseOrder`、`ProductionOrder`、`PlannedOrder`、`OutsourceOrder` 全部是**工厂级（仅带 `factoryId`，单据上不带目标 `warehouseId`，入库仓在收货/报工时才指定）**。
  因此，在当前架构下，**`ScheduledReceipts` 和 `Demands` 不需要做仓库级过滤，只需在 `onHand` 现存量汇总处过滤 `isMrpRelevant = true` 即可**。（若未来采购单/杂项单扩展出「指定入非 MRP 仓」的专案采购字段，届时再将该类在途单据同步排除出 `ScheduledReceipts`）。

#### 3. 补充留意：顶层「成品仓」与「半成品仓」的一个机制差异
虽然半成品仓设 `isMrpRelevant = true` 完全严丝合缝，但在检查本系统代码时，顶层**成品（连接 `FactoryOrder` 的物料）**有一个细节值得留意：
- 半成品的需求来自父阶工单组件（`requiredQuantity - issuedQuantity`），报工入半成品仓时**不会**减少父阶需求，所以半成品库存必须算入 `onHand` 去对冲；
- 而顶层成品的需求来自 `FactoryOrderItem`（`MrpCalculationEngine` 第 341 行：`quantity - allocatedQuantity`）。在 `PlannedOrder` 转 `ProductionOrder` 时（`PlannedOrderServiceImpl` 第 375 行），**已经提前把 `allocatedQuantity` 加上去了**（即 A 工厂订单的未分配需求已经变成 `0`）。
- 如果 A 订单对应的成品工单分批完工入库到「成品仓」（此时成品仓 `StockOnHand` 增加，但还没建销售出货单去扣减库存或占用 `reservedQuantity`），此时若进来一张新的 B 工厂订单跑 MRP，且成品仓为 `isMrpRelevant = true`，MRP 会把成品仓里这批尚未发货的现存量当作自由库存抵扣给 B 订单（MTS 按库生产逻辑）。如果贵司对顶层成品采用严格的**按单生产（MTO，A 单做的成品绝不能被 B 单挪用）**，则需要配合库存预留（`reservedQuantity`）或按单锁库机制来隔离。
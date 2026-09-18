# 03. 契约：无表变更，待转 DTO 与 Pegging

> 本专题 **不改表、不改枚举、不加 Liquibase**。  
> `mrp_results.convert_status` / `converted_quantity` 的生产规则已在 [`../20260825-purchase/03-schema设计.md`](../20260825-purchase/03-schema设计.md) 锁定，这里只写作业台用到的 API 形状。

---

## 1. 仍使用的现网结构

| 对象 | 用途 |
|------|------|
| `mrp_results` | 建议；生产整行 `OPEN` → `CONVERTED` |
| `planned_orders` | `PROPOSED` / `FIRMED` / `CONVERTED`；`order_type=MAKE` |
| `order_peggings` | `FACTORY_ORDER → MRP_RESULT → PLANNED_ORDER → PRODUCTION_ORDER` |
| `production_orders` | 转 MO 现网生成 |

不要为待转池建新表。待转是最新 Run 上 OPEN 生产结果的查询视图。

---

## 2. `PendingMrpProductionItemResponse`

PP 模块 DTO（不必放到 `lychee-erp-common` Remote，除非以后有跨模块调用）。字段对齐采购 `PendingMrpPurchaseItem` 的只读部分。  
**不要**供应商 / 单价 / MOQ / 可改单位。数量必须带物料基本单位展示，否则计划员无法判读。

| 字段 | 类型 | 说明 |
|------|------|------|
| `mrpResultId` | Long | 行键；转单 Body、Pegging `sourceId` 都用此 id。**没有** `id` |
| `mrpRunId` | Long | 来源 Run |
| `mrpRunCode` | String | 展示 |
| `factoryId` / `factoryCode` / `factoryName` | | |
| `materialId` / `materialCode` / `materialName` | | |
| `unitId` / `unitCode` / `unitName` | | 物料 `baseUnit`，只读展示 |
| `requiredDate` | LocalDate | |
| `plannedStartDate` / `plannedEndDate` | LocalDate | 写入 PLO start/end |
| `requiredQuantity` | BigDecimal | 整行转出量 |
| `convertedQuantity` | BigDecimal | 待转池应为 0 |
| `remainingQuantity` | BigDecimal | `MrpResultConvertStatus.remaining` |
| `convertStatus` | `MrpResultConvertStatus` | 应为 `OPEN` |
| `convertible` | boolean | `hasProtectedOrder` 为 false 时 true |
| `blockReason` | String，可空 | 仅 `PROTECTED_PLO`；可转时 null |

`blockReason` 用稳定码，前端 i18n，不要直接返回中文。

派生：

```text
convertible == false  ↔  blockReason == PROTECTED_PLO
convertible == true   ↔  blockReason == null
```

列表查询已保证最新 Run + PRODUCTION + OPEN，故不必再返回 `NOT_LATEST_RUN`。提交时仍要重校验最新 Run（防待转页开着时又跑了一次 MRP）。

搜索参数走 `MrpResult`：`factoryId`、`material.code_or_name`（或 `material.name`）、日期。禁止用 PLO 的 `productMaterial.*`，`DynamicSpecifications` 会解析失败。

分页 fetch 必须带点路径（`Material.baseUnit` 是 LAZY；只 fetch `material` 映射单位时会再打一轮）：

```text
DynamicSpecifications.fetch("material.baseUnit", "factory", "mrpRun")
```

---

## 3. 转单请求 / 响应

```text
POST /planned-orders/from-mrp-results
Body: [ mrpResultId, ... ]

200: List<PlannedOrderResponse>   // 契约仍用现网类型；本接口只保证 id / orderNo
```

不要做成采购那种 `{ items: [{ mrpResultId, convertQuantity, supplierId, ... }] }`。生产没有行级改写。

`saveAll` 后 `productMaterial` / `factory` 未 hydrate。**不要**为了物料名再查一遍带 fetch 的 PLO。前端成功文案只用 `orders.map(o => o.orderNo)`。映射主表已有字段即可，名称类字段允许为空。

错误（整批回滚）：

| 条件 | message key |
|------|-------------|
| 非 PRODUCTION | 新增 `validation.mrpResult.not.production` |
| 非最新 Run | 复用 `validation.mrpResult.not.latest.run` |
| 非 OPEN / remaining=0 | `validation.mrpResult.no.remaining` |
| `PROTECTED_PLO` | 新增 `validation.mrpResult.convert.protected.plo`（可带物料编码） |
| id 不存在 | `entity.mrp_result` |

firm / unfirm 非法状态（现网 PLO API，本波收紧）：

| 条件 | message key |
|------|-------------|
| `bulk-firm` 含非 PROPOSED | 新增 `validation.plannedOrder.firm.only.proposed` |
| `bulk-unfirm` 含非 FIRMED | 新增 `validation.plannedOrder.unfirm.only.firmed` |

提交加锁（`from-mrp-results`）：

```text
ids.stream().sorted() 之后再 findByIdForUpdate
同事务 Map<factoryId, latestRunId> 缓存 findLatestCoveringOperativeRunId
```

交叉勾选同一批 id 时，不加锁顺序会在 PostgreSQL 上死锁。

---

## 4. Pegging（不改）

转 PLO（现网）：

```text
demandType = MRP_RESULT      demandId = mrpResultId
supplyType = PLANNED_ORDER   supplyId = plo.id
peggedQuantity = requiredQuantity
materialId = result.materialId
```

转 MO、删 PROPOSED 回退：现网 `PlannedOrderServiceImpl`，不动。

保护判断语义与现网 `hasProtectedOrder(foItemId, materialId, {FIRMED, CONVERTED})` 相同。  
`hasProtectedOrder` **留给** `from-mrp-results` 加锁后的逐条校验，不要删。待转分页**禁止**循环调用它。

待转分页对当前页算 `convertible` / `blockReason`，保护相关 DB 交互**固定 2 次**（本页无 FO peg 则第 2 次跳过，避免空 `IN`）：

1. `findBySupplyTypeAndSupplyIdIn(MRP_RESULT, 本页 mrpResultIds)`
2. 抽出 `foItemIds` / `materialIds`；若 `foItemIds` 非空，再调一次 `findProtectedFoItemMaterialPairs`（新增，见下）
3. 内存做成 `Set`（建议 key = `foItemId + ':' + materialId`），按行 O(1) 判 `convertible`

`PlannedOrderRepository` 新增：

```text
List<Object[]> findProtectedFoItemMaterialPairs(foItemIds, materialIds, statuses)
-- DISTINCT peg1.demandId, p.productMaterialId
-- JOIN 与现网 hasProtectedOrder 同一条 pegging 链
-- peg1.demandId IN :foItemIds AND p.productMaterialId IN :materialIds
-- p.orderStatus IN {FIRMED, CONVERTED}
```

无 FO pegging 的组件层建议（上层 `demandType=MRP_RESULT` 或 MO 组件需求）：`convertible=true`，`blockReason=null`。与现网循环一致：只在 FO peg 上检查保护。

---

## 5. 与采购 DTO 的关系

| | 采购待转 | 生产待转 |
|--|----------|----------|
| 最新 Run | 相同定义 | 相同定义 |
| 动作类型 | PURCHASE | PRODUCTION |
| remaining | 可部分转 | 列出时即整行未转 |
| 行编辑 | 供应商/量/单价/单位 | 无；单位只读展示 |
| 落单据 | PO `source_type=MRP` | PLO `MAKE` `PROPOSED` |
| Remote 接口 | `RemoteMrpResultService.findPendingPurchaseItems` | **不必**新 Remote；PP Controller 直查 |

不要把生产待转塞进 `RemotePendingMrpPurchaseItemDTO`。

---

## 6. 权限与菜单

不改 `adm` 菜单树。页面仍是「计划工单(PLO)」。  
Tab 文案只走前端 i18n，不单独授权。看不见计划工单菜单的人本来就不能进工作台；结果页跳转按钮用 `accessAction="update"` 对齐转单。

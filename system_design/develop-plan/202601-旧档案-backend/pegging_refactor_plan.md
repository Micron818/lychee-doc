# ERP 訂單匯總與溯源 (Pegging) 架構重構計畫

## 1. 背景與目標

現有系統的訂單溯源採用「1對1」的主檔欄位關聯（例如在 `FactoryOrderItem` 中記錄 `salesOrderItemId`，在 `PlannedOrder` 中記錄 `sourceFactoryOrderItemId`）。這種設計在 MTO（接單生產）模式下運作良好，但無法支援 MTS（計畫生產）或 MRP 批量生產時的「匯總 (N:1)」與「拆分 (1:N)」場景。

為了解決此問題，我們將引入統一的 **「需求溯源網路（Pegging Network）」**，建立 `OrderPegging` 實體來管理所有單據之間的多對多關聯，並徹底移除各主檔/明細檔中舊有的 1:1 來源關聯欄位。

## 2. 重構範圍

### 2.1 新增共用元件

- **Enum `PeggingOrderType`**: 定義單據類型（SALES_ORDER, FACTORY_ORDER, MRP_RESULT, PLANNED_ORDER, PRODUCTION_ORDER, PURCHASE_REQUISITION）。
- **Entity `OrderPegging`**: 統一的溯源關聯表。
- **Repository `OrderPeggingRepository`**: 資料存取介面。

### 2.2 清理 FactoryOrder 相關 (lychee-erp-pp)

- **Entity `FactoryOrderItem`**: 移除 `salesOrderItemId`, `salesOrderNo`, `salesOrderDeliveryDate`。
- **DTOs**: 更新 `FactoryOrderItemDto`, `FactoryOrderCreateRequest` 等，移除對應欄位。
- **Service**: 調整 `FactoryOrderServiceImpl` 建立與查詢邏輯。

### 2.3 清理 MrpResult 相關 (lychee-erp-pp)

- **Entity `MrpResult`**: 移除 `sourceType`, `sourceId`, `convertedRefId`。
- **DTOs**: 更新相關 DTO。
- **Service**: 調整 MRP 計算與轉單邏輯。

### 2.4 清理 PlannedOrder 相關 (lychee-erp-pp)

- **Entity `PlannedOrder`**: 移除 `sourceFactoryOrderItemId`, `relatedProductionOrderId`, `relatedPurchaseRequisitionId` 以及相關的 `@ManyToOne` 關聯。
- **DTOs**: 更新 `PlannedOrderDto` 等。
- **Service**: 調整計畫訂單的建立與轉單邏輯。

### 2.5 清理 ProductionOrder 相關 (lychee-erp-pp)

- **Entity `ProductionOrder`**: 移除 `sourcePlannedOrderId`, `sourceFactoryOrderId`, `sourceFactoryOrderItemId` 以及相關的 `@ManyToOne` 關聯。
- **DTOs**: 更新 `ProductionOrderDto`, `ProductionOrderCreateRequest` 等。
- **Service**: 調整工單建立邏輯。

## 3. 執行步驟

1. 建立 `PeggingOrderType` Enum。
2. 建立 `OrderPegging` Entity 與 Repository。
3. 逐一修改 `FactoryOrderItem`, `MrpResult`, `PlannedOrder`, `ProductionOrder` 的 Entity 檔案。
4. 修正因 Entity 欄位刪除而導致編譯錯誤的 DTO、Mapper 與 Service 檔案。
5. （未來擴充）在各 Service 的建立/轉單邏輯中，寫入 `OrderPegging` 關聯資料。

---

name: pegging_implementation
overview: 完成各 Service 中的 OrderPegging 溯源邏輯實作，建立完整的 SO -> FO -> MRP -> PO -> PrO 溯源鏈。
todos:

- id: impl_mrp
content: 實作 MrpServiceImpl 的 OrderPegging 邏輯
status: completed
- id: impl_po
content: 實作 PlannedOrderServiceImpl 的 OrderPegging 邏輯
status: completed
- id: impl_pro
content: 實作 ProductionOrderServiceImpl 的 OrderPegging 邏輯
status: completed
isProject: false

---

# OrderPegging 實作計畫

為了建立完整的訂單溯源鏈 (SalesOrder -> FactoryOrder -> MrpResult -> PlannedOrder -> ProductionOrder)，我們將在各個 Service 中補齊 `OrderPegging` 的寫入與查詢邏輯。採用「鏈式溯源」設計，每個階段產生新的單據時，都會建立一筆指向上游單據的 Pegging 紀錄。

## 1. MrpServiceImpl 實作

- `**getMrpResultPage`**:
  - 透過 `OrderPeggingRepository` 查詢 `supplyType = MRP_RESULT` 且 `demandType = FACTORY_ORDER` 的紀錄。
  - 取得對應的 `FactoryOrderItem` ID，進而關聯出 `FactoryOrder` 的 `orderNo`，並設定到 `MrpResultResponse.sourceNo`。
- `**convertToPlannedOrders**`:
  - 在將 `MrpResult` 轉換為 `PlannedOrder` 後，建立新的 `OrderPegging` 紀錄：
    - `demandType = MRP_RESULT`, `demandId = mrpResult.getId()`
    - `supplyType = PLANNED_ORDER`, `supplyId = plannedOrder.getId()`
    - `peggedQuantity = mrpResult.getRequiredQuantity()`

## 2. PlannedOrderServiceImpl 實作

- `**deletePlannedOrderBulk**`:
  - 查詢 `supplyType = PLANNED_ORDER` 且 `supplyId IN (ids)` 的 `OrderPegging` 紀錄。
  - 從這些紀錄中找出 `demandType = MRP_RESULT` 的 `demandId` (即 MrpResult ID)。
  - 將這些 `MrpResult` 的 `isConverted` 設為 `false`。
  - 刪除這些 `OrderPegging` 紀錄。
- `**processSingleConversion**`:
  - 在建立 `ProductionOrder` 後，建立新的 `OrderPegging` 紀錄：
    - `demandType = PLANNED_ORDER`, `demandId = plannedOrder.getId()`
    - `supplyType = PRODUCTION_ORDER`, `supplyId = productionOrder.getId()`
    - `peggedQuantity = plannedOrder.getQuantity()`
  - **更新廠單狀態與分配量**:
    - 透過 Pegging 鏈往上追溯：`PLANNED_ORDER` -> `MRP_RESULT` -> `FACTORY_ORDER` (FactoryOrderItem)。
    - 增加 `FactoryOrderItem` 的 `allocatedQuantity`。
    - 將對應的 `FactoryOrder` 狀態更新為 `IN_PROGRESS`。

## 3. ProductionOrderServiceImpl 實作

- `**rollbackFactoryOrderAllocation`**:
  - 查詢 `supplyType = PRODUCTION_ORDER` 且 `supplyId = po.getId()` 的 `OrderPegging` 紀錄。
  - 找出 `demandType = PLANNED_ORDER` 的 `demandId` (即 PlannedOrder ID)，將其狀態退回 `FIRMED`。
  - 繼續往上追溯至 `FACTORY_ORDER` (FactoryOrderItem)。
  - 扣除 `FactoryOrderItem` 的 `allocatedQuantity`。
  - 若該 `FactoryOrder` 下的所有項目分配量皆為 0，則將 `FactoryOrder` 狀態退回 `CONFIRMED`。
  - 刪除該 `ProductionOrder` 關聯的 `OrderPegging` 紀錄。





太好了！既然您已經成功引入 `OrderPegging` 並重構了相關的 Entity 與 Service，這表示您的系統已經具備了強大的「多對多溯源網路」基礎。

現在，我們來評估如何基於這個 `OrderPegging` 表，實現 **全鏈路進度追蹤查詢 (Full-Chain Traceability)**。這通常是 ERP 系統中生管與業務最需要、但也最難寫的查詢功能。

### 1. 查詢場景分析

全鏈路追蹤通常分為兩個方向：

*   **Top-Down (由上往下 / 需求追供給)**：

    *   **情境**：業務員問「我的這張銷售訂單 (SO) 目前生產進度到哪裡了？」

    *   **路徑`**SALES_ORDER` -> `FACTORY_ORDER` -> `MRP_RESULT` / `PLANNED_ORDER` -> `PRODUCTION_ORDER`

*   **Bottom-Up (由下往上 / 供給追需求)**：

    *   **情境**：現場回報「這張生產工單 (PrO) 缺料要延遲」，生管問「這會影響到哪些客戶的訂單？」

    *   **路徑**`PRODUCTION_ORDER` -> `PLANNED_ORDER` / `MRP_RESULT` -> `FACTORY_ORDER` -> `SALES_ORDER`

### 2. 查詢架構設計評估

由於 `OrderPegging` 是一個**圖狀結構（Graph）**（因為有匯總與拆分，它不是單純的樹狀，而是有向無環圖 DAG），我們在關聯式資料庫（RDBMS）中查詢這種結構，有幾種常見的實現方式：

#### 方案 A：遞迴查詢 (Recursive Query / CTE) - **強烈推薦**

現代資料庫（如 PostgreSQL, MySQL 8.0+, SQL Server 8.0+）都支援 `WITH RECURSIVE` 語法。這是處理 Pegging 網路最有效率且最優雅的方式。

**Top-Down 範例 (給定 SO Item ID，往下找所有關聯單據)：**

```sql

WITH RECURSIVE PeggingTree AS (

    -- 1. Base case: 從指定的 SO 開始找第一層 (SO -> FO)

    SELECT 

        id, demand_type, demand_id, supply_type, supply_id, pegged_quantity, material_id,

        1 as level,

        CAST(demand_id AS VARCHAR(255)) as path -- 記錄路徑方便除錯

    FROM order_peggings

    WHERE demand_type = 'SALES_ORDER' AND demand_id = :soItemId

    UNION ALL

    -- 2. Recursive step: 拿上一層的 supply 作為下一層的 demand 繼續往下找

    SELECT 

        [p.id](http://p.id), p.demand_type, p.demand_id, [p.supply](http://p.supply)_type, [p.supply](http://p.supply)_id, p.pegged_quantity, p.material_id,

        pt.level + 1,

        CONCAT(pt.path, '->', p.demand_id)

    FROM order_peggings p

    INNER JOIN PeggingTree pt 

        ON p.demand_type = [pt.supply](http://pt.supply)_type AND p.demand_id = [pt.supply](http://pt.supply)_id

)

SELECT * FROM PeggingTree;

```

**Bottom-Up 範例 (給定 Production Order ID，往上找所有受影響的 SO)：**

```sql

WITH RECURSIVE PeggingTree AS (

    -- 1. Base case: 從指定的 PrO 開始找第一層 (PrO 往上找)

    SELECT 

        id, demand_type, demand_id, supply_type, supply_id, pegged_quantity, material_id,

        1 as level

    FROM order_peggings

    WHERE supply_type = 'PRODUCTION_ORDER' AND supply_id = :productionOrderId

    UNION ALL

    -- 2. Recursive step: 拿上一層的 demand 作為下一層的 supply 繼續往上找

    SELECT 

        [p.id](http://p.id), p.demand_type, p.demand_id, [p.supply](http://p.supply)_type, [p.supply](http://p.supply)_id, p.pegged_quantity, p.material_id,

        pt.level + 1

    FROM order_peggings p

    INNER JOIN PeggingTree pt 

        ON [p.supply](http://p.supply)_type = pt.demand_type AND [p.supply](http://p.supply)_id = pt.demand_id

)

SELECT * FROM PeggingTree WHERE demand_type = 'SALES_ORDER'; -- 最後只濾出頂層的 SO

```

**優點**：一次 Query 就能把整個網路撈出來，效能極高，不需要在 Java 應用層寫迴圈狂打 DB。

**缺點**：需要寫 Native SQL，JPA/Hibernate 的 Criteria API 對 Recursive CTE 支援度較差。

#### 方案 B：應用層遞迴 (Java Level Recursion)

如果您不想寫 Native SQL，或者資料庫不支援 CTE，可以在 Java Service 層寫遞迴。

```java

public List<OrderPegging> findDownstreamPeggings(PeggingOrderType type, Long id) {

    // 1. 查出第一層

    List<OrderPegging> directSupplies = orderPeggingRepository.findByDemandTypeAndDemandId(type, id);

    List<OrderPegging> allSupplies = new ArrayList<>(directSupplies);

    

    // 2. 對每一個 supply，遞迴往下找

    for (OrderPegging supply : directSupplies) {

        // 避免無窮迴圈（雖然正常業務邏輯不該有環）

        allSupplies.addAll(findDownstreamPeggings(supply.getSupplyType(), supply.getSupplyId()));

    }

    return allSupplies;

}

```

**優點**：純 Java 實作，與資料庫解耦。

**缺點**：**效能極差 (N+1 Query 問題)**。如果網路很深或很廣，會對資料庫發出數十甚至數百次 Query。在 ERP 系統中**非常不建議**這樣做。

---

### 3. 實作建議與架構規劃

要在 `lychee-backend` 中完美實現這個功能，建議採用以下架構：

#### 步驟 1：建立專屬的 `PeggingQueryService`

不要把這個邏輯塞在 `SalesOrderService` 或 `ProductionOrderService` 裡，因為它是跨模組的。建立一個專門負責「追蹤與溯源」的 Service。

#### 步驟 2：定義 DTO (Data Transfer Object)

因為前端需要畫出樹狀圖或甘特圖，您需要定義一個能表達層級關係的 DTO。

```java

@Data

public class PeggingNodeDTO {

    private PeggingOrderType nodeType; // 單據類型

    private Long nodeId;               // 單據 ID

    private String orderNo;            // 單據號碼 (需額外 Join 取得)

    private BigDecimal quantity;       // 數量

    private String status;             // 狀態 (例如: 生產中, 已完工)

    

    // 下游節點 (Top-Down 用) 或 上游節點 (Bottom-Up 用)

    private List<PeggingNodeDTO> relatedNodes = new ArrayList<>(); 

}

```

#### 步驟 3：使用 MyBatis / MyBatis-Plus 或 Native Query (Repository)

由於 JPA/Hibernate 原生不支援 `WITH RECURSIVE`，建議在 `OrderPeggingRepository` 中使用 `@Query(value = "...", nativeQuery = true)` 來撰寫 CTE SQL。

1.  **先用 CTE 撈出所有關聯的 `OrderPegging` 紀錄**。

2.  **在 Java 層進行資料組裝 (Data Assembly)**：

    CTE 撈出來的只是一堆 `demand_id` 和 `supply_id`。您需要根據這些 ID，批次 (Batch) 去撈取實際的單據資訊（例如 `FactoryOrder` 的單號、狀態）。

    *   *千萬不要在 CTE 裡面去 JOIN 所有單據表*（會變成超級大怪獸 SQL）。

    *   *正確做法*：CTE 撈出 Pegging 關係 -> Java 收集所有的 `factory_order_id` -> `factoryOrderRepo.findAllById(ids)` -> Java 收集所有的 `production_order_id` -> `productionOrderRepo.findAllById(ids)` -> 最後在 Java 中把資料組裝成 `PeggingNodeDTO` 樹狀結構。

### 總結

加入 `OrderPegging` 是一個非常正確且具備前瞻性的架構決定。接下來的關鍵在於**查詢效能**。強烈建議使用 **資料庫 Recursive CTE (方案 A)** 撈取關聯網路，搭配 **Java 應用層批次查詢與組裝單據詳情** 的混合策略，這樣既能保證效能，又能提供前端豐富的追蹤資訊。
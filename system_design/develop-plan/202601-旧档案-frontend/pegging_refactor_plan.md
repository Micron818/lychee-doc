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

- `**getMrpResultPage**`:
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


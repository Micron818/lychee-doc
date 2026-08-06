---
name: 委外發料批次產生實作
overview: 實作 WM 模組 batchCreateItemsFromOutsource 功能，讓倉管人員能快速從委外單待發料項目產生領料單明細。
todos:
  - id: step-1-dtos
    content: 新增 RemoteOutsourceOrderComponentDTO 與 BatchOutsourceIssueRequest
    status: completed
  - id: step-2-scm-remote
    content: 擴充 RemoteOutsourceOrderService 並於 SCM 模組實作 getComponentsByIds
    status: completed
  - id: step-3-wm-remote
    content: 擴充 RemoteStockIssueService 與 Repository，並於 WM 模組實作 sumDraftBaseQuantityByOutsourceOrderComponentIds
    status: completed
  - id: step-4-wm-service
    content: 實作 StockIssueServiceImpl.batchCreateItemsFromOutsource 核心邏輯
    status: completed
  - id: step-5-wm-controller
    content: 於 StockIssueController 新增對應的 POST API 端點
    status: completed
isProject: false
---

# 委外加工系統：批次產生委外發料明細 (Batch Create from Outsource)

本計劃旨在實作類似 `batchCreateItemsFromProduction` 的機制，允許從委外單 (Outsource Order) 的用料 (Component) 直接產生 WM 模組的領料單明細 (Stock Issue Item)。

## 1. 建立 DTO 與 Common 介面
擴充跨模組通訊所需的 DTO 與 Service 介面，讓 WM 模組能取得 SCM 模組的委外用料資訊。
*   於 `lychee-erp-common` 模組的 `dto/response` 新增 `RemoteOutsourceOrderComponentDTO`，包含：
    *   `id`, `outsourceOrderId`, `outsourceOrderNo`
    *   `orderStatus` (OutsourceOrderStatus)
    *   `materialId`, `requiredQuantity`, `issuedQuantity`, `isSupplierProvided`
*   於 `lychee-erp-common` 模組的 `RemoteOutsourceOrderService` 新增：
    *   `List<RemoteOutsourceOrderComponentDTO> getComponentsByIds(Set<Long> componentIds);`
*   於 `lychee-erp-common` 模組的 `RemoteStockIssueService` 新增：
    *   `Map<Long, BigDecimal> sumDraftBaseQuantityByOutsourceOrderComponentIds(Set<Long> componentIds);`

## 2. 實作 SCM 與 WM 的 Remote Service
實作剛剛定義好的跨模組方法。
*   於 `lychee-erp-scm` 模組的 `RemoteOutsourceOrderServiceImpl` 實作 `getComponentsByIds`：
    *   透過 `OutsourceOrderComponentRepository` 查詢指定的 Components。
    *   關聯 `OutsourceOrderItem` 與 `OutsourceOrder`，取得委外單號與訂單狀態。
    *   組裝並回傳 `RemoteOutsourceOrderComponentDTO` 列表。
*   於 `lychee-erp-wm` 模組的 `StockIssueItemRepository`：
    *   新增 `@Query` 以 `sourceDocType = 'OUTSOURCE_ORDER_COMPONENT'` 聚合查詢草稿數量 (可建立或沿用類似 `ProductionOrderComponentQuantitySum` 的 Projection 介面)。
*   於 `lychee-erp-wm` 模組的 `RemoteStockIssueServiceImpl`：
    *   呼叫 Repository 方法實作 `sumDraftBaseQuantityByOutsourceOrderComponentIds`。

## 3. WM 模組：實作 Batch Create 邏輯
於領料單服務中加入核心的批次產生邏輯。
*   於 `lychee-erp-wm` 模組的 `dto/request` 新增 `BatchOutsourceIssueRequest`：
    *   內部包含 `IssueItem` (含 `outsourceOrderComponentId`, `issueQuantity`, `warehouseId`, `batchNo`, `transactionUnitId`)。
*   於 `lychee-erp-wm` 模組的 `StockIssueService` 介面與 `StockIssueServiceImpl` 實作 `batchCreateItemsFromOutsource`：
    *   檢核 Header 狀態為 `DRAFT`。
    *   呼叫 `getComponentsByIds` 取得委外用料資訊。
    *   **驗證邏輯**：
        1.  對應的委外單狀態必須為 `ISSUED` 或 `PARTIAL`。
        2.  必須為客供料 (`isSupplierProvided == false`) 才能發料。
        3.  數量檢核：`issuedQuantity + 草稿發放量 (draftQuantity) + 本次新增量 <= requiredQuantity`。
    *   實作 Upsert 邏輯 (同 `batchCreateItemsFromProduction`)，將資料轉為 `StockIssueItem` (帶入 `sourceDocType = OUTSOURCE_ORDER_COMPONENT`)。
    *   更新 `StockOnHandInventoryService.reserveStock` 保留庫存，並儲存至資料庫。

## 4. 暴露 Controller API
*   於 `lychee-erp-wm` 模組的 `StockIssueController` 新增 API：
    *   `POST /api/v1/wm/stock-issues/{stockIssueId}/items/batch-from-outsource`。
    *   接收 `BatchOutsourceIssueRequest` 並呼叫 `stockIssueService.batchCreateItemsFromOutsource`。
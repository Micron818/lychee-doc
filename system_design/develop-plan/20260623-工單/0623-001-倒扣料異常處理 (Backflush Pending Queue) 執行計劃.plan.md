---
name: Backflush Pending Queue
overview: Implement a Pending Queue (Option 2) to track and resolve backflush material shortages during production reporting.
todos:
  - id: step-1-data-model
    content: Create ProductionBackflushException entity, enum, repository, and Flyway migration
    status: completed
  - id: step-2-detect-shortages
    content: Update ProductionReportServiceImpl to detect shortages and create exceptions during postProductionReport
    status: completed
  - id: step-3-reverse-handling
    content: Update ProductionReportServiceImpl to handle exceptions during reverseProductionReport
    status: completed
  - id: step-4-resolution-api
    content: Create ProductionBackflushExceptionService and Controller with page and reprocess APIs
    status: completed
  - id: step-5-close-validation
    content: Update ProductionOrderServiceImpl.closeProductionOrder to block closing if pending exceptions exist
    status: completed
isProject: false
---

# 倒扣料異常處理 (Backflush Pending Queue) 執行計劃

本計劃採用「方案二：建立異常待處理佇列」的架構，當報工倒扣料時若庫存不足，系統會放行報工，但將短少的數量記錄至異常佇列中。後續可透過專屬介面重新執行扣料，並在工單結案時進行嚴格卡控。

## 1. 資料庫與實體設計 (Data Model)
新增 `ProductionBackflushException` 實體與資料表，用於記錄應扣未扣的差異。

- **新增 Enum**: `ProductionBackflushExceptionStatus` (`PENDING`, `RESOLVED`)
- **新增 Entity**: `ProductionBackflushException`
  - `id`, `tenantId`, `factoryId`
  - `productionOrderId` (關聯工單)
  - `productionReportId` (關聯報工單)
  - `productionOrderComponentId` (關聯工單用料)
  - `materialId` (物料)
  - `issueUnitId` (發料單位)
  - `missingQuantity` (短少數量)
  - `status` (狀態)
- **新增 Repository**: `ProductionBackflushExceptionRepository`
- **新增 Flyway Script**: 建立 `production_backflush_exceptions` 資料表。

## 2. 異常偵測與記錄 (Detection)
修改 `ProductionReportServiceImpl`，在報工過帳與反過帳時處理異常紀錄。

- **報工過帳 (`postProductionReport`)**:
  - 在扣料邏輯後，撈取該工單所有 `isBackflush = true` 的 `ProductionOrderComponent`。
  - 計算理論應耗用量：`theoreticalQty = (goodQty + scrapQty) * requiredQuantity / plannedQuantity`。
  - 比對實際已扣量 `actualIssueQty` (來自 `ProductionReportComponent`)。
  - 若 `theoreticalQty > actualIssueQty`，則建立 `ProductionBackflushException` (狀態為 `PENDING`)。
- **報工反過帳 (`reverseProductionReport`)**:
  - 檢查該報工單關聯的 `ProductionBackflushException`。
  - 若有狀態為 `RESOLVED` 的紀錄，拋出 `ValidationException` 阻斷反過帳 (需先處理已補扣的料)。
  - 若皆為 `PENDING`，則直接刪除這些異常紀錄。

## 3. 異常處理與補扣料 API (Resolution)
實作獨立的 Service 與 Controller 供前端查詢與重新處理異常。

- **查詢 API**: `GET /api/v1/pp/backflush-exceptions/page` (支援分頁與多條件過濾)。
- **重新處理 API**: `POST /api/v1/pp/backflush-exceptions/reprocess` (傳入 Exception ID 列表)。
  - **邏輯**:
    1. 針對每個 Exception，呼叫 `remoteStockOnHandService.suggestAllocations` 檢查可用庫存。
    2. 若有可用庫存，建立 `RemoteProductionBackflushRequestDTO`。
    3. 呼叫 `remoteProductionInventoryService.postBackflushMaterials` 產生 `StockIssue` (發料單) 扣減庫存。
    4. 更新 `ProductionOrderComponent.issuedQuantity` (累加已發量)。
    5. 更新 `ProductionBackflushException` 的 `missingQuantity` (扣減) 與 `status` (若扣完則改為 `RESOLVED`)。

## 4. 工單結案卡控 (Order Close Validation)
確保成本結算前，所有欠料皆已補齊。

- 修改 `ProductionOrderServiceImpl.closeProductionOrder`。
- 檢查 `ProductionBackflushExceptionRepository.existsByProductionOrderIdAndStatus(id, PENDING)`。
- 若存在未處理的異常，拋出 `ValidationException` ("該工單尚有未處理的倒扣料異常，不允許結案")。
---
name: Write Reprocess to ReportComponent
overview: Update reprocessExceptions to insert a new ProductionReportComponent record with remarks, and remove the validation block in reverseProductionReport.
todos:
  - id: step-1-insert-report-component
    content: Update ProductionBackflushExceptionServiceImpl to insert ProductionReportComponent and pass its ID to postBackflushMaterials
    status: completed
  - id: step-2-remove-reverse-validation
    content: Update ProductionReportServiceImpl.reverseProductionReport to remove the RESOLVED validation block
    status: completed
isProject: false
---

# 將補扣料紀錄寫回 ProductionReportComponent 執行計劃

本計劃旨在優化倒扣料異常處理 (Backflush Pending Queue) 的流程。當使用者在 `ProductionBackflushExceptionServiceImpl.reprocessExceptions` 中成功補扣料後，系統將會新增一筆 `ProductionReportComponent` 紀錄，並在 `remarks` 欄位標註來源為「倒扣異常處理」。這樣一來，報工單的反過帳 (`reverseProductionReport`) 就能自動處理這些事後補扣的料，我們也不再需要阻擋 `RESOLVED` 狀態的異常紀錄反過帳。

## 1. 修改 `ProductionBackflushExceptionServiceImpl.reprocessExceptions`

在成功呼叫 `remoteProductionInventoryService.postBackflushMaterials` 扣減庫存並更新 `ProductionOrderComponent` 後，新增邏輯以建立並儲存 `ProductionReportComponent`：

- 注入 `ProductionReportComponentRepository` (若尚未注入)。
- 針對每一個成功分配的庫存 (`AllocationSuggestResponse.Allocation`)，建立一個 `ProductionReportComponent` 實體：
  - `tenantId`: 從 `exception` 或 `report` 取得。
  - `productionReportId`: `exception.getProductionReportId()`
  - `productionOrderComponentId`: `exception.getProductionOrderComponentId()`
  - `warehouseId`: `allocation.getWarehouseId()`
  - `batchNo`: `allocation.getBatchNo()` (若為 null 則設為空字串 `""`)
  - `materialId`: `exception.getMaterialId()`
  - `unitId`: `exception.getIssueUnitId()`
  - `issueQuantity`: `allocation.getAllocateQuantity()`
  - `remarks`: `"倒扣異常處理 (Reprocess Exception)"`
- 將這些實體儲存至 `ProductionReportComponentRepository`。

## 2. 修改 `ProductionReportServiceImpl.reverseProductionReport`

因為補扣料的紀錄已經寫回 `ProductionReportComponent`，當報工單反過帳時，原本的邏輯 (撈取所有 `components` 並呼叫 `reverseBackflushMaterials`) 就會自動把這些事後補扣的料也反轉掉。

- **移除阻擋邏輯**：刪除檢查 `hasResolved` 並拋出 `ValidationException("validation.productionReport.cannotReverseWithResolvedExceptions")` 的程式碼區塊。
- **清理異常紀錄**：保留 `backflushExceptionRepository.deleteAll(exceptions);`，無論異常紀錄的狀態是 `PENDING` 還是 `RESOLVED`，在報工單反過帳時一律將其刪除。

## 3. 調整 `RemoteProductionInventoryServiceImpl.postBackflushMaterials` (建議)

為了讓庫存交易 (StockIssueItem) 的 `sourceDocId` 能夠正確對應到新建立的 `ProductionReportComponent`，我們需要調整 `reprocessExceptions` 呼叫 `postBackflushMaterials` 的順序或參數：

- **調整順序**：先 `save` 新的 `ProductionReportComponent`，取得其 `id`。
- **設定 SourceDocId**：在建立 `RemoteProductionBackflushRequestDTO.Item` 時，將 `sourceDocId` 設為新建立的 `ProductionReportComponent.getId()`，而非 `exception.getId()`。
- 這樣能保持庫存模組 (`WM`) 與生產模組 (`PP`) 之間的文件關聯一致性。


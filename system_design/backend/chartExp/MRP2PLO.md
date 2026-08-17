在目前的系統實現中，MRP 計算到產生計劃訂單（Planned Order）的過程遵循 **「計算建議 -> 審核確認 -> 轉化單據」** 的異步模式。

以下是詳細的技術流程說明：

### 1. 產生建議階段 (`MrpResult`)
當您執行 `MrpService.calculateMrp` 時，系統並不會直接建立計劃訂單，而是先產生 **`MrpResult` (MRP 運算結果/建議)**。
*   **遞歸展開**：系統根據 BOM 結構，將工廠訂單 (FO) 的需求層層分解。
*   **判定動作**：
    *   如果有 BOM，系統記錄一條 `suggestedActionType = PRODUCTION` (生產) 的建議。
    *   如果沒有 BOM，系統記錄一條 `suggestedActionType = PURCHASE` (採購) 的建議。
*   **儲存結果**：這些建議被存放在 `mrp_results` 表中，供計畫員在 UI 上查看、調整或過濾。

### 2. 人工/系統確認階段 (待實作/擴展)
在典型的 ERP 流程中，計畫員會查看 MRP 結果，決定哪些建議要變成真實的計畫：
*   計畫員可以修改建議的數量或日期。
*   計畫員勾選多筆 `MrpResult`，點擊「轉化為計劃訂單」。

### 3. 單據轉化階段 (`PlannedOrder`)
雖然目前代碼中主要實作了「計劃訂單轉生產單 (MO)」，但從 `MrpResult` 到 `PlannedOrder` 的轉化邏輯如下（這部分通常在 `MrpService` 或 `PlannedOrderService` 中）：

**轉化邏輯核心步：**
1.  **讀取結果**：獲取狀態為 `isConverted = false` 的 `MrpResult`。
2.  **建立計畫**：為每一筆（或合併後的）`MrpResult` 建立一筆 `PlannedOrder`：
    *   `MrpResult.materialId` $\rightarrow$ `PlannedOrder.productMaterialId`
    *   `MrpResult.requiredQuantity` $\rightarrow$ `PlannedOrder.quantity`
    *   `MrpResult.suggestedActionType` $\rightarrow$ `PlannedOrder.orderType` (這裡就涉及我們剛討論的 **PRODUCTION $\rightarrow$ MAKE** 或 **PURCHASE $\rightarrow$ BUY** 的映射)。
3.  **回寫狀態**：更新 `MrpResult`：
    *   `isConverted = true`
    *   `convertedRefId = PlannedOrder.id` (建立追溯鏈結)。

### 4. 目前代碼中的體現
您可以在 `MrpResult` 模型中看到這些關鍵欄位：

```java
public class MrpResult extends AuditableEntity {
    // ...
    private Long materialId;
    private LocalDate requiredDate;
    private BigDecimal requiredQuantity;

    @Enumerated(EnumType.STRING)
    private MrpActionType suggestedActionType; // PURCHASE, PRODUCTION, OUTSOURCE

    @Enumerated(EnumType.STRING)
    private MrpSourceType sourceType; // FACTORY_ORDER, etc.
    
    private Long sourceId; // 關聯的 FactoryOrder ID

    private Boolean isConverted; // 是否已轉化為計畫單
    private Long convertedRefId; // 轉化後的 PlannedOrder ID
}
```

### 總結
MRP 計算產生的是 **「建議」(`MrpResult`)**，它是一個運算過程中的中間狀態。
**計劃訂單 (`PlannedOrder`)** 則是對建議的 **「執行承諾」**。

**您是否需要我現在為您實作「MRP 結果轉計劃訂單」的批量轉化邏輯？** (這通常會包含在 `MrpService` 的一個 `convertToPlannedOrders` 方法中)。
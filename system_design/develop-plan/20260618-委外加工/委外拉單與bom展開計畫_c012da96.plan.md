---
name: 委外拉單與BOM展開計畫
overview: 基於 SCM 拉單模式，修正現有的 BOM 展開邏輯，並建立 PP 與 SCM 之間的跨模組通訊以完成委外計畫單的轉換與溯源 (Pegging)。
todos:
  - id: fix-expand-bom
    content: 修正 `OutsourceOrderComponentManageServiceImpl.expandBom` 的廢品率 (scrapRate) 計算 Bug。
    status: pending
  - id: create-common-interfaces
    content: 在 `common` 模組定義 PP 提供給 SCM 的 RPC 介面 (`RemotePlannedOrderService`) 與相關 DTO。
    status: pending
  - id: implement-pp-rpc
    content: 在 `PP` 模組實作待處理清單查詢與拉單後的回撥邏輯 (狀態更新至 CONVERTED 與建立 OrderPegging)。
    status: pending
  - id: implement-scm-pull
    content: 在 `SCM` 模組實作拉單業務邏輯 (建立 Item、展開 Component，並呼叫 PP callback)。
    status: pending
isProject: false
---

# 委外計畫單拉單流程 (Pull-based) 與 BOM 展開優化計畫

經過程式碼分析，SCM 模組中已經實作了透過 `RemoteBomService` 取得 BOM 並展開的 `expandBom` 方法。這對我們的架構是一個好消息，這意味著 **PP 模組不需要在拉單時負責展開 BOM 傳給 SCM**，SCM 完全可以自給自足地產生元件需求。

## 一、 `expandBom` 方法分析與調整建議

查看 `@lychee-erp-scm/src/main/java/com/lychee/erp/scm/service/impl/OutsourceOrderComponentManageServiceImpl.java:141`，有兩個需要調整的地方：

1.  **⚠️ 嚴重的廢品率 (Scrap Rate) 計算 Bug**：
    *   **現狀**：程式碼直接將 `scrapRate` 加上 `1` (例如 5% 會變成 `1 + 5.0 = 6.0`)，導致需求量暴增 6 倍。
    *   **調整**：必須與 `PP` 模組的邏輯對齊，將其除以 100。
    ```java
    // 應修改為：
    BigDecimal scrapRate = bomItem.scrapRate() != null ? 
        bomItem.scrapRate().divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
    BigDecimal requiredQty = item.getOrderedQuantity()
            .multiply(bomItem.quantity())
            .multiply(BigDecimal.ONE.add(scrapRate))
            .setScale(6, RoundingMode.HALF_UP);
    ```
2.  **取 BOM 的基準日 (有效日期) 優化**：
    *   **現狀**：目前使用 `order.getOrderDate()` (委外單建立日期) 來取 BOM。
    *   **調整**：如果是從 MRP/PlannedOrder 拉單，為了確保取得與 MRP 展算時完全一致的 BOM 版本，建議 SCM 在拉單建立 Item 時，能將計畫單的「預計開工日 (`plannedStartDate`)」記錄下來，並在展開 BOM 時優先以此日期為基準。

---

## 二、 執行計畫步驟

### Phase 1: 建立 Common RPC 介面與 DTO
在 `lychee-erp-common` 模組定義 PP 提供給 SCM 的服務：
*   **查詢介面**：`List<RemotePlannedOrderDTO> getPendingOutsourceOrders(Long factoryId)`，供 SCM 查詢可拉取的清單 (Type: OUTSOURCE, Status: FIRMED)。
*   **回撥介面**：`void callbackAfterOutsourcePulled(List<RemotePlannedOrderCallbackDTO> callbacks)`，供 SCM 通知 PP 更新狀態。
*   **DTO 定義**：包含計畫單的物料、數量、日期等資訊，以及 Callback 用的 IDs。

### Phase 2: PP 模組實作 (`lychee-erp-pp`)
*   實作上述 `RemotePlannedOrderService`。
*   **Callback 邏輯**：收到 SCM 成功拉單的通知後，將對應的 `PlannedOrder` 狀態更新為 `CONVERTED`。
*   **建立 Pegging**：寫入 `OrderPegging`，綁定 `demandType = PLANNED_ORDER` 與 `supplyType = OUTSOURCE_ORDER`。

### Phase 3: SCM 模組優化 `expandBom` (`lychee-erp-scm`)
*   修正 `OutsourceOrderComponentManageServiceImpl` 中的 `scrapRate` 數學計算錯誤。

### Phase 4: SCM 模組實作拉單業務邏輯 (`lychee-erp-scm`)
*   在 `OutsourceOrderService` 新增方法（如 `pullFromPlannedOrders(Long outsourceOrderId, Set<Long> plannedOrderIds)`）。
*   **邏輯流程**：
    1. 驗證 Header 狀態。
    2. 透過 RPC (或由前端帶入的資料) 取得 `PlannedOrder` 資訊。
    3. 迴圈建立 `OutsourceOrderItem`。
    4. 針對每個 Item，呼叫 (或重用) `expandBom` 的邏輯來產生 `OutsourceOrderComponent`。
    5. 儲存至資料庫。
    6. 收集 `plannedOrderId` 與產生的 `outsourceOrderItemId`，呼叫 PP 的 `callbackAfterOutsourcePulled` 完成整個流程。
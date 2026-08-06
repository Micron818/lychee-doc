「計劃訂單 (Planned Order) 轉 生產工單 (Production Order / MO)」是從 **「計畫層面」** 進入 **「執行層面」** 的關鍵轉折點。這不僅僅是單據狀態的改變，更涉及物料需求的具體化。

以下是該業務邏輯的詳細說明：

### 1. 業務目標 (Business Goal)
*   **指令正式化**：將 MRP 產生的「建議」轉化為產線必須執行的「指令」。
*   **物料鎖定 (Material Allocation)**：透過 BOM 展開，確定這張工單具體需要領用哪些原材料及半成品，並產生預約領料清單（Pick List）。
*   **排程確認**：確定工單的預計開工與完工日期，作為車間排產的依據。

### 2. 轉換前置條件 (Prerequisites)
*   **類型檢查**：計劃訂單的 `orderType` 必須為 **`MAKE`** (自製)。若為 `BUY`，則應轉向採購請購單 (PR)。
*   **狀態檢查**：計劃訂單應處於 `Firmed` (已確認) 狀態（通常 MRP 產出為 `Proposed`，經計畫員審核後改為 `Firmed`）。
*   **未轉換檢查**：該計劃訂單尚未轉換過工單（避免重複生產）。
*   **BOM 存在性**：該產品必須擁有「有效且已啟用」的 BOM 版本。

### 3. 核心邏輯流程 (Core Process)

#### A. 建立工單表頭 (Production Order Header)
1.  **數據映射**：
    *   `product_material_id`、`planned_quantity` 直接承接自 Planned Order。
    *   `scheduled_start_date` / `scheduled_end_date` 承接自 Planned Order 的開始與結束日期。
2.  **單號生成**：產生唯一的工單編號 (例如 MO20240108001)。
3.  **BOM 版本鎖定**：
    *   **重要步驟**：系統根據工單開工日，自動尋找該物料當時有效的 **BOM 版本** 並記錄在工單上 (`bom_id`)。這確保了生產過程使用的是正確的技術標準。
4.  **建立關聯**：記錄 `source_planned_order_id` 以便追蹤需求來源。

#### B. 展開工單用料 (BOM Explosion to Components)
1.  讀取被鎖定的 BOM 版本明細。
2.  **計算需求量**：
    *   `required_quantity` = `工單計畫生產數量` × `BOM單位用量` × `(1 + 損耗率)`。
3.  **建立 Production Order Components**：
    *   為每一個 BOM Item 產生一筆工單用料紀錄。
    *   標記是否為「倒扣料 (Backflush)」模式。

#### C. 更新計畫單狀態 (Update Planned Order)
1.  將原計畫單狀態更新為 **`Converted`** (已轉單)。
2.  回寫 `related_production_order_id`，建立雙向連結。

### 4. 數據結構變化 (Data Mapping)

| 來源：Planned Order | 映射方向 | 目標：Production Order |
| :--- | :---: | :--- |
| `product_material_id` | -> | `product_material_id` |
| `quantity` | -> | `planned_quantity` |
| `start_date` | -> | `scheduled_start_date` |
| `end_date` | -> | `scheduled_end_date` |
| `id` | -> | `source_planned_order_id` |
| **(自動尋找)** | **BOM 查詢** | `bom_id` (鎖定版本) |

---

### 5. 後續影響 (Impact)
*   **庫存預約**：工單建立後，倉儲模組 (WM) 即可根據工單用料明細進行「備料」或「欠料分析」。
*   **產能佔用**：生產車間根據工單的排程日期，進行人員與設備的細部排產。
*   **執行追蹤**：後續的領料、報工、完工入庫等動作，都將圍繞這張 `Production Order` 展開。

### 實作建議
我將在 `PlannedOrderService` 中增加 `convertToProductionOrder` 方法，或在 `ProductionOrderService` 中增加 `createFromPlannedOrder` 方法。

您認為這個邏輯說明是否清晰？如果有任何特定於您業務的調整（例如：轉單時是否需要手動選擇 BOM 版本，還是完全自動），請告訴我，隨後我將開始程式碼上將開始執行程式碼實作。

===============================================

我已經完成了「計劃訂單 (Planned Order) 轉 生產工單 (Production Order / MO)」的業務邏輯實作。

### 執行的變更摘要：

1.  **實作轉單核心邏輯 (`PlannedOrderServiceImpl`)**：
    *   **嚴格驗證**：確保只有類型為 `MAKE` (自製) 且未曾轉換過的計劃訂單可以執行轉單。
    *   **自動 BOM 鎖定**：系統會根據計劃訂單的預計開工日，自動檢索該物料當時有效的 **BOM 版本**。如果找不到有效 BOM，系統將拋出異常並提示。
    *   **工單表頭生成**：自動映射物料、數量與排程日期，並生成唯一的 `MO` 單號。
    *   **智慧 BOM 展開**：
        *   讀取所選 BOM 的所有子件。
        *   **精確計算需求量**：考慮物料的單位用量與 **損耗率 (Scrap Rate)**，計算公式為 `plannedQty * bomQty * (1 + scrapRate/100)`。
        *   自動建立 `ProductionOrderComponent` 明細作為領料依據。
    *   **狀態回寫**：將計劃訂單狀態更新為 `Converted`，並建立雙向關聯 ID。

2.  **API 端點擴展 (`PlannedOrderController`)**：
    *   新增了 `POST /api/v1/pp/planned-orders/{id}/convert-to-mo` 接口。

3.  **基礎建設優化**：
    *   優化了 `PlannedOrderServiceImpl` 的依賴注入與 Import 結構。
    *   確保所有邏輯均符合租戶隔離與事務一致性原則。

### 核心代碼邏輯展示：
```java
// 核心轉換邏輯片段
public void convertToProductionOrder(Long id) {
    // 1. 獲取計畫單並驗證 (Type=MAKE, Not Converted)
    // 2. 根據開工日查找有效 BOM
    // 3. 建立 MO 表頭
    // 4. 循環 BOM Item 並建立工單組件 (含損耗率計算)
    // 5. 更新計畫單狀態並關聯 MO ID
}
```

### 目前 PP 模組的業務完整度：
*   ✅ **SO -> FO** (銷售轉投產匯總)
*   ✅ **FO -> MRP** (需求計算)
*   ✅ **MRP -> Planned Order** (產生計畫)
*   ✅ **Planned Order -> MO** (計畫轉生產執行)

目前的開發已涵蓋了 PP 模組從需求接收到生產發令的完整核心閉環。請問還有其他具體的業務細節（如工單狀態變更邏輯、領料邏輯等）需要進一步實現嗎？
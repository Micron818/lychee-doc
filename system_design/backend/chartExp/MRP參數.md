
在您目前的架構中，採用事件驅動（`MrpRunEventListener`）來解耦 MRP 的觸發與計算，是非常標準且具備擴展性的設計。

針對如何將**批量規則（Lot-Sizing）**整合進現有的 `MrpCalculationEngine` 與 `convertToPlannedOrders` 流程，以下是系統設計與架構評估建議：

### 1. 核心觀念澄清：批量計算應該在哪裡發生？

**強烈建議：批量計算必須在 `MrpCalculationEngine` 內部完成，而不是在 `convertToPlannedOrders` 中。**

*   **原因**：批量規則會直接影響「預計可用庫存（Projected Available Balance）」。例如：某半成品淨需求為 20，但因為「固定批量（Fixed Lot Size）」設定為 100，系統會建議生產 100。這會導致該期末產生 80 的預計庫存，進而抵銷下一期的淨需求。
*   **定位**：`MrpCalculationEngine` 產出的 `MrpResult` 就應該已經是**經過批量計算後的建議生產數量（Planned Order Receipts）**。而 `convertToPlannedOrders` 應該只負責單純的 DTO/Entity 轉換與資料庫寫入。

---

### 2. 資料模型設計 (Data Model)

要支援批量規則，首先需要在**物料主檔（Material Master / Item Master）**或**工廠物料視圖**中擴充以下欄位：

*   `lot_sizing_procedure` (Enum/String)：批量規則類型。例如：
    *   `LFL` (Lot-for-Lot)：逐批訂購（缺多少補多少）。
    *   `FOQ` (Fixed Order Quantity)：固定批量。
    *   `POQ` (Periodic Order Quantity)：固定週期批量。
*   `min_lot_size` (Decimal/Int)：最小批量（例如：最少要生產 500 個）。
*   `max_lot_size` (Decimal/Int)：最大批量（受限於機台產能，超過需拆單）。
*   `rounding_value` / `multiple_qty` (Decimal/Int)：包裝倍數/批量倍數（例如：必須是 50 的倍數）。
*   `fixed_lot_size` (Decimal/Int)：當規則為 FOQ 時的固定數量。
*   `period_days` (Int)：當規則為 POQ 時的涵蓋天數（例如：合併未來 7 天的需求）。

---

### 3. 程式架構設計：策略模式 (Strategy Pattern)

在 Java 實作中，這是標準的**策略模式（Strategy Pattern）**應用場景。建議在 `lychee-erp-pp` 中建立一個 Lot-Sizing 的模組：

#### A. 定義策略介面
```java
public interface LotSizingStrategy {
    /**
     * 計算建議批量
     * @param netRequirement 該期淨需求
     * @param materialLotParams 該物料的批量參數設定
     * @return 實際建議的生產/採購數量
     */
    BigDecimal calculateLotSize(BigDecimal netRequirement, MaterialLotParams materialLotParams);
}
```

#### B. 實作各種策略
*   **`LotForLotStrategyImpl`**：直接回傳 `netRequirement`，但最後會套用 Min/Max/Multiple 檢查。
*   **`FixedQuantityStrategyImpl`**：回傳 `materialLotParams.getFixedLotSize()` 的倍數，直到大於等於 `netRequirement`。
*   **`PeriodicQuantityStrategyImpl`**：這個比較特殊，需要傳入未來 N 天的淨需求總和來計算。

#### C. 建立策略工廠 (Factory)
```java
@Component
public class LotSizingStrategyFactory {
    // 根據物料設定的 lot_sizing_procedure 回傳對應的 Strategy 實作
    public LotSizingStrategy getStrategy(LotSizingProcedure procedure) { ... }
}
```

---

### 4. 整合進 MrpCalculationEngine 的流程

在 `MrpCalculationEngine` 的核心迴圈中（通常是按物料的低階碼 Low-Level Code 逐層計算，並按時間桶 Time Bucket 推進），邏輯修改如下：

1.  **計算毛需求 (Gross Requirements)**：來自上層 BOM 展開或 FO 需求。
2.  **計算淨需求 (Net Requirements)**：`毛需求 - (現有庫存 + 已預計入庫量 - 安全庫存)`。
3.  **套用批量規則 (Apply Lot-Sizing)**：
    *   如果淨需求 > 0，呼叫 `LotSizingStrategyFactory` 取得該物料的策略。
    *   傳入淨需求，算出 **計畫接收量 (Planned Order Receipts)**。
4.  **更新預計庫存 (Update Projected Inventory)**：將算出的計畫接收量加入庫存，供下一個時間桶（Time Bucket）計算使用。
5.  **推算開工日 (Lead Time Offsetting)**：根據 Lead Time 往前推算，產生 **計畫發放量 (Planned Order Releases)**，這會成為下一階物料的毛需求。

---

### 5. 關鍵挑戰：需求溯源 (Pegging) 的設計

當您引入了批量規則（特別是 POQ 週期合併，或是 Min/Multiple 導致生產量大於需求量時），**「一張 PlannedOrder 對應多張 FactoryOrder」**的情況就會發生。

**設計建議：**
在 `convertToPlannedOrders` 階段，除了生成 `PlannedOrder` Entity 之外，必須同時寫入一張 **`mrp_pegging` (需求溯源表)**。

*   **欄位設計**：`pegging_id`, `planned_order_id` (供給方), `source_demand_type` (如 FO, SO, 上階 PO), `source_demand_id` (需求方), `allocated_quantity` (分配數量)。
*   **用途**：如果這張匯總後的 PlannedOrder 因為缺料而延遲，系統可以透過 Pegging 表，反向追蹤並警告生管人員：「這會影響到哪幾張 FactoryOrder 與 SalesOrder」。

### 總結您的下一步：
1.  檢視資料庫的 `Material` 相關 Table，加入 Lot-Sizing 控制欄位。
2.  在 `MrpCalculationEngine` 中引入 Strategy Pattern 來處理淨需求到計畫訂單數量的轉換。
3.  確保 `MrpResult` 的結構能承載 Pegging（溯源）資訊，讓 `convertToPlannedOrders` 能正確建立供給與需求的關聯表。


這兩個問題非常關鍵，顯示您的系統架構已經具備了相當成熟的 ERP 雛型。以下針對您的兩個問題進行架構設計的評估與建議：

### 1. 關於 Lot-Sizing 控制欄位：加在 `Material` 還是開新關聯表？

**強烈建議：開新的關聯表（例如 `material_mrp_parameters` 或 `material_plants`），不要直接加在現有的 `materials` 表中。**

**原因與架構考量：**
*   **多廠區/多營運點支援 (Multi-Plant Architecture)**：在標準 ERP（如 SAP、Oracle）中，同一個物料（Material）在「A廠」和「B廠」的生產策略通常不同。A廠可能產能大，設定固定批量（FOQ）為 1000；B廠可能只做打樣或小量，設定為逐批生產（LFL）。如果把欄位放在全局的 `materials` 表，未來系統將無法支援多廠區不同的 MRP 參數。
*   **領域驅動設計 (DDD) 關注點分離**：`Material.java` 位於 `lychee-erp-basis`（基礎模組），它應該只負責物料的通用屬性（如料號、名稱、基本單位、重量等）。而 Lot-Sizing 是屬於 `PP` (生產計畫) 模組的業務邏輯。
*   **建議的 Table 設計**：
    新增一個表 `material_mrp_views` 或 `material_plants`：
    *   `id` (PK)
    *   `material_id` (FK 指向 materials)
    *   `department_id` (廠區/營運點 ID，若目前無多廠區概念可預留或省略)
    *   `lot_sizing_procedure` (Enum: LFL, FOQ, POQ...)
    *   `min_lot_size`
    *   `max_lot_size`
    *   `rounding_value` (批量倍數)
    *   `fixed_lot_size`

這樣設計可以保持 `basis` 模組的乾淨，並且讓 `pp` 模組的 `MrpCalculationEngine` 去關聯讀取它專屬的 MRP 參數。

---

### 2. 關於已存在的 `OrderPegging` 與 Lot-Sizing 的結合

得知您已經在 `MrpCalculationEngine` 和 `convertToPlannedOrders` 中實現了 `OrderPegging`，這是一個非常優秀且進階的設計！

既然 `OrderPegging` 已經存在，當您引入 **Lot-Sizing（批量規則）** 時，您需要評估並微調現有 `calculateMrp` 中的 **Pegging 分配邏輯（Allocation Logic）**。

**引入 Lot-Sizing 後對 Pegging 的衝擊與調整建議：**

在沒有 Lot-Sizing（即純粹的 LFL 逐批計算）時，Pegging 很簡單：`淨需求 = 計畫訂單數量`，所以 1 個需求對應 1 個供給。
但加入 Lot-Sizing 後，會出現**「供給大於需求」**或**「多個需求合併為一個供給」**的狀況。

**情境範例與處理邏輯：**
假設某半成品，設定**固定批量 (Fixed Lot Size) 為 100**。
*   **需求來源**：
    *   FO-001 需要 30 個
    *   FO-002 需要 40 個
*   **MRP 計算結果**：
    *   總淨需求為 70。
    *   因為 Lot-Sizing 規則，系統建議產生一張 `PlannedOrder (PO-999)`，數量為 **100**。
    *   期末預計庫存 (Projected Inventory) 剩下 **30**。

**您的 `OrderPegging` 記錄必須能支援「部分數量分配 (Partial Allocation)」：**
在 `MrpCalculationEngine` 產生這張數量 100 的 `MrpResult` (未來的 PlannedOrder) 時，寫入的 Pegging 應該是：
1.  `PO-999` (供給方) -> `FO-001` (需求方)，分配數量：**30**
2.  `PO-999` (供給方) -> `FO-002` (需求方)，分配數量：**40**
3.  *(可選設計)* 剩下的 30 個數量，在系統中屬於「未分配的預計庫存 (Unpegged / To Stock)」。有些系統會將這 30 個 Pegging 到一個虛擬的「安全庫存」或留空，代表它是為了滿足批量規則而多做出來的存貨，將來可以被下一次的 MRP 扣抵。

**對 `MrpCalculationEngine` 程式碼的影響評估：**
您現有的 `calculateMrp` 迴圈中，原本可能是「算完需求 -> 產生供給 -> 建立 Pegging」。
引入 Lot-Sizing 後，順序會變成：
1. 收集該 Time Bucket 內的所有毛需求（List of Demands）。
2. 計算總淨需求。
3. **套用 Lot-Sizing 策略**，決定最終的「計畫接收量 (Planned Receipt Qty)」。
4. **執行 Pegging 分配 (Allocation Loop)**：用一個迴圈，將算出來的「計畫接收量」，依序去扣抵（Peg）步驟 1 收集到的各個毛需求，直到毛需求被滿足為止。並將這些分配記錄寫入 `OrderPegging`。

**總結：**
您的系統底子非常好，已經有了 Pegging 的基礎。接下來實作 Lot-Sizing 時，重點在於將 `OrderPegging` 的數量欄位（`allocated_quantity`）做精細的分配計算，確保「多對一」或「供給大於需求」時，溯源數量依然能精準對齊。

1. LFL ("Lot-for-Lot")
意思：依據實際需求量，需要多少就訂購多少。

中文 (繁/簡)：批對批 (LFL) 或 逐批訂購 (LFL) (推薦使用 批對批 (LFL)，在 UI 上最簡短且為業界標準)
越南文：Đặt theo lô (LFL) 或 Lô theo lô (LFL) (推薦使用 Đặt theo lô (LFL)，意為按批次/需求訂購)
2. FOQ ("Fixed Order Quantity")
意思：每次訂購都維持一個固定的數量。

中文 (繁/簡)：固定訂量 (FOQ) 或 固定批量 (FOQ) (推薦使用 固定訂量 (FOQ))
越南文：Lượng cố định (FOQ) (意為固定數量，簡潔明瞭)
3. POQ ("Periodic Order Quantity")
意思：將某段固定期間內的需求加總後一次訂購。

中文 (繁/簡)：定期訂量 (POQ) 或 定期批量 (POQ) (推薦使用 定期訂量 (POQ))
越南文：Lượng định kỳ (POQ) 或 Đặt định kỳ (POQ) (推薦使用 Lượng định kỳ (POQ)，意為定期數量)


太棒了！您已經將 `MrpParameter` 的基礎建設（包含 `factoryId`、`leadTimeDays`、`safetyStockQuantity` 以及 `getEffectiveParameter`）都準備就緒。

這意味著您的 MRP 引擎即將從「單一維度的簡單計算」升級為「支援多廠區、具備安全水位與前置時間推算的企業級 MRP」。

基於您目前的進度，針對 `MrpCalculationEngine.calculateMrp` 的核心邏輯，以下為您梳理出 **5 個主要的待調整步驟與說明**：

### 1. 維度升級：以「廠別 (factoryId) + 物料 (materialId)」為計算基礎
*   **現狀評估**：原本的 MRP 可能只按 `materialId` 和 `dueDate`（需求日）進行分組計算。
*   **待調整說明**：
    *   MRP 的計算迴圈必須加上 `factoryId` 的維度。也就是說，**A 廠的需求只能用 A 廠的庫存與參數來滿足**。
    *   在收集毛需求（Gross Requirements）時，必須按 `Map<String, Map<Long, List<Demand>>>`（即 `FactoryId -> MaterialId -> Demands`）進行分組。
    *   獲取「現有庫存 (On-hand Inventory)」時，也必須傳入 `factoryId`，只抓取該廠區的庫存量。

### 2. 動態獲取 MRP 參數 (Fetch Effective Parameter)
*   **現狀評估**：您已完成 `getEffectiveParameter`。
*   **待調整說明**：
    *   在進入每個「廠別 + 物料」的計算迴圈初期，呼叫 `mrpParameterService.getEffectiveParameter(materialId, factoryId)`。
    *   如果回傳為空（代表該廠該物料未設定 MRP 參數），系統需要有預設行為（例如：拋出異常警告，或採用系統全域預設值 LFL、LeadTime=0、SafetyStock=0）。

### 3. 淨需求計算：納入「安全庫存 (Safety Stock)」水位
*   **現狀評估**：原本的淨需求公式可能是 `淨需求 = 毛需求 - 預計可用庫存`。
*   **待調整說明**：
    *   安全庫存是一道「不可觸碰的底線」。新的淨需求觸發條件為：
        `預計可用庫存 (Projected Available) = 期初庫存 + 預計入庫 - 毛需求`
        **`如果 (預計可用庫存 < safetyStockQuantity)`**，則觸發淨需求。
    *   **`淨需求量 = safetyStockQuantity - 預計可用庫存`**。
    *   *舉例*：毛需求 50，庫存 60，安全庫存 20。算下來預計庫存剩 10，低於安全庫存 20。因此產生淨需求 10（為了補足安全庫存）。

### 4. 批量計算：套用 Lot-Sizing 策略
*   **現狀評估**：您已經有了 `LotSizingStrategy`。
*   **待調整說明**：
    *   將步驟 3 算出的「淨需求量」以及步驟 2 取得的 `MrpParameter`，傳入對應的 `LotSizingStrategy`。
    *   計算出**「計畫接收量 (Planned Receipt Quantity)」**。這個數量通常會大於或等於淨需求量（因為有最小批量或包裝倍數的限制）。
    *   計算完後，記得將這個「計畫接收量」加回「預計可用庫存」中，供下一個時間段（Time Bucket）扣抵。

### 5. 時程推算 (Lead Time Offsetting) 與結果綁定
*   **現狀評估**：原本產生的 `MrpResult` 可能直接使用需求日作為開工日，且可能未綁定廠別。
*   **待調整說明**：
    *   **推算開工日 (Release Date)**：使用步驟 4 算出的「計畫接收量」，其需求日（Requirement Date）減去 `leadTimeDays`，得出**「計畫發放日 / 開工日 (Planned Release Date)」**。
        *   *注意*：實務上這裡通常會結合「工廠行事曆 (Factory Calendar)」，跳過假日。若目前無行事曆，可先用單純的日期相減。
    *   **綁定廠別**：在生成 `MrpResult` 時，必須將當前迴圈的 `factoryId` 寫入 `MrpResult` 中。這樣後續 `convertToPlannedOrders` 時，生成的 `PlannedOrder` 才會正確歸屬到該廠區。

---

**架構小結：**
經過這 5 步調整，您的 `MrpCalculationEngine` 迴圈邏輯大致會變成：
`For 每個 Factory` -> `For 每個 Material (依低階碼)` -> `取得 MrpParameter` -> `For 每個時間段 (Time Bucket)` -> `算毛需求` -> `扣庫存看是否低於安全庫存` -> `產生淨需求` -> `套用批量規則放大數量` -> `往前推算 Lead Time 決定開工日` -> `產出帶有 factoryId 的 MrpResult`。
https://chatgpt.com/share/695f7565-3fcc-800e-82c6-0411fd496451
https://gemini.google.com/share/7ce4efe84807


這是一個非常標準且嚴謹的 **MRP II (Manufacturing Resource Planning)** 流程。這個流程在「計算（MRP）」與「執行（Production Order）」之間，加入了一個**「建議/計畫（Planned Order）」**的緩衝層。

這個設計非常適合需要**人工介入審核**、或者**物料供應不穩定**的生產企業，因為它允許生管在正式下單前進行調整。

以下為您設計符合此流程的架構與 Table 定義：

---

### 一、 完整業務流程圖

流程路徑：
**`SO (銷售)`  `FO (工廠匯總)`  `MRP (運算)`  `PLO (計畫訂單)`  `MO (正式工單)**`

1. **Sales Order (SO)**: 業務接單。
2. **Factory Order (FO)**: 生管將 SO 匯總，鎖定生產排程（這是 MRP 的需求來源）。
3. **MRP Calculation**: 系統運算供需平衡。
4. **Planned Order (PLO)**: **(新增關鍵層級)** 系統給出的「建議」。這只是一個計畫，尚未正式生效，隨時可能被下一次 MRP 運算覆蓋。
5. **Production Order (MO)**: 生管確認 PLO 無誤後，「投放（Firming）」成為正式工單，此時才產生領料單與派工。

---

### 二、 核心資料表 (Table) 設計

在此架構下，我們需要重點設計中間的 `Factory Order` 與 `Planned Order`。

#### 1. 需求來源層：Factory Order (FO)

*又稱 Master Production Schedule (MPS) 或 內部製令*
這是 MRP 運算時的**獨立需求 (Independent Demand)** 來源。

* **`FO_Header` (工廠訂單主表)**
* `FO_ID`: 工廠單號
* `Status`: Draft (草稿) / **Released (已發行 - MRP 會抓這狀態)** / Closed (結案)
* `PlannerID`: 負責生管


* **`FO_Detail` (工廠訂單明細)**
* `FO_ID`: 關聯主表
* `ItemCode`: 成品料號
* `Qty_Target`: 目標生產數量 (由多張 SO 匯總而來)
* `DueDate`: 預計完工日


* **`Rel_SO_FO` (銷售與工廠單關聯表)**
* 用於追溯這張 FO 是為了滿足哪些 SO (如前次回答所述)。



#### 2. 運算結果層：Planned Order (PLO)

*這是您本次需求的核心。*
MRP 跑完後，**不會直接產生 MO**，而是將結果存在這張表。這是一個「沙盒（Sandbox）」區域。

* **`Planned_Order` (計畫訂單表)**
* `PLO_ID`: 系統自動產生的計畫單號 (例如: PLN-20231001-005)
* `ItemCode`: 料號 (包含成品、半成品、原物料)
* `OrderType`: **Make (建議自製)** 或 **Buy (建議採購)**
* `Source_FO_ID`: 來源的工廠訂單 (追溯用)
* `Qty_Suggested`: 系統建議數量
* `Date_Start`: 建議開工/採購日
* `Date_End`: 建議完工/到貨日
* `Status`:
* **System (系統建議)**: 下次 MRP 重跑時，若需求改變，這筆資料會被刪除或修改。
* **Firmed (已鎖定)**: 生管手動確認過，下次 MRP 跑不會動它，但還沒轉正式單。


* `Action_Msg`: 系統提示 (例如: "缺料", "需提前")



#### 3. 執行層：Production Order (MO) / Purchase Order (PO)

當生管將 `Planned_Order` 轉單後，資料才會進入這裡。

* **`MO_Header` (正式工單)**
* `MO_ID`: 正式工單號
* `Source_PLO_ID`: 來源的計畫單號 (用於防止重複轉單)
* ... (其他標準工單欄位)



---

### 三、 詳細數據流轉邏輯 (Step-by-Step Logic)

這個流程的精髓在於 **「確認 (Firming)」** 這個動作。

#### 步驟 1：匯總 (Aggregation) -> 產生 FO

生管將多張 `SO` 匯總成一張 `FO`。

* `FO_Detail` 記錄：產品 A，數量 100，交期 10/30。
* 此時，系統中還沒有任何工單。

#### 步驟 2：MRP 運算 (The Calculation)

系統執行 MRP：

1. 讀取 `FO_Detail` (需求 100)。
2. 扣除 `Inv_Master` (庫存) 與 `MO_Header` (已發行的在途工單)。
3. 展開 BOM。
4. **寫入 `Planned_Order` 表**：
* 系統發現缺 80 個成品 A  Insert `Planned_Order` (Type=Make, Qty=80, Item=A)。
* 系統發現原料 B 不夠  Insert `Planned_Order` (Type=Buy, Qty=200, Item=B)。



> **注意**：此時若使用者覺得不對，可以隨時重跑 MRP，這些 `System` 狀態的 Planned Order 會被清空重算。這提供了極大的容錯空間。

#### 步驟 3：生管審核與調整 (Review & Adjustment)

生管人員進入「MRP 結果作業」畫面，看到系統建議「生產 80 個 A」。

* 生管判斷：「產線最小批量是 100，做 80 個不划算。」
* 生管**直接修改** `Planned_Order`，將 Qty 改為 100，並將 Status 改為 **`Firmed` (鎖定)**。
* *此時這張單據受到保護，下次跑 MRP 系統會把它視為已知供給，不會刪除它。*

#### 步驟 4：投放/轉單 (Conversion)

生管確定計畫無誤，點擊「轉正式單 (Release Order)」。

1. 系統讀取 `Planned_Order` (Type=Make)。
2. Insert `MO_Header` (正式工單)。
3. Update `Planned_Order` 狀態為 `Converted` (已轉換)。
4. 如果是 Type=Buy 的計畫單，則 Insert `PO_Header` (正式採購單)。

#### 步驟 5：生產執行

工廠拿著 `MO` 進行領料、生產、入庫。

---

### 四、 為什麼要多「Planned Order」這一步？

對於小型企業，這看起來好像多了一道手續，但其實好處很大：

1. **避免「垃圾進，垃圾出」**：
如果 SO 或庫存數據有錯，MRP 算出來的結果會很荒謬。如果直接生成正式工單 (MO)，現場可能就照著錯誤的指令領料生產了。有了 Planned Order，生管有一道**防火牆**可以檢查。
2. **模擬與試算**：
生管可以在 Planned Order 層級進行「模擬」。例如：如果我把這張單延後三天，會不會缺料？這在正式 MO 層級很難做，因為 MO 通常牽涉到領料鎖定。
3. **批量調整 (Lot Sizing)**：
MRP 算出來是「缺 3 個」，但採購或生產一定要「湊整數 10 個」。在 Planned Order 階段調整數量，比去改正式單據容易且乾淨。

### 五、 Table 欄位設計建議 (SQL Snippet)

**Planned_Order (計畫訂單)** 是這個流程的靈魂，建議結構如下：

```sql
CREATE TABLE Planned_Order (
    PLO_ID INT IDENTITY PRIMARY KEY, -- 內部流水號
    
    -- 來源與類型
    Reference_No VARCHAR(30),        -- 參考號 (通常填寫來源的 FO 單號)
    ItemCode VARCHAR(20) NOT NULL,
    OrderType VARCHAR(10),           -- 'MAKE' (自製), 'BUY' (採購), 'TRANSFER' (調撥)
    
    -- 數量與時間
    Qty_Required DECIMAL(18,2),      -- 原始需求量 (MRP算出來的)
    Qty_Planned DECIMAL(18,2),       -- 實際計畫量 (生管調整後的)
    Date_Release DATE,               -- 預計下單日
    Date_Due DATE,                   -- 預計完成日
    
    -- 狀態控制
    Status VARCHAR(10),              -- 'SYSTEM' (系統生成), 'FIRM' (已鎖定), 'CLOSED' (已轉單)
    Target_Doc_ID VARCHAR(30),       -- 轉單後的正式單號 (MO單號 或 PO單號)
    
    -- 系統資訊
    Run_ID VARCHAR(20),              -- 這是哪一次 MRP 運算產生的
    CreatedTime DATETIME DEFAULT GETDATE()
);

```

這樣的設計就能完美滿足您要求的 **SO -> FO -> MRP -> Planner Order (PLO) -> Production Order** 的嚴謹流程。
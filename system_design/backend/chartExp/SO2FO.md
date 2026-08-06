在 ERP 的生產計畫流程中，「銷售訂單 (SO) 轉 投產單 (FO)」是將**「客戶需求」**轉化為**「內部生產指令」**的核心步驟。

以下是針對「SO 轉 FO」業務邏輯的詳細說明，分為四個維度：

### 1. 業務目標 (Business Goal)
*   **需求匯總**：將不同客戶、不同訂單但「相同產品」且「交期相近」的需求進行合併，以利於生產車間進行大批量生產，降低換線成本。
*   **需求鎖定**：將已確認的銷售需求正式轉入生產排程，防止重複轉單或遺漏需求。
*   **追溯性 (Traceability)**：建立從生產指令 (FO) 回溯至原始客戶訂單 (SO) 的關聯，以便回答「這批貨是為了哪張訂單生產的？」

### 2. 轉換前置條件 (Prerequisites)
*   **SO 狀態**：銷售訂單必須處於 `Confirmed` (已確認) 狀態。
*   **物料屬性**：銷售訂單明細中的物料必須是「自製件」或「委外件」（即具備 BOM 的產品）。
*   **未分配檢查**：該銷售訂單明細 (SO Item) 尚未被分配到其他的投產單，或者分配數量尚未滿額（避免超量生產）。

### 3. 核心邏輯流程 (Core Process)

#### A. 篩選與選擇 (Selection)
1.  用戶在 UI 界面篩選「待投產」的銷售訂單明細。
2.  系統列出所有 `Confirmed` 且 `Allocated Quantity < Ordered Quantity` 的 SO Items。

#### B. 匯總策略 (Aggregation Strategy)
系統通常提供兩種模式：
*   **明細對應 (1-to-1)**：一張 SO 直接生成一張 FO（適用於客製化程度高的產品）。
*   **按物料匯總 (Group by Material)**：
    *   將相同 `ProductMaterialId` 的明細合併。
    *   **預計完工日 (Due Date)** 計算：取所有來源 SO 明細中最晚的 `ExpectedDeliveryDate` 或是用戶手動指定。
    *   **總數量**：所有來源 SO 明細的 `quantity` 加總。

#### C. 建立單據 (Creation)
1.  **建立 Factory Order (表頭)**：
    *   生成新的 `OrderNo` (例如 FO20240108001)。
    *   設定 `ProductMaterialId`、`Total Quantity`、`Due Date`。
    *   狀態設為 `Draft` 或 `Confirmed`。
2.  **建立 Factory Order Items (表身/關聯層)**：
    *   為每一筆來源 SO 明細建立一筆 `FactoryOrderItem`。
    *   記錄 `sales_order_item_id` 與分配數量 `allocated_quantity`。

#### D. 回寫與鎖定 (Update Source)
*   （可選但建議）在 `sales_order_items` 表增加一個欄位 `allocated_to_fo_quantity`，記錄已轉投產的數量，用於防止重複轉單。

### 4. 數據結構變化 (Data Mapping)

| 來源：Sales Order Item | 映射方向 | 目標：Factory Order |
| :--- | :---: | :--- |
| `material_id` | -> | `product_material_id` (匯總 Key) |
| `quantity` (加總) | -> | `quantity` (FO 表頭) |
| `expected_delivery_date` | -> | `due_date` (FO 表頭) |
| `id` (SO Item ID) | -> | `sales_order_item_id` (FO Item 表身) |
| `quantity` (個別量) | -> | `allocated_quantity` (FO Item 表身) |

---

### 5. 後續影響 (Impact)
*   **MRP 觸發**：當 FO 狀態變更為 `Confirmed` 時，MRP 運算引擎會讀取此 FO 需求，進一步計算該產品所需的半成品與原材料需求。
*   **進度追蹤**：生產完成後，可透過 FO Item 回饋給銷售部門該筆訂單的完工狀況。

### 實作建議
我們可以在 `FactoryOrderService` 中增加一個名為 `convertFromSalesOrders` 的方法，接收一個包含多個 `SalesOrderItemId` 的 List，然後執行上述的匯總與創建邏輯。

================================================

[32 tools called]

我已經完成了「銷售訂單 (SO) 轉 投產單 (FO)」的核心業務邏輯開發。

### 本次執行的變更：

1.  **資料結構擴展 (SD 模組)**：
    *   在 `sales_order_items` 表與實體中增加了 **`allocated_quantity`** 欄位，用於精確追蹤每一行訂單明細已轉產的數量，防止超量轉單。
    *   在 `RemoteSalesOrderService` 增加了 `getSalesOrderItems` 與 `updateAllocatedQuantities` 介面，支援跨模組的需求讀取與數量回寫。

2.  **轉換邏輯實現 (PP 模組)**：
    *   **新增 DTO**：`FactoryOrderConvertRequest` 用於接收前端傳入的 SO Item ID 列表及自動確認選項。
    *   **服務層實作**：在 `FactoryOrderServiceImpl.convertFromSalesOrders` 中實現了以下核心邏輯：
        *   **智慧匯總**：自動將多筆 SO 明細按「物料 (Material)」進行分組。
        *   **自動計算**：
            *   **總數量**：自動加總各訂單明細的剩餘未轉產數量。
            *   **交期策略**：自動取所有關聯訂單中最晚的期望交期作為投產單的 `dueDate`。
        *   **關聯建立**：生成 FO 表頭的同時，為每一筆來源 SO 建立對應的 `FactoryOrderItem` 關聯紀錄。
        *   **狀態控制**：支援 `autoConfirm` 參數，可直接生成 `Confirmed` 狀態的投產單以觸發 MRP。

3.  **API 端點**：
    *   在 `FactoryOrderController` 新增了 `POST /api/v1/pp/factory-orders/convert-from-so` 接口。

### 核心代碼邏輯 (FactoryOrderServiceImpl)：
```java
// 按物料分組並建立投產單
for (Map.Entry<Long, List<RemoteSalesOrderItemDTO>> entry : groupedByMaterial.entrySet()) {
    // 1. 計算匯總數據（總量、最晚交期）
    // 2. 建立 FactoryOrder (Header)
    // 3. 循環建立 FactoryOrderItem (Detail) 並記錄來源 SO
    // 4. 調用遠端服務回寫 SO 明細的已分配數量
}
```

### 後續操作說明：
*   **觸發 MRP**：現在您可以通過此接口生成 `Confirmed` 狀態的投產單，隨後運行的 MRP 運算將自動讀取這些需求。
*   **追溯查詢**：您可以透過 `FactoryOrderItem` 輕鬆查出任何一張投產單是由哪些客戶訂單匯總而來的。


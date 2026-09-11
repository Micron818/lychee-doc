在規範的 ERP 系統（例如 SAP、Oracle、Microsoft Dynamics）中，**是非常允許且必須支持**用戶手動添加、修改或刪除工單組件（Production Order Components）的，即使這些組件不在標準的 BOM（BomItem）設定之內。

### 為什麼標準 ERP 需支持此功能？（實際業務場景）

1. **替代料（Material Substitution）：** 當 BOM 中指定的標準材料缺貨時，生管或現場人員會手動在工單中添加替代材料，以確保生產不中斷。
2. **額外消耗（Extra Consumption / Scrap）：** 在生產過程中，可能會因為品質不良、機台調試（Trial run）等原因，需要消耗 BOM 中未定義的額外輔料，或者消耗大於 BOM 預定比例的材料。
3. **客製化需求（One-off/Custom Requirements）：** 某些特定的客戶訂單可能會有特殊的包裝或微小的設計變更，此時不需要為此專門去修改或新建一個主檔 BOM，而是直接在生成的「該張工單」上新增需要的材料即可。
4. **研發或打樣：** 試產工單往往沒有非常精確的 BOM，需要工程師在開立工單時手動調整投入的物料清單。

### 從你提供的程式碼結構來看（架構設計）

你的程式碼設計已經很好地反映了這個解耦（Decoupled）的標準邏輯：

觀察 `@lychee-erp-pp/src/main/java/com/lychee/erp/pp/model/ProductionOrderComponent.java` 的欄位：
```java
    @NotNull(message = "{validation.productionOrderComponent.productionOrderId.required}")
    @Column(name = "production_order_id", nullable = false)
    private Long productionOrderId;

    @NotNull(message = "{validation.productionOrderComponent.materialId.required}")
    @Column(name = "material_id", nullable = false)
    private Long materialId;
```

你**沒有**在 `ProductionOrderComponent` 裡面強制加上類似 `bom_item_id` 這樣的 Foreign Key 限制。這是一個非常正確的設計：
* `BomItem` 是**「標準範本」**（Master Data）。
* `ProductionOrderComponent` 是**「交易數據 / 實際執行數據」**（Transactional Data）。
* 當工單建立時（通常是根據 BOM 展開），系統會複製 BOM 裡面的項目到工單組件中。一旦複製過去，這些工單組件的生命週期就獨立了。用戶後續可以自由在該工單下新增其他 `material_id`，因為它只跟聯 `production_order_id` 和 `material_id`。

**總結來說：**
在規範的 ERP 系統設計中，BOM 只是一個「預設帶入的範本」。工單一旦生成，用戶絕對有權限（依據系統權限控管）在工單的發料清單中，手動增加不在 BOM 裡面的其他料件。目前的系統 Entity 設計也是完全支持這樣的彈性這種彈性操作的。
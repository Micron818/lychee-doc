# Lychee Backend Development Skill

本 Skill 以 `SalesOrder` 為範本，定義了 Lychee ERP 後端開發的核心模式與標準流程。在開發新的業務功能（如採購單、生產單等）時，應嚴格遵循此規範。

## 1. 核心開發模式 (Standard Patterns)

### 1.1 多租戶隔離 (Multi-tenancy)
所有數據操作必須包含租戶隔離，防止數據越權。
- **獲取租戶 ID:** 使用 `CurrentTenant.tenantId()`。
- **Repository 規範:** 方法必須包含 `tenantId` 參數，例如 `findByTenantIdAndId(Long tenantId, Long id)`。
- **Service 邏輯:** 在執行任何 CRUD 前，先獲取當前租戶 ID 並傳入 Repository。

### 1.2 主從架構處理 (Header-Item Architecture)
對於具有「單頭-單身」結構的功能，需遵循以下邏輯：
- **狀態同步:** 當單頭（Header）狀態變更（如確認/取消確認）時，必須同步更新所有單身（Item）的狀態。
- **預設值繼承:** 建立單身時，應自動從單頭繼承相關屬性（如 `expectedDeliveryDate`）。
- **金額加總:** 單身變動後，必須調用 `recalculateOrderTotals` 重新計算單頭的總金額、稅額等。
- **校驗:** 在更新或刪除單身前，必須檢查單頭狀態（通常僅 `DRAFT` 狀態可修改）。

### 1.3 數據填充 (Data Enrichment)
- **審核資訊:** 使用 `dictionaryCacheService.fillAuditNames(tenantId, list)` 填充 `createdBy` 和 `updatedBy` 的顯示名稱。
- **選項與用戶:** 使用 `dictionaryCacheService.getOptionValues` 和 `getUserNames` 獲取關聯的顯示文字。
- **冗餘設計:** 對於高頻訪問的名稱（如 `customerName`），應在 Entity 中存儲冗餘欄位，並在建立/更新時同步。

## 2. 代碼結構規範

### 2.1 Controller 層
- 統一使用 `ApiResponse.success()` 包裝回傳結果。
- 分頁查詢統一使用 `POST` 方法配合 `ProPageRequest`。
- 權限控制：使用 `@PreAuthorize("hasAuthority('...')")`。

### 2.2 Service 層
- 標註 `@Transactional` 確保事務一致性。
- 分頁查詢：
  ```java
  Specification<Entity> spec = DynamicSpecifications.build(Entity.class, request.getParams());
  Page<Entity> entityPage = repository.findAll(spec, pageable);
  ```
- 關聯抓取優化：使用 `DynamicSpecifications.fetch("relation1", "relation2")` 解決 N+1 問題。

### 2.3 Mapper 層 (MapStruct)
- 使用 `JsonNullableMapper` 處理部分更新（Partial Update）。
- 設置 `nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE`。

## 3. 業務校驗標準
- **重複性檢查:** 在建立前檢查唯一編號（如 `orderNo`）是否在同租戶下重複。
- **金額精度:** 計算金額時，統一使用 `BigDecimal` 並設置 `setScale(2, RoundingMode.HALF_UP)`。
- **誤差校驗:** 對於前端傳入的計算結果，應允許 0.05 以內的微小誤差。

## 4. 參考範本文件
- **Service:** `com.lychee.erp.sd.service.impl.SalesOrderServiceImpl`
- **Controller:** `com.lychee.erp.sd.controller.SalesOrderController`
- **Mapper:** `com.lychee.erp.sd.mapper.SalesOrderMapper`
- **Repository:** `com.lychee.erp.sd.repository.SalesOrderRepository`

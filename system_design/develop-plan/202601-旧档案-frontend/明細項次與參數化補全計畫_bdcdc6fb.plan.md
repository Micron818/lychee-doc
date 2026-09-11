---
name: 明細項次與參數化補全計畫
overview: 根據討論結論，為系統各單據明細加入項次(item_no)與溯源欄位，並將項次的起始值、步長、允許手動修改等規則參數化，整合至 sys_doc_rule 中。
todos:
  - id: db-schema-update
    content: 更新 sys_doc_rule 及相關單據明細表的 SQL schema 與 Liquibase changelog
    status: completed
  - id: entity-update
    content: 更新 JPA Entities (SysDocRule, ) 映射新增的欄位
    status: completed
  - id: allocator-refactor
    content: 重構 DocumentItemNoAllocator，支援 first, step 與插單分配邏輯
    status: completed
  - id: service-config-api
    content: 實作 DocumentNumberGeneratorService.getItemRule 與對應 Controller API
    status: completed
  - id: dto-update
    content: 更新各模組的 DTO，加入 itemNo 與其他溯源關聯欄位
    status: completed
  - id: service-integration
    content: 修改各單據 Service (SO, PO, PR, FO, BOM, GR)，套用新的 allocator 分配項次
    status: completed
isProject: false
---

# 明細項次與參數化補全計畫

本計畫旨在落實標準 ERP 對於單據明細項次 (Item Number) 的管理規範，包含新增必要的項次與溯源欄位、將項次生成規則參數化，以及重構自動編號分配器以支援插單與客製化步長。

## 1. 資料庫結構與實體 (Entity) 更新

更新 SQL schema 定義與建立 Liquibase changelog，並同步更新對應的 JPA Entities：

- **sys_doc_rule**: 新增 `item_first_no` (預設 10), `item_step` (預設 10), `is_item_manual_edit` (預設 true) 欄位。

## 2. 核心分配器與服務層重構

- **DocumentItemNoAllocator**: 修改 `[lychee-erp-common/.../DocumentItemNoAllocator.java](lychee-erp-common/src/main/java/com/lychee/erp/common/util/DocumentItemNoAllocator.java)`，讓 `Sequence` 支援傳入 `first` 與 `step`，並實作 `allocate(Integer requestedNo)` 方法以支援無條件進位及前端手動插單。
- **DocumentItemRuleDTO**: 建立 DTO 用於傳遞項次設定 (`firstNo`, `step`, `manualEditAllowed`)。
- **DocumentNumberGeneratorService**: 於 `[DocumentNumberGeneratorService.java](lychee-erp-common/src/main/java/com/lychee/erp/common/service/DocumentNumberGeneratorService.java)` 新增 `getItemRule(String docType)`，並在實作類別中從 `sys_doc_rule` 讀取資料，套用 Spring Cache (`@Cacheable`)。
- **SysDocRuleController**: 在basis模組建立或擴充 Controller API (如 `GET /api/v1/basis/doc-rules/{docType}/item-config`)，提供前端讀取單據項次規則。

## 3. DTO 與業務 Service 整合

- **Request DTOs**: 在對應的 Item Request DTO 中加入 `itemNo` 欄位 (允許 Null)，以接收前端傳入的自訂項次。
- **業務 Service**: 檢查需要處理項次的實作(例如`SalesOrderServiceImpl`, `PurchaseOrderServiceImpl`, `BillOfMaterialServiceImpl` 等等)，在建立明細時：
  1. 呼叫 `documentNumberGeneratorService.getItemRule(docType)` 取得設定。
  2. 從資料庫取得目前該單據的 `MAX(item_no)`。
  3. 初始化 `DocumentItemNoAllocator.Sequence`。
  4. 迴圈中使用 `sequence.allocate(dto.getItemNo())` 分配項次，並設入 Entity 中。

## 4. 資料庫變更腳本

建立一份新的 Liquibase changelog SQL 檔案，包含上述所有 `ALTER TABLE` 語法，確保環境升級時資料庫結構能順利遷移。
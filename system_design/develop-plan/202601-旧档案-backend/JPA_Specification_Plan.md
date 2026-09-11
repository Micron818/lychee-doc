### 執行計劃（JPA Specification 封裝）

- **目標**: 將 `PageRequestDTO.params`（如 `createdAt_lte=2025-10-01, name_like=%test%, createdAt_gte=2025-09-03`）自動解析並轉為通用的 JPA `Specification<T>`，支援動態欄位、型別轉換、關聯欄位與多運算子。

1) 定義運算子規範與對應
- **支援運算子**: `eq, ne, lt, lte, gt, gte, like, in, between, isnull, isnotnull, startswith, endswith`
- **對應 CriteriaBuilder**:
  - eq/ne → `cb.equal`/`cb.notEqual`
  - lt/lte/gt/gte → `cb.lessThan(Comparable)`/`cb.lessThanOrEqualTo`/...
  - like/startswith/endswith → 使用 `cb.like(cb.lower(path), pattern)`
  - in → `path.in(values)`
  - between → `cb.between(Comparable, start, end)`
  - isnull/isnotnull → `cb.isNull`/`cb.isNotNull`
- **大小寫**: `like` 走不區分大小寫（`lower()`）；若值未含 `%`，自動包裝 `%value%`。

2) 參數解析與驗證
- **鍵名解析**: `fieldPath_operator` → `fieldPath`（支援巢狀如 `user.company.name`）、`operator`
- **預設運算子**: 若無 `_operator`，預設 `eq`
- **值解析**:
  - `in` 支援逗號分隔（如 `status_in=ACTIVE,INACTIVE`）
  - `isnull/isnotnull` 不需值或忽略值
- **欄位白名單/驗證**: 以實體 `Class<T>` 反射或 JPA Metamodel 驗證欄位存在，非法欄位或運算子拋出 `ValidationException`

3) 目標型別推斷與轉換
- **型別來源**: 透過反射沿 `fieldPath` 取得終端欄位型別；若遇關聯，記錄 join 路徑
- **型別支援**: `String, Integer/Long/BigDecimal, Boolean, Enum, LocalDate, LocalDateTime, UUID`
- **日期時間處理**:
  - `yyyy-MM-dd` 解析為 `LocalDate`
  - `yyyy-MM-ddTHH:mm[:ss]` 解析為 `LocalDateTime`
  - 對 `*_gte/*_lte` 成對出現時合併為 `between`
  - 只有 `gte` 或 `lte` 時各自為單邊條件
  - 可選策略：日期上限標準化到日末（如 `2025-10-01` → `2025-10-01T23:59:59.999999999`）

4) 規範建構器
- **核心**: `Specification<T> build(Class<T> entityClass, Map<String, String> params)`
- **Join 支援**: 巢狀欄位自動以 `LEFT JOIN` 逐段建立 path
- **組合邏輯**:
  - 預設全部條件以 AND 相連
  - 預留 OR 語法（可選，例如鍵前綴 `or__name_like` 進入 OR group）
- **合併範圍**: 自動將同欄位 `gte/lte` 聚合為一個 `between` predicate

5) 分頁與排序整合
- **Pageable**: 由 `PageRequestDTO.current/pageSize` 構造 `PageRequest`
- **排序（可選）**: 擴充 `PageRequestDTO` 接收如 `sort=name,asc;createdAt,desc`，轉為 `Sort`

6) Service 層接口
- **泛型工具類**: `DynamicSpecifications.build(entityClass, params)` 回傳 `Specification<T>`
- **使用範例**: `repository.findAll(Specification, Pageable)` 並回傳 `Page<T>`
- **錯誤處理**: 捕捉轉換/驗證異常，統一拋 `ValidationException`（已有類）

7) 測試用例
- **正向**: 
  - `createdAt_gte + createdAt_lte` → between
  - `name_like=%test%` → `lower(name) like %test%`
  - `status_in=ACTIVE,INACTIVE`（Enum）
  - 巢狀欄位 `user.company.name_like`
- **負向**:
  - 不存在欄位/非法運算子
  - 型別不匹配（如對字串用 `gt`）
  - 空值/空白清理策略

8) 文件與約定
- **鍵名約定**: `fieldPath_operator`
- **型別/格式**: 日期/時間格式、`in` 的分隔規則
- **大小寫與萬用字元**: 預設自動 `%value%`，已含 `%` 則尊重

9) 效能與安全
- **索引建議**: 常用查詢欄位建立索引
- **JOIN 效能**: 避免不必要的 `fetch join`；必要時加 `distinct(true)`
- **欄位白名單**: 防止透過 params 探測或注入欄位名

——

針對示例 `PageRequestDTO` 的處理效果
- `createdAt_gte=2025-09-03` 與 `createdAt_lte=2025-10-01` → 合併為 `createdAt between [2025-09-03T00:00:00, 2025-10-01T23:59:59.999...]`（依採用的上限策略）
- `name_like=%test%` → `lower(name) like %test%`

如需，我可以下一步直接補上 `Operator` 列舉、`SearchFilter` 資料結構與 `DynamicSpecifications.build(...)` 的骨架程式碼，並接到既有的 `PageRequestDTO` 與 `ValidationException`。
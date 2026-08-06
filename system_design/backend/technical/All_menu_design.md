以下內容將你提供的 **端到端流程（SO → FO → MRP → PLO → MO / PO / SUB → 入庫）**，映射到 **模組化 ERP Menu 設計**。

本文件假設：

* 模組僅為「職責分區」，可依企業實際啟用 / 停用
* 流程是橫向的，Menu 是縱向的
* 每一張單據 **只屬於一個模組**

---

## 一、整體模組劃分（可擴充）

```text
BASIS  基本資料 / 系統設定
CRM    客戶與需求管理
SD     銷售與訂單
PP     生產計畫與控制
MM     採購與物料
SCM    供應鏈協同 / 預測
WM     倉儲與庫存
REPORT 跨模組查詢與追蹤
```

---

## 二、BASIS｜基本資料模組

> 所有交易單據的「地基」，不直接參與流程

```text
BASIS
 ├─ 組織架構
 │   ├─ 公司 / 法人
 │   ├─ 工廠
 │   └─ 倉庫 / 庫位
 ├─ 物料主檔
 │   ├─ 物料基本資料
 │   ├─ 物料圖檔 / 附件
 │   └─ 單位 / 屬性
 ├─ BOM 管理
 ├─ 製程 / 工序 / 工作中心
 ├─ 客戶主檔
 ├─ 供應商主檔
 └─ 系統參數
     ├─ MRP 策略
     ├─ 計畫參數
     └─ 單據狀態定義
```

---

## 三、CRM｜客戶與需求管理（需求前端）

> 關注「市場與客戶」，不負責生產與採購

```text
CRM
 ├─ 潛在客戶 / 商機
 ├─ 報價單
 ├─ 客戶需求預測（Forecast）
 ├─ 客戶需求彙總
 └─ 客戶需求追蹤
```

🔎 說明：

* CRM 可產生 **預測需求**，但不直接進 MRP
* 預測結果可送往 SCM / PP 作為參考

---

## 四、SD｜銷售與訂單模組

> 「正式需求」成立的地方

```text
SD
 ├─ 客戶訂單（SO）
 ├─ 訂單審核 / 確認
 ├─ 訂單變更管理
 └─ 銷售訂單追蹤
```

流程定位：

```
SO（需求成立）
```

---

## 五、PP｜生產計畫與控制（流程核心）

```text
PP
 ├─ 廠訂單（FO）
 ├─ MRP 需求運算
 ├─ 生產計畫單（PLO）
 ├─ 生產指令（MO）
 ├─ 生產執行 / 報工
 └─ 委外加工單（SUB）
```

流程覆蓋：

```
FO → MRP → PLO → MO / SUB → 生產執行
```

設計原則：

* FO 是「生產視角訂單」，歸 PP
* SUB 是生產策略，不歸 MM

---

## 六、MM｜採購與物料管理

```text
MM
 ├─ 採購需求（PR）
 ├─ 採購單（PO）
 ├─ 採購交期追蹤
 └─ 委外採購（來自 SUB）
```

流程覆蓋：

```
MRP → PR → PO
```

---

## 七、SCM｜供應鏈管理（協同與預測）

> 橫跨 CRM / PP / MM，但不取代任何一個模組

```text
SCM
 ├─ 需求預測整合（CRM + 歷史）
 ├─ 產能 / 供應平衡分析
 ├─ 供應商交期回饋
 ├─ 中長期供應計畫
 └─ 模擬與情境分析
```

🔎 說明：

* SCM 偏「計畫層 / 分析層」
* 不直接產生 MO / PO

---

## 八、WM｜倉儲與庫存

```text
WM
 ├─ 原料收貨 / 入庫
 ├─ 生產發料
 ├─ 成品入庫
 ├─ 委外回庫
 ├─ 庫存查詢
 └─ 庫存異動紀錄
```

流程覆蓋：

```
PO → 收貨 → 庫存
MO / SUB → 成品入庫
```

---

## 九、REPORT｜跨模組追蹤（強烈建議）

> 解決「資料分散在多模組」的 UX 問題

```text
REPORT
 ├─ 訂單全流程追蹤
 │   SO → FO → PLO → MO / PO / SUB → 入庫
 ├─ MRP 運算歷史
 ├─ 生產達成率
 ├─ 採購交期達成率
 └─ 庫存分析
```

---

## 十、總結：設計紅線

✅ 模組是責任，不是流程
✅ 一張單據只屬於一個模組
✅ 跨模組需求用「追蹤 / 報表」解決
❌ 不要複製 Menu 到多個模組

---

## 十一、客戶主檔（BASIS）與 CRM 擴充資料結構設計

> 目標：
>
> * 客戶「身份定義」穩定、可跨模組共用
> * CRM 可自由擴充，不影響交易與歷史資料

---

### 1️⃣ Customer Master（BASIS）— 核心主數據

```text
customer_master
-----------------------------
id (PK)
customer_code (UK)
legal_name
short_name
customer_type
vat_no
country
address
phone
email
status
created_at
updated_at
```

**設計說明**

* `customer_code`：跨系統唯一識別（SO / AR / Report 使用）
* 不含任何業務行為欄位
* 資料變動需嚴格控管（主數據流程）

---

### 2️⃣ Customer Contact（BASIS / CRM 共用）

```text
customer_contact
-----------------------------
id (PK)
customer_id (FK → customer_master.id)
name
role
title
phone
email
is_primary
```

**說明**

* 聯絡人屬於「客戶本身」而非交易
* 可由 CRM 維護，但關聯 BASIS 主檔

---

### 3️⃣ CRM Customer Extension（CRM 專屬）

```text
crm_customer_profile
-----------------------------
customer_id (PK, FK → customer_master.id)
customer_level
industry
sales_owner_id
default_payment_term
credit_rating
remark
```

**說明**

* 1:1 擴充表
* 可隨 CRM 成熟度增加欄位
* 不影響 SO / FO 歷史資料

---

### 4️⃣ CRM Interaction（互動 / 行為資料）

```text
crm_interaction
-----------------------------
id (PK)
customer_id (FK)
type (call / visit / email)
subject
content
interaction_date
owner_id
```

---

### 5️⃣ CRM Opportunity（商機）

```text
crm_opportunity
-----------------------------
id (PK)
customer_id (FK)
name
expected_amount
probability
stage
expected_close_date
```

---

### 6️⃣ 關聯關係圖（文字 ERD）

```text
customer_master
   1 ──── 1 crm_customer_profile
   1 ──── n customer_contact
   1 ──── n crm_interaction
   1 ──── n crm_opportunity
```

---

### 7️⃣ 為什麼這樣拆是「長期安全」的？

* 客戶名稱調整 ≠ CRM 資料異動
* CRM 可獨立升級或停用
* SO / 發票 / 報表只依賴 `customer_master`
* 不會發生「歷史訂單客戶被改壞」

---

### 8️⃣ 可直接複製給後端的設計原則

* 主鍵永遠用 `customer_id`
* CRM 表 **只參考、不擁有** 客戶
* 禁止 CRM 寫入 customer_code / legal_name

---

如需下一步，可在此文件繼續補：

* 供應商（Supplier / Vendor）同構資料結構（已補）
* 客戶 / 供應商共用 Party Model
* 多公司 / 多法人 Customer / Supplier 設計

---

## 十二、供應商 / Vendor 的同構資料結構設計

> 設計目標：
>
> * 與 Customer Master 結構一致（降低學習與維護成本）
> * BASIS 定義供應商身份
> * MM / SCM 僅擴充與使用，不擁有主數據

---

### 1️⃣ Supplier Master（BASIS）— 核心主數據

```text
supplier_master
-----------------------------
id (PK)
supplier_code (UK)
legal_name
short_name
supplier_type
vat_no
country
address
phone
email
status
created_at
updated_at
```

**設計說明**

* 結構刻意與 customer_master 對齊
* `supplier_code` 為跨模組唯一識別（PO / 收貨 / 成本）
* 不包含任何採購策略或績效欄位

---

### 2️⃣ Supplier Contact（共用概念）

```text
supplier_contact
-----------------------------
id (PK)
supplier_id (FK → supplier_master.id)
name
role
title
phone
email
is_primary
```

---

### 3️⃣ MM Supplier Extension（採購專屬 1:1）

```text
mm_supplier_profile
-----------------------------
supplier_id (PK, FK → supplier_master.id)
default_currency
default_incoterm
default_payment_term
lead_time_days
min_order_qty
purchase_block_flag
```

**說明**

* 採購與價格策略集中在 MM
* 不影響歷史 PO

---

### 4️⃣ SCM Supplier Extension（供應鏈 / 評估）

```text
scm_supplier_profile
-----------------------------
supplier_id (PK, FK → supplier_master.id)
capacity_level
on_time_delivery_rate
quality_rating
preferred_flag
risk_level
last_audit_date
```

---

### 5️⃣ SCM Interaction / Audit（行為資料）

```text
scm_supplier_interaction
-----------------------------
id (PK)
supplier_id (FK)
type (audit / meeting / issue)
subject
content
interaction_date
owner_id
```

---

### 6️⃣ 關聯關係圖（文字 ERD）

```text
supplier_master
   1 ──── 1 mm_supplier_profile
   1 ──── 1 scm_supplier_profile
   1 ──── n supplier_contact
   1 ──── n scm_supplier_interaction
```

---

### 7️⃣ 與 Customer 的同構對照表

| 概念   | Customer             | Supplier                  |
| ---- | -------------------- | ------------------------- |
| 主表   | customer_master      | supplier_master           |
| 代碼   | customer_code        | supplier_code             |
| 聯絡人  | customer_contact     | supplier_contact          |
| 業務擴充 | crm_customer_profile | mm / scm_supplier_profile |

---

### 8️⃣ 可直接給後端的設計紅線

* Supplier 與 Customer **不共用表，但共用結構**
* 主檔只放「身份定義」
* MM / SCM 表不得修改 supplier_code / legal_name
* 所有 PO / 收貨 **只引用 supplier_id**

---

### 9️⃣ 什麼時候該升級成 Party Model？

當出現以下任一情況：

* 同一家公司既是客戶也是供應商
* 需要統一信用 / 風險 / 法務資料
* 集團化、多法人共享往來對象

→ 才考慮 Party Model，否則目前設計最穩定

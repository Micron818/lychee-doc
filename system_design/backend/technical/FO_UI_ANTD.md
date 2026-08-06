# SO → FO 汇总规则在 Ant Design Pro 的组件实现建议

> 本文件目的：
> 将 **SO → FO 汇总规则 + UI 提示 / 禁用逻辑**，
> 明确落地为 **Ant Design Pro 可直接实现的组件与交互规范**，
> 作为前端实现与前后端协作的依据。

---

## 一、SO 选择页（SO → FO 汇总入口）

### 使用组件

* PageContainer
* ProTable<SO>
* rowSelection
* Tooltip / Tag / Icon

---

### 1️⃣ 不可汇总 SO → Checkbox 禁用

**交互目标**：
用户在选择 SO 时，立即知道「为什么不能选」。

**实现方式**

* 使用 rowSelection.getCheckboxProps
* 禁用整行选择
* Hover 显示原因

**示意规则字段（后端返回）**

* canMerge: boolean
* mergeBlockReason: string

**UI 表现**

* Checkbox disabled
* 行内 Tag：不可汇总
* Tooltip：具体原因（客户不同 / 工厂不同等）

---

### 2️⃣ 可选但有风险的 SO → Warning 提示

**场景**

* 交期差异过大
* 数量差异明显

**UI 表现**

* 黄色 Warning Icon
* Tooltip：风险说明

**设计原则**

* 可选 ≠ 合理
* 用视觉风险提示引导，而非禁止操作

---

## 二、FO Detail – Header 汇总提示

### 使用组件

* PageContainer
* Alert
* Descriptions

---

### 3️⃣ 多 SO 汇总提示 Banner

**触发条件**

* sourceSoCount > 1

**UI 表现**

* Info Alert
* 文案示例：本 FO 汇总自 4 笔 SO

---

### 4️⃣ 交期冲突提示

**触发条件**

* hasMultipleDueDates = true

**UI 表现**

* Warning Alert
* 文案：存在多组交期，请留意排产策略

---

## 三、FO Lines（需求明细）

### 使用组件

* ProTable<FoLine>
* expandable
* Typography.Text / Tooltip / Tag

---

### 5️⃣ 行合并结果的可视化

**规则**

* 同产品 + 同交期 → 合并
* 同产品 + 不同交期 → 拆行

**UI 表现**

* 数量下方灰字：已合并自 X 笔 SO
* 不同交期行显示 Tag：不同交期

---

### 6️⃣ 来源 SO 的简写 + 追溯

**表格列表现**

* 显示：SO-001, SO-002 +1
* Hover：显示完整 SO 清单

**展开行（expandable）内容**

* SO No
* SO Line No
* 原始数量
* 原始交期

---

## 四、Confirm / 执行 MRP 的防呆设计

### 使用组件

* Button
* Tooltip
* Modal.confirm
* message

---

### 7️⃣ Confirm 按钮禁用逻辑

**触发条件**

* canConfirm = false

**UI 表现**

* Confirm 按钮 disabled
* Tooltip 显示阻挡原因

---

### 8️⃣ 需人工确认的风险弹窗

**场景**

* 交期冲突需确认策略

**UI 表现**

* Modal.confirm
* 文案示例：是否确认以最早交期作为排产基准？

---

## 五、前后端职责边界（关键原则）

### 后端负责

* 所有业务规则判断
* 返回统一 Rule Result，例如：

  * canMerge
  * riskFlags
  * blockReason
  * canConfirm

### 前端负责

* 不实现业务规则
* 只做：

  * 禁用
  * 提示
  * 风险视觉化

---

## 六、可直接拆分的前端任务清单

* SO List：rowSelection 禁用 + Tooltip
* SO List：风险 Icon / Tag
* FO Header：多 SO / 交期 Banner
* FO Lines：合并说明 + expandable 追溯
* Confirm：disabled + confirm modal

---

> 本文件可直接作为：
>
> * UI 规格书
> * 前端实现指南
> * 与后端对齐的规则契约文档

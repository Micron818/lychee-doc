# FO / SO 汇总模块 API 清单

> 本文件目的：
>
> * 明确定义 FO / SO 汇总模块的 **后端 API 边界**
> * 作为前后端对接、Mock、Swagger 设计依据
> * 与既有 DTO（FO / FO Line / SO Line / RuleResult）完全一致

---

## 一、FO Detail 页面

### 1️⃣ 查询 FO 明细

**Endpoint**

```
GET /api/fo/{foId}
```

**Response**

```json
{
  "fo": {
    "id": "FO-001",
    "foNo": "FO-2026-0001",
    "status": "DRAFT",
    "customerId": "C001",
    "customerName": "ABC 客户",
    "plantId": "P01",
    "dueDate": "2026-02-15",
    "sourceSoCount": 3,
    "hasMultipleDueDates": true,
    "hasPartialTransfer": false,
    "confirmRule": {
      "allowed": false,
      "level": "BLOCK",
      "message": "存在未指定来源 SO 的需求行"
    },
    "mrpRule": {
      "allowed": false,
      "level": "BLOCK",
      "message": "FO 尚未确认"
    }
  },
  "lines": [
    {
      "id": "FO-L1",
      "lineNo": 1,
      "itemId": "FG-001",
      "itemCode": "FG-001",
      "itemName": "成品 A",
      "quantity": 300,
      "uom": "PCS",
      "dueDate": "2026-02-15",
      "sourceSoNos": ["SO-001", "SO-002"],
      "mergedFromSoCount": 2,
      "soDetails": [
        {
          "soNo": "SO-001",
          "soLineNo": 1,
          "qty": 100,
          "dueDate": "2026-02-15"
        },
        {
          "soNo": "SO-002",
          "soLineNo": 1,
          "qty": 200,
          "dueDate": "2026-02-15"
        }
      ],
      "lineRule": {
        "allowed": true,
        "level": "WARNING",
        "message": "合并自多笔 SO"
      }
    }
  ]
}
```

---

## 二、SO 汇入 FO（Drawer 使用）

### 2️⃣ 查询可汇入 SO Line

**Endpoint**

```
GET /api/fo/{foId}/selectable-so-lines
```

**Response**

```json
{
  "foId": "FO-001",
  "soLines": [
    {
      "id": "SO-L1",
      "soNo": "SO-001",
      "soLineNo": 1,
      "customerId": "C001",
      "customerName": "ABC 客户",
      "itemId": "FG-001",
      "itemCode": "FG-001",
      "itemName": "成品 A",
      "qty": 100,
      "uom": "PCS",
      "dueDate": "2026-02-15",
      "transferredQty": 0,
      "availableQty": 100,
      "mergeRule": {
        "allowed": true,
        "level": "NONE"
      }
    },
    {
      "id": "SO-L2",
      "soNo": "SO-003",
      "soLineNo": 1,
      "customerId": "C002",
      "customerName": "XYZ 客户",
      "itemId": "FG-002",
      "itemCode": "FG-002",
      "itemName": "成品 B",
      "qty": 50,
      "uom": "PCS",
      "dueDate": "2026-02-20",
      "transferredQty": 0,
      "availableQty": 50,
      "mergeRule": {
        "allowed": false,
        "level": "BLOCK",
        "message": "客户不同，不可汇总"
      }
    }
  ]
}
```

---

### 3️⃣ 汇入 SO Line 至 FO

**Endpoint**

```
POST /api/fo/{foId}/import-so-lines
```

**Request**

```json
{
  "soLineIds": ["SO-L1", "SO-L2"],
  "confirmRisk": true
}
```

**Response**

```json
{
  "success": true,
  "warnings": [
    "2 笔 SO 已合并为 1 笔 FO 需求（FG-001 / 2026-02-15）"
  ]
}
```

---

## 三、FO 状态操作

### 4️⃣ Confirm FO

**Endpoint**

```
POST /api/fo/{foId}/confirm
```

**Response（需人工确认）**

```json
{
  "allowed": false,
  "needConfirm": true,
  "message": "存在多组交期，是否以最早交期排产？"
}
```

**Response（确认成功）**

```json
{
  "success": true,
  "status": "CONFIRMED"
}
```

---

### 5️⃣ 执行 MRP

**Endpoint**

```
POST /api/fo/{foId}/run-mrp
```

**Response**

```json
{
  "success": true,
  "generated": {
    "ploCount": 2,
    "prCount": 5
  }
}
```

---

## 四、API 设计原则（强烈建议遵守）

1. **所有规则判断统一返回 RuleResult 结构**
2. **前端不写业务规则，只消费 API 结果**
3. **风险 ≠ 错误，风险要允许继续（需确认）**
4. **错误只用于真正不可执行的情况**

---

> 本 API 清单可直接用于：
>
> * Swagger / OpenAPI 定义
> * Mock Server
> * 前后端联调对照表

---

## 🔁 FO Line 调整 / 拆分 / 取消汇入 API（补充）

### 1️⃣ 取消 SO Line 汇入（从 FO 移除）

**DELETE** `/api/fo/{foId}/lines/{foLineId}`

**Response**

```json
{
  "success": true,
  "removedLineId": "FO-LINE-002",
  "affectedSoLineId": "SO-LINE-009",
  "foSummary": {
    "totalQty": 180,
    "lineCount": 2
  }
}
```

**UI 行为**

* 允许状态：`DRAFT`
* `CONFIRMED` 状态下禁用（提示：需取消确认）

---

### 2️⃣ 调整 FO Line 数量（部分汇入 / 修正）

**PATCH** `/api/fo/{foId}/lines/{foLineId}/quantity`

**Request**

```json
{
  "newQuantity": 80
}
```

**Response**

```json
{
  "success": true,
  "foLine": {
    "id": "FO-LINE-001",
    "quantity": 80
  },
  "ruleResult": {
    "warnings": ["SO 剩余 20 未汇入"],
    "errors": []
  }
}
```

**规则说明**

* 数量不可大于来源 SO Line 剩余数量
* 若小于 SO 数量 → SO Line 标记为 `PARTIAL_USED`

---

### 3️⃣ 拆分 FO Line（交期 / 工单拆分）

**POST** `/api/fo/{foId}/lines/{foLineId}/split`

**Request**

```json
{
  "splits": [
    { "quantity": 40, "requiredDate": "2026-02-15" },
    { "quantity": 40, "requiredDate": "2026-02-20" }
  ]
}
```

**Response**

```json
{
  "success": true,
  "newLines": [
    {
      "id": "FO-LINE-010",
      "quantity": 40,
      "requiredDate": "2026-02-15"
    },
    {
      "id": "FO-LINE-011",
      "quantity": 40,
      "requiredDate": "2026-02-20"
    }
  ],
  "removedLineId": "FO-LINE-001"
}
```

**UI 行为**

* 操作入口：FO Line 行内「拆分」
* 拆分后自动重新计算 MRP 标记

---

### 4️⃣ SO Line 使用状态查询（用于 UI 同步）

**GET** `/api/so-lines/usage-status`

**Query**

```
?soIds=SO-001,SO-002
```

**Response**

```json
[
  {
    "soLineId": "SO-LINE-009",
    "usedQty": 80,
    "remainingQty": 20,
    "status": "PARTIAL_USED"
  }
]
```

---

## 📌 状态与权限总结

| 操作   | DRAFT | CONFIRMED |
| ---- | ----- | --------- |
| 取消汇入 | ✅     | ❌         |
| 调整数量 | ✅     | ❌         |
| 拆分行  | ✅     | ❌         |

> CONFIRMED 状态需先执行「取消确认」才能修改

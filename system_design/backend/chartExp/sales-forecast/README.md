# 预告订单（SALES_FORECAST）

本目录描述 **客户预告订单**：客户给出的可滚动、可被正式单消耗的计划需求。  
**不是**统计预测，**不是**第二套销售订单，**不能**交货、**不能**开票。

中文、表名、单据类型统一为 **预告订单 / `SALES_FORECAST`**。单号前缀 `SFO`。  
现有单表 `sales_forecasts`、changelog `0620-002`、SD Entity/API **一律视为废稿**，实施时 `DROP CASCADE` 后按本目录重建。不要把旧列（`version` 行级、`status_option_id`、无表头）迁进新表。

主流程：

```text
预告确认 ACTIVE
  → 开量转 FO（sourceType = FORECAST）→ 与正式单共用 MRP / 工单 / 入库
滚动换版
  → 旧单 CLOSED（未转开量作废；已转未接管的 FO 留在 supersedes 链上）
正式 SO 确认
  → 按 公司 + 客户 + 物料 + 时间桶 消耗
  → 先接管换版链上未认领的 FO，再吃当前 ACTIVE
  → 重叠量不重复投产
交货 DN 只认 SALES_ORDER
```

审查后已锁定（相对初稿）：关单**不**要求 `open_to_allocate=0`；`order_peggings` 唯一键必须带 `demand_type/supply_type`；消耗隔离 `company_id`。细节见 [04-实施清单.md](./04-实施清单.md) §2。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：正式单链、废稿单表、占位枚举、错误接法 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：维护、转 FO、SO 消耗/接管、API、前端 |
| [03-schema设计.md](./03-schema设计.md) | `sales_forecasts` / items、数量账、枚举、Pegging、旧表废弃 |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、改动面、提交顺序、验收 |

对照已落地的正式订单：`sales_orders` / `sales_order_items` 与 FO `add-items-from-so`。预告对齐其「表头–明细 + 行号 + 确认」骨架，**去掉价税交收字段**，**加上桶日期与消耗量**。

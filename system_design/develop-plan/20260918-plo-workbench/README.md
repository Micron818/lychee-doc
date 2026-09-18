# 计划工单作业台（PLO Workbench）

本目录描述 **生产建议转计划工单、计划工单转生产工单** 的作业入口优化。  
对照采购已落地的 `/scm/purchase-orders` 三 Tab：计划员仍在 MRP 结果里看建议，**转单与后续处理收敛到计划工单页**。

**不改变单据链。** 计算完成后不自动转 PLO，不跳过 PLO 直接出 MO，不自动 FIRMED。  
PROPOSED / FIRMED / CONVERTED、再生式清理、仅 FIRMED 计入供给，全部维持现网。

```text
FO → MRP → MrpResult(PRODUCTION)
              │  结果页只跳转，不再在此 POST 转单
              ▼
        计划工单页 Tab「MRP 待转」  →  PLO(PROPOSED)
              │  同页切 Tab「计划工单」
              ▼
        智能批量：确认 / 取消确认 / 转 MO / 删除
              ▼
             MO
```

采购对照：`../20260825-purchase`（结果页 PURCHASE → `/scm/purchase-orders?tab=mrp`）。  
本专题是生产侧对等的作业收敛，**不是**采购那种「去掉中间单据」。PLO 仍是确认门。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：跨页转单、行内单笔动作、与采购工作台的不对称 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：PLO 页双 Tab、转单规则、智能批量工具栏、API |
| [03-schema设计.md](./03-schema设计.md) | 无表结构变更；待转 DTO 与 Pegging 契约 |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、加锁/Tab/空选等实现约定、提交顺序、验收 |

相关实现（改造前）：

- 结果页转 PLO：`ResultList.tsx` → `MrpConversionServiceImpl.convertToPlannedOrders`
- PLO 行内动作：`PlannedOrderMoreActionsButton` → `firm` / `unfirm` / `convertToProductionOrders`（每次 1 条）
- 批量 API 已存在但前端未接到工具栏：`PlannedOrderController` `bulk-firm` / `bulk-unfirm` / `bulk-convert-to-mo`
- 采购工作台：`MrpProposalWorkbench` + `findPendingPurchaseItems`（「该厂最新 Run」）

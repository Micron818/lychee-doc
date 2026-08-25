# 原物料采购流程设计

本目录描述 **FO 驱动的原物料采购** 如何从现有 `MrpResult → PR → PO` 简化为 `MrpResult → PO`。  
请购保留给内部申请；PO 主档用 `source_type` 区分 `MRP` / `PURCHASE_REQUISITION` / `MANUAL`。系统尚未上线，允许改表。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：现有单据链、作业步骤、代码路径与摩擦点 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：采购工作台、转单规则、API、MRP 供给/清理、实施阶段 |
| [03-schema设计.md](./03-schema设计.md) | 物料供应商主档、PO 来源、Pegging、`mrp_results.convert_status`、PR 保留范围 |

相关实现（改造前）：

- 转 PR：`MrpConversionServiceImpl.convertToPurchaseRequisitions`
- 建 PR：`RemotePurchaseRequisitionServiceImpl.createFromMrpResults`
- 审 PR：`PurchaseRequisitionServiceImpl.approvePurchaseRequisitionBulk`
- 汇入 PO：`PurchaseOrderGenerationServiceImpl.createPurchaseOrderItemsFromPr`
- 溯源：`order_peggings`（不在明细上存 `source_*_id`）

对照生产侧已落地的一键转单：`PlannedOrderServiceImpl.convertToProductionOrders`。

# 客户退货（CUSTOMER_RETURN）

本目录描述 **销售出库的反向单**：把已过账 `SALES_DELIVERY` 领料中尚未被 AR 占用的数量退回仓库。  
**不是**内部退料（`STOCK_ISSUE_RETURN`），也**不是**采购退货（`PURCHASE_RETURN`），也**不是**负向交货单。

中文、表名、单据类型、流水账类型统一为 **客户退货 / `CUSTOMER_RETURN`**。不要写「销售退货」作正式名称（locale 可用 Sales Return 作英文）。不要启用 `deliveries.delivery_type = RETURN`，不要实现收货转换 `CUSTOMER_RETURN_ITEM`。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：交货、销售出库、应收、占位枚举与缺口 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：单据链、数量账、过账、API、前端 |
| [03-schema设计.md](./03-schema设计.md) | `customer_returns` / items、领料/交货已退、删除 `CUSTOMER_RETURN_ITEM` |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、改动面、提交顺序、验收 |

已开票要退：先做 [应收贷项](../应收贷项/README.md)，不要在退货过账里生成贷项。  
已收款要退现金：见 [客户退款-主流程V1](../客户退款-主流程V1/README.md)。

对照已落地的采购退货：`PurchaseReturnServiceImpl` / `/wm/purchase-returns`。  
客户退货骨架对齐采购退货，上游改为 `SALES_DELIVERY` 领料 + 交货/SO，下游冲回 COGS。

三件套一起设计、实施可分波：建议 **应收贷项 → 客户退货 → 客户退款**。本目录只覆盖库存退货；贷项过账前本波仍只退未占用数量。

# 采购退货（PURCHASE_RETURN）

本目录描述 **采购收货的反向单**：把已过账采购收货中尚未开票的数量退回供应商。  
**不是**内部退料（`STOCK_ISSUE_RETURN`），也**不是**客户退货（`CUSTOMER_RETURN`）。

中文、表名、单据类型、流水账类型统一为 **采购退货 / `PURCHASE_RETURN`**。不要写「供应商退货」、`VENDOR_RETURN`、`VENDER_RETURN`。系统未上线，现网占位的 `StockTransactionType.VENDOR_RETURN` **改名为** `PURCHASE_RETURN`。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：收货、退料、应付、占位枚举与缺口 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：单据链、数量账、过账、API、前端 |
| [03-schema设计.md](./03-schema设计.md) | `purchase_returns` / items、收货 `returned_quantity`、枚举更名 |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、改动面、提交顺序、验收 |

已开票要退：先做 [应付贷项](../应付贷项/README.md)（FI 二期），不要在退货过账里生成贷项。

对照已落地的内部退料：`StockIssueReturnServiceImpl` / `/wm/stock-issue-returns`。  
采购退货骨架对齐退料单，上游改为收货 + PO，下游冲回 GR/IR。

审查补丁（相对初稿）：AP 回写闸门、已退用单据量求和、PO `CLOSED` 守卫、冲销超收、凭证冻结成本与清尾。口径以 `02` / `04` 为准。

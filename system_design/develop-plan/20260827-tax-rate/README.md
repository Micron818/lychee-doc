# 税码与税率（二期）

本目录描述如何把一期「单据行手填 `tax_rate` 百分比」升级为规范 ERP 的 **税码主数据 + 税分类判定 + 单据快照**。  
系统尚未上线，允许改表；与采购工作台、科目判定（`INPUT_TAX` / `OUTPUT_TAX`）同一套租户/公司模型对齐。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：裸百分比、默认 0、过账只认金额、主数据无税分类 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：税码/税分类/判定矩阵、开单带出、下游复制快照、发票可改票面税额 |
| [03-schema设计.md](./03-schema设计.md) | `tax_codes` / `tax_code_rates` / `tax_classes` / `tax_determinations`（含国家键）与单据行加列 |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、改动面、提交顺序、验收 |

相关实现（改造前）：

- 采购金额：`PurchaseOrderItemServiceImpl` / `PurchaseOrderGenerationServiceImpl.applyItemAmounts`（未税 × 税率 / 100）
- 委外金额：`OutsourceOrderItemServiceImpl`
- 销售金额：`SalesOrderServiceImpl`（新建行税率写死 0）
- AP/AR 过账：`ApInvoicePostingServiceImpl`（`INPUT_TAX`→222102）、`ArInvoicePostingServiceImpl`（`OUTPUT_TAX`→222101）
- 收货快照：`goods_receipt_items.tax_rate` 从 PO/委外行复制

对照已落地的科目判定：`valuation_classes` + `fi_account_determination`。税码是税务维度，评估类是存货/收入科目维度，**不要合并成一张表**。

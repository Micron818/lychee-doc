# 付款条件（Payment Term）

本目录描述如何把一期「ADM `PAYMENT_TERM` 选项 + 从 code/name 正则抽天数」升级为规范 ERP 的 **付款条件主档 + 条件行 + 发票付款排程**。  
系统尚未上线，**一次交付完整方案**，不保留 option 字典双轨，不做「先在 option_values 加 metadata」的过渡。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：字典选项、parse 文字、静默 30 天、发票无条件快照 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：主档/条件行、到期日算法、单据带出、发票排程、现金折扣 |
| [03-schema设计.md](./03-schema设计.md) | `fi_payment_terms` / `fi_payment_term_lines` / 发票排程 / FK 替换 |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、改动面、提交顺序、验收 |

相关实现（改造前）：

- 到期日：`fi/.../PaymentTermDueDateHelper.java`（从 `option.code` / `option.name` 抓第一组数字，失败则 30）
- AP 立账：`ApInvoiceFromGoodsReceiptServiceImpl`（只用往来主档条件，忽略 PO）
- AR 立账：`ArInvoiceFromDeliveryServiceImpl`（同上，忽略 SO）
- 手工开票：`ap-invoices/index.tsx` / `ar-invoices/index.tsx` 写死 `dueDate = today + 30`
- 往来：`business_partners.payment_term_option_id` → `option_values`
- 单据：`purchase_orders` / `sales_orders` 同字段；委外单无付款条件
- 供应商/客户表单：只读展示 FI 带出的选项，保存时剥离

对照已落地的财务主档：`valuation_classes`、`gl_accounts`。付款条件是**会计规则**，不是 ADM 枚举；与税码专题（`chartExp/tax-rate`）同一哲学——从 `option_values` 毕业到 FI。

# 应收贷项（AR Credit Memo）

本目录描述 **应收发票的反向单**：把已过账 AR 上的数量/金额贷回客户，并回减交货行 `invoiced_quantity`。  
**不是**收款单，**不是**发票作废，**不是**客户退货。客户退货仍是 WM 库存单据；贷项先过账后，占用下降，退货按 V1 公式即可退。

中文、表名、单据类型统一为 **应收贷项 / `AR_CREDIT_MEMO`**。不要写「红字发票」作为正式名称。我们开给客户的税务贷项号进 `tax_credit_note_no`（对标 AR 的 `tax_invoice_no`），不要照搬应付的「供应商贷项号」。不要把贷项做成负向 `AR_INVOICE`。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：AR 正数发票、收款核销、客户退货占用闸 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：单据链、占用回减、拆 applied / refundable、凭证、API |
| [03-schema设计.md](./03-schema设计.md) | `ar_credit_memos` / lines、`ar_invoices.credited_amount` / `applied_credit_amount` |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、改动面、提交顺序、验收 |

对照已落地的应付贷项：`ApCreditMemoServiceImpl` / `/fi/ap-credit-memos`。  
客户退货见 [../客户退货/README.md](../客户退货/README.md)。真实现金退款见 [客户退款-主流程V1](../客户退款-主流程V1/README.md)。

本专题按 **应付贷项当前口径** 一次设计：贷项可超过未收剩余并拆 applied / refundable。不要先做「只能贷未收」再打补丁。

跨专题归属：`refundable/page` **本波交付**。[客户退货](../客户退货/README.md) 实现 `existsPostedByDeliveryItemIds`（本波先 stub）。现金退款见 [客户退款-主流程V1](../客户退款-主流程V1/README.md)。

# 应付贷项（AP Credit Memo）

本目录描述 **应付发票的反向单**：把已过账 AP 上尚未付清的数量/金额贷回供应商，并回减收货行 `invoiced_quantity`。  
**不是**付款单，**不是**发票作废，**不是**采购退货。采购退货仍是 WM 库存单据；贷项先过账后，占用下降，退货按 V1 公式即可退。

中文、表名、单据类型统一为 **应付贷项 / `AP_CREDIT_MEMO`**。不要写「红字发票」作为正式名称（供应商纸质红字号进 `external_credit_note_no`）。不要把贷项做成负向 `AP_INVOICE`。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | As-Is：AP 正数发票、付款核销、采购退货 V1 占用闸 |
| [02-目标流程.md](./02-目标流程.md) | To-Be：单据链、占用回减、核销、凭证、API、前端 |
| [03-schema设计.md](./03-schema设计.md) | `ap_credit_memos` / lines、`ap_invoices.credited_amount` |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、改动面、提交顺序、验收 |

对照已落地的应付发票：`ApInvoiceServiceImpl` / `/fi/ap-invoices`。  
采购退货 V1 见 [../采购退货/README.md](../采购退货/README.md)；本专题落地后回写其 §7。

> 当前专题已切到「贷项可超过未付剩余并拆 applied / refundable」口径。真实现金退款见 [供应商退款-主流程V1](../供应商退款-主流程V1/README.md)。  
> 完整目标（换日核销、状态机等）见 [供应商退款](../供应商退款/README.md)，不要按该完整范围实施。

SO   - Sales Order
SFO  - Sales Forecast
SR   - Sales Return

PR   - Purchase Requisition
PO   - Purchase Order
POR  - Purchase Return

PLN  - Planned Order
MO   - Production Order
RWK  - Rework Order
SUB  - Subcontract Order

DO   - Delivery Order
GI   - Goods Issue
GR   - Goods Receipt
TO   - Transfer Order

AR   - AR Invoice
AP   - AP Invoice

INT  - Internal Order
FMO  - Factory Management Order


Internal / Control Orders
 ├─ 成本管理類
 ├─ 工廠管理類
 ├─ 專案 / 專用訂單
 ├─ 維修 / 品保
 ├─ 管理控制 / 例外
internal_order
internal_order_cost

Factory Management Order（工廠管理訂單）
factory_order
factory_order_so_rel

Maintenance Order（維修工單）


Sales Order
   ↓
Factory Order
   ↓
Planned Order
   ↓
Production Order
   ↓
Internal Order（成本歸集）


Sales Order        → 市場需求
Factory Order      → 工廠需求
Planned Order      → MRP 計劃結果
Production Order   → 生產執行

Planned Order
PLANNED → CONVERTED → CANCELLED
Production Order
CREATED → RELEASED → IN_PROCESS → COMPLETED → CLOSED

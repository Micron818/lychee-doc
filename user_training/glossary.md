# 术语表（中文 ↔ 越南文）

> 中文为源。越南文列在启动 `vi/` 翻译时填齐；缩写两语共用。  
> 界面菜单名以系统当前界面显示为准；本表用于训练文档用词统一。  
> 训练文档功能范围对照：`menus_20260808`（与正文为同一套材料），并已纳入采购订单页工作台与「物料供应商」。SQL 表英文 `name`（如 OO、MR、Cost Roll-up）**不**作为训练用语；以界面中文与下表缩写为准。

## 单据与流程缩写

| 缩写 | 中文 | Việt Nam（待填） | 说明 |
|------|------|------------------|------|
| SO | 销售订单 | | Sales Order |
| DN | 交货单 | | Delivery Note |
| FO | 工厂订单 | | Factory Order |
| PR | 采购申请 | | 仅内部手工请购；原物料不经 PR |
| PO | 采购订单 | | 三种诞生方式：MRP / 采购申请 / 手工 |
| OSO | 委外加工订单 | | Outsource Order（界面用 OSO，非 OO） |
| GR | 收货单 | | Goods Receipt |
| SI | 库存领料 | | Stock Issue |
| ST | 库存调拨 | | Stock Transfer |
| PI | 库存盘点 | | Physical Inventory |
| BOM | 物料清单 | | Bill of Materials |
| MRP | 物料需求计划 | | Material Requirements Planning |
| PLO | 计划工单 | | Planned Order |
| MO | 生产工单 | | Production / Manufacturing Order |
| MOR | 工单产量回馈 | | Manufacturing / Production Report（界面用 MOR，非 MR） |
| AP | 应付发票 | | Accounts Payable Invoice |
| AR | 应收发票 | | Accounts Receivable Invoice |
| GR/IR | 收货/发票暂估 | | Goods Receipt / Invoice Receipt |

## 模块

| 代码 | 中文 | Việt Nam（待填） | 备注 |
|------|------|------------------|------|
| ADM | 系统管理 | | |
| BASIS | 基础资料 | | |
| MM | 物料管理 | | |
| SD | 销售管理 | | |
| SCM | 采购管理 | | |
| WM | 仓储管理 | | |
| PP | 生产计划 | | |
| FI | 财务会计 | | |
| RPT | 报表中心 | | 文档中亦可称 REPORT；菜单 access_key 为 RPT |

## 通用界面用语

| 中文 | Việt Nam（待填） | 备注 |
|------|------------------|------|
| 草稿 | | 常见状态起点 |
| 提交 | | |
| 审核 / 批准 | | 以界面实际文案为准 |
| 过账 | | 财务凭证类 |
| 作废 | | |
| 冲销 | | |
| 导出 | | |
| 导入 | | |
| 打印 | | |
| 下载 PDF | | |
| 导出中心 | | 菜单：报表中心 → 导出中心 |
| 导入中心 | | 菜单：报表中心 → 导入中心 |
| 筛选 | | |
| 保存 | | |
| 删除 | | |
| MRP 待转 | | 采购订单页页签；各厂最新 MRP 的待买建议 |
| 请购待转 | | 采购订单页页签；已核准 PR 明细待转 PO |
| 来源类型 | | PO 如何诞生：MRP / 采购申请 / 手工；创建后不可改 |
| 物料供应商 | | 物料×工厂×供应商：默认供应商、采购单位、最小订购量、末次价 |

## 关账与成本（高频禁忌用词）

| 中文 | Việt Nam（待填） | 备注 |
|------|------------------|------|
| 库存期末结账 | | WM；菜单 `menu.wm.inventoryPeriods` |
| 进耗存汇总表 | | WM；菜单 `menu.wm.inventoryBalances` |
| 会计期间结账 | | FI |
| 成本结算 | | FI；界面名「成本结算」（勿称 Cost Roll-up） |
| 活跃成本结算 | | 未作废且未结束的成本作业，会阻止库存期重开 |
| 倒扣料 | | Backflush |
| 倒扣料异常 | | 需在「倒扣料异常处理」处理 |
| 物料采购成本分析 | | FI 进阶查询入口 |

## 维护说明

1. 新增术语先改本表，再写剧本正文。  
2. 越南文翻译批次应整表核对一次，避免同词多种译法。  
3. 与界面文案不一致时：以**已上线界面**为准，并回改本表与训练正文。

# 速查：采购管理（SCM）

> 版本：2026-08-08 | 语言：zh | vi 同步：待同步

## 入口（界面菜单）

| 菜单路径 | 训练深度 |
|----------|----------|
| `采购管理 → 供应商管理` | PB-01 / PB-06 |
| `采购管理 → 采购申请(PR)` | PB-03 |
| `采购管理 → 采购订单(PO)` | PB-03 / PB-06 |
| `采购管理 → 委外加工订单(OSO)` | PB-08 |

## 典型动作

PR → PO →（打印/PDF）→ 等待 GR；OSO → 发料/收货协同仓储。

## 禁忌

- 草稿 PO 勿外发给供应商。  
- 导出需 `export` 权限。  
- 界面缩写为 **OSO**（非 OO）。  
详见 [PB-03](../03-process-playbooks/PB-03-procure-to-pay.md)、[PB-06](../03-process-playbooks/PB-06-export-and-print.md)、[PB-08](../03-process-playbooks/PB-08-outsource-loop.md)。

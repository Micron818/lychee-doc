# 速查：生产计划（PP）

> 版本：2026-08-01 | 语言：zh | vi 同步：待同步

## 入口

BOM、工厂订单(FO)、MRP 参数、MRP 运行、计划工单(PLO)、生产工单(MO)、产量回馈(MOR)、倒扣料异常。

## 典型动作

BOM →（FO）→ MRP → PLO → MO → MOR；异常进倒扣料队列。

## 禁忌

- 勿盲目全量转换 MRP 结果。  
- 结案前处理倒扣料异常（除非豁免流程）。  
详见 [PB-04](../03-process-playbooks/PB-04-mrp-to-production.md)。

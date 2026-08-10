# MRP 系统设计

本目录文档以**当前代码实现**为唯一依据，描述现有能力，并给出后续演进计划。

| 文档 | 说明 |
|------|------|
| [01-current-capability.md](./01-current-capability.md) | 现有功能盘点（As-Is） |
| [02-evolution-plan.md](./02-evolution-plan.md) | 演进计划（To-Be，分阶段） |

相关代码主路径：

- Backend：`lychee-erp-pp`（`MrpServiceImpl` / `MrpCalculationEngine` / `MrpScheduleServiceImpl` / `MrpScheduleJob`）
- Frontend：`lychee-frontend/src/pages/pp/mrp-runs`、`mrp-parameters`、`mrp-schedules`

# 管理监测（系统健康与每日生产进度）

本目录描述用户测试阶段给管理者看的 **只读监测**。两件事：

1. 系统资料完整度与健康指标。页面壳先做，指标上线后按需要逐个加。
2. 每天的生产进度。数据来自已有报工 `ProductionReport`，本波做汇总页，不改报工单据。

**留在现有 Web。** 同一地址用响应式布局，手机浏览器能看。本阶段不新建手机专案、不引入图表库、不落导出作业、不建新表。

监测入口和拼装放在 `lychee-erp-report`。查询留在数据所属模块。`lychee-erp-report` 继续只依赖 `lychee-erp-common`，不依赖 pp / wm / fi 等业务模块。

```text
浏览器  /report/monitors
    │  Bearer，菜单权限 /report/monitors:read
    ▼
lychee-erp-report
    ├─ GET  /api/v1/report/monitors/health
    │     收集各模块注册的 HealthIndicator，拼成卡片
    └─ POST /api/v1/report/monitors/production-progress
          转发到 pp 的只读查询
    ▼
各业务模块（查询、租户过滤、口径）
    pp：当日已过账报工的良品 / 返工 / 报废、产出、单位与良品率
    其他模块：各自的健康指标（P2 起逐个注册）
```

与已有 Excel 的分工：

| 已有 | 本专题 |
|------|--------|
| [生产日报表](../20260818-report/11-示例-生产日报表.md)：单厂 + 单日 + 单一状态的报工 Excel | 展开进度区块后看当日进度；只计 `POSTED` |
| [工单进度报表](../20260818-report/10-示例-工单进度报表.md)：生产工单计划 vs 完工 / 齐套 | 齐套与工单进度导出不在本页。监测页只在展开某一厂后的工单卡片上显示累计完工 / 计划量 |

导出框架仍只管文件作业。监测是同步读接口，不走 `ExportJob`。

| 文档 | 说明 |
|------|------|
| [01-现状与方案选择.md](./01-现状与方案选择.md) | 现网能力、三种做法、选定 Web 监测页的理由 |
| [02-目标架构.md](./02-目标架构.md) | 模块边界、页面、权限、与日报 Excel 的口径差 |
| [03-契约设计.md](./03-契约设计.md) | 健康指标 SPI、生产进度查询接口、API |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：P0 空壳、P1 当日进度、P2 起逐个指标 |
| [05-物料变体检核.md](./05-物料变体检核.md) | P2 第一批三张变体卡片，以及监测页按区块展开后载入 |
| [06-物料变体排查.md](./06-物料变体排查.md) | 下一批：三张变体卡片在需关注时打开抽屉，列出违规物料 |
| [07-进度区交互.md](./07-进度区交互.md) | 进度区：无工厂下拉、点一厂展开工单、改日期即查、手动刷新 |

相关实现（设计时点）：

- report 只依赖 common：`lychee-erp-report/build.gradle`
- 导出分发：`DataExportHandler` + `ExportJobServiceImpl` 收集 Handler
- 报工与日报查询在 pp：`ProductionReport`、`ProductionDailyExportHandler`
- 工单进度查询在 pp：`ProductionProgressExportHandler`（本专题不调用）

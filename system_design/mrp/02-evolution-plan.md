# MRP 演进计划（基于现有实现）

> 目标：在**不推翻**现有「创建 Run → 异步计算 → 人工转单」骨架的前提下，补齐触发、作用域与运维能力。  
> 约束：转单默认仍人工确认；不自动产出 MO / PO。

---

## 1. 问题陈述

现有系统已具备可用的 Regenerative 净算与转单闭环，但触发面过窄：

| 现状 | 影响 |
|------|------|
| 仅前端手动 `POST /mrp-runs` | 依赖计划员记得跑；夜间无固定重算 |
| `MrpRun` 无工厂 / 计划期间 / 触发来源 | 无法按厂排程、无法审计「谁/何因」触发 |
| 每次全量清理未固化建议 | 多用户同时点跑会互相覆盖 |
| `CANCELLED` 未落地 | 长任务无法中止 |
| Net Change / 变更驱动缺失 | 白天频繁全量成本高 |

演进原则：

1. **单一执行内核**：所有触发通道最终都调用现有 `createMrpRun` → `MrpRunCreatedEvent` → `MrpCalculationEngine`
2. **先补治理，再扩算法**：排程与互斥优先于 Net Change
3. **结果仍是建议**：自动触发 ≠ 自动转单

---

## 2. 目标架构（逻辑）

```text
┌─────────────┐  ┌──────────────┐  ┌─────────────────┐
│ 手动 (UI)   │  │ 定时 Job     │  │ Net Change 合并 │
└──────┬──────┘  └──────┬───────┘  └────────┬────────┘
       │                │                   │
       └────────────────┼───────────────────┘
                        ▼
              MrpRunOrchestrator
              （校验互斥 / 填默认参数 / 记 triggerSource）
                        ▼
              MrpService.createMrpRun  ← 现有
                        ▼
              MrpCalculationEngine     ← 现有（后续可扩 scope）
                        ▼
              MrpResult → 人工转 PLO/PR ← 现有
```

---

## 3. 阶段划分

### Phase 0 — 基线固化（文档与观测，无行为变更）

**目的：** 让团队对 As-Is 对齐，便于改造验收。

- [x] 盘点现有能力 → `01-current-capability.md`
- [ ] 明确验收用例（见第 5 节）并补到测试清单
- [ ] 为 Run 列表补充「执行耗时 / 失败原因」展示核对（字段已存在）

**完成标准：** 产品 / 开发对「需求来源、供给来源、清理范围、转单边界」无歧义。

---

### Phase 1 — Run 作用域与并发治理（P0）✅ 实现中/已落地代码

**目的：** 让「定时」和「多人手动」可以安全共存。

#### 1.1 扩展 `MrpRun` / `MrpRunRequest`

| 字段 | 说明 | 默认（兼容现网） |
|------|------|------------------|
| `factoryId` | 可选；空=全租户工厂（等同今日行为） | null |
| `planningHorizonDays` | 可选计划期间（天）；空=不截断 | null |
| `triggerSource` | `MANUAL` / `SCHEDULED` / `NET_CHANGE` / `API` | `MANUAL` |
| `triggeredBy` | 用户 id 或系统账号标识 | 当前登录用户 |
| `runMode` | `OPERATIVE` / `SIMULATION`（逻辑后置） | `OPERATIVE` |

前端创建弹窗增加工厂（可选）、计划期间（天，可选）；后端校验工厂存在性。

#### 1.2 同范围互斥

- 全厂 Run（`factoryId=null`）：租户内存在任意 `RUNNING` 则拒绝
- 单厂 Run：同厂 `RUNNING` 或全厂 `RUNNING` 则拒绝
- 冲突时返回明确业务错误，不创建第二笔 Run
- 定时任务命中互斥时：记日志 / 告警，跳过本轮

#### 1.3 清理范围收窄（配合 factory 过滤）

- 有 `factoryId`：只清该工厂未固化结果 / PROPOSED PLO / DRAFT MRP-PR
- 无 `factoryId`：保持现行为

引擎种子需求与供给收集同步按工厂过滤；`planningHorizonDays` 仅截断初始需求种子。

#### 1.4 交付物

- Liquibase：`mrp_runs` 加列
- `MrpServiceImpl` 互斥校验
- `MrpCalculationEngine` scope 过滤
- FE：创建表单字段 + 列表展示 triggerSource / factory

**完成标准：** 厂 A 运算不删除厂 B 的未转单建议；同厂第二次创建在 RUNNING 期间被拒绝。

---

### Phase 2 — 定时 Regenerative（P0）✅ 已落地

**目的：** 规范 ERP 日终全量重算，不再只靠人工点按钮。

#### 2.1 排程配置（`mrp_schedules`）

| 字段 | 说明 |
|------|------|
| `tenantId` / `factoryId` | 作用范围（工厂可选） |
| `cronExpression` + `timeZone` | Spring 6 段 Cron + IANA 时区 |
| `enabled` | 开关 |
| `planningHorizonDays` | 传给 Run |
| `lastTriggeredAt` / `lastErrorMessage` | 运维观测 |
| 自动转单 | **不做**（仍人工转 PLO/PR） |

#### 2.2 执行器

- `MrpScheduleJob` 固定间隔轮询（默认 60s，`lychee.mrp.schedule.*`）
- `SystemTenantAuthentication`（userId=0）+ `RemoteTenantService` 跨租户扫描
- 到期则调用现有 `createMrpRun`，`triggerSource=SCHEDULED`
- 互斥冲突：跳过并写 `lastErrorMessage`，推进 `lastTriggeredAt` 防每分钟重试

#### 2.3 运维

- FE：`/pp/mrp-schedules` CRUD +「立即执行」
- Run 列表可筛 `triggerSource=SCHEDULED`
- Liquibase 同步写入菜单与权限（对已有 MRP Runs 读权限的角色授权）

**完成标准：** 指定工厂可在无人值守下按 Cron 产生 COMPLETED Run；与手动 Run 互斥正确。

---

### Phase 3 — 运行控制补齐（P1）

**目的：** 长任务可管理。

| 项 | 做法 |
|----|------|
| 取消 | 将 `CANCELLED` 落地：RUNNING 中标记取消；引擎循环检查 flag，停止写结果并清理本 Run 半成品 |
| 超时 | 配置最大执行时长，超时 → FAILED |
| 空跑可辨 | 无需求时 COMPLETED，但可记 `resultCount=0`（可选字段）便于 UI 提示 |
| 删除保护 | RUNNING 不可删（FE 已有部分限制，BE 补强） |

**完成标准：** 可取消卡死/误触发的 Run；状态机完整：`RUNNING → COMPLETED|FAILED|CANCELLED`。

---

### Phase 4 — Net Change（P1）

**目的：** 白天增量重算，降低全量成本。前提：Phase 1 作用域已稳定。

#### 4.1 Planning File（脏标）

变更写脏（物料 + 工厂），来源第一批：

- FO 确认 / 数量或交期变更 / 关闭
- BOM 批准
- `mrp_parameters` 变更

#### 4.2 合并触发

- 定时微批（如每 5–15 分钟）或脏标数量阈值
- 创建 `triggerSource=NET_CHANGE` 的 Run
- 引擎仅处理脏物料及其下层 LLC（需扩展 `calculateMrp` 的 seed/cleanup 范围）

#### 4.3 与 Regenerative 关系

- 夜间 / 周初：SCHEDULED Regenerative（全量）
- 白天：NET_CHANGE
- FIRMED PLO / 已审批 PR 保护规则与今日一致，不削弱

**完成标准：** 改一张 FO 交期后，相关料号建议更新，无需全租户重算；夜间全量仍可校准。

---

### Phase 5 — 需求面扩展（P2，按业务优先级选做）

仅在现有引擎种子点扩展，不改主骨架：

| 候选 | 说明 | 依赖 |
|------|------|------|
| SO 独立需求 | 未转 FO 的确认 SO 可参与（需产品定规则，避免与 FO 双重计算） | SD 开量接口 |
| Forecast | 启用已有 `MrpSourceType.FORECAST` | 预测主数据 |
| 安全库存独立需求行 | 与今日「净算下限」二选一或并存策略需产品确认 | 参数语义澄清 |
| OUTSOURCE 建议 | 恢复第三动作类型，转单对接委外 | 物料供应类型主数据 |

每项单独开需求，不与排程强绑定。

---

### Phase 6 — 体验与可解释性（P2）

基于已有 Result + Pegging，增强计划员效率：

- Run 差异比对（本次 vs 上次建议量/交期）
- 例外视图：缺 BOM、lead time=0、净需求被 max lot 截断等（计算中写 exception 码，今日无）
- 结果层供需投影（库存 + receipts − demands 时间轴）
- 模拟 Run：不参与「正式清理」、不可转单或转至隔离区（字段已预留 `runMode`）

---

## 4. 明确不做（本期边界）

| 不做 | 原因 |
|------|------|
| 定时自动转 PLO/PR/MO/PO | 违背现有「建议→人工确认」闭环；风险高 |
| CRP / 产能平衡 | 当前无产能模型 |
| 实时每次库存异动全量 MRP | 成本不可控；由 Net Change 合并窗口替代 |
| 重写计算引擎 | 现有 LLC + pegging + lot sizing 可演进 |

若未来需要「自动转 PR」，必须：独立开关、物料白名单、完整审计，且默认关闭。

---

## 5. 验收用例（跨阶段）

### 现网回归（任何改造后必须过）

1. 存在 CONFIRMED FO 开量 → 手动跑 MRP → 产生 PRODUCTION/PURCHASE 结果  
2. PRODUCTION 结果可转 PROPOSED PLO，并建立 `MRP_RESULT→PLANNED_ORDER` pegging  
3. PURCHASE 结果可转 DRAFT PR，pegging 指向 PR item  
4. FIRMED PLO 不被下次 Regenerative 清掉，并计入供给  
5. 已转单且供给已固化的结果不被误删  
6. 批量删除含已转单结果的 Run → 业务校验失败  

### Phase 1+

7. 厂 A RUNNING 时，同厂再创建 → 拒绝  
8. 厂 A 运算不清理厂 B 未转单建议  
9. 全厂 RUNNING 时，任意单厂创建 → 拒绝  

### Phase 2+

10. 启用排程后，到点自动产生 `triggerSource=SCHEDULED` 的 COMPLETED Run  
11. 排程与手动互斥行为符合配置  

### Phase 4+

12. 仅变更 FO 交期 → Net Change 更新相关料建议，无关料结果保持  

---

## 6. 建议实施顺序与工期量级

| 阶段 | 内容 | 量级（参考） | 依赖 |
|------|------|--------------|------|
| Phase 0 | 基线对齐 | 0.5d | — |
| Phase 1 | 作用域 + 互斥 + 清理收窄 | 3–5d | — |
| Phase 2 | 定时排程 | 2–3d | Phase 1 |
| Phase 3 | 取消 / 超时 | 2–3d | Phase 1 |
| Phase 4 | Net Change | 5–8d | Phase 1 |
| Phase 5/6 | 需求扩展 / 体验 | 按项评估 | 产品优先级 |

推荐上线切片：**Phase 1 + Phase 2** 作为第一交付；Net Change 作为第二交付。

---

## 7. 关键改造点（代码锚点）

| 改动 | 锚点 |
|------|------|
| 创建与互斥 | `MrpServiceImpl.createMrpRun` |
| 异步执行 | `MrpRunEventListener`（可加取消检查协作点） |
| 清理 / 种子 / 净算 | `MrpCalculationEngine` |
| 供给收集 | `MrpScheduledReceiptServiceImpl` |
| 转单（原则上本期少动） | `MrpConversionServiceImpl` |
| FE 创建与列表 | `pages/pp/mrp-runs/**` |
| 新排程（新增） | `pp` 模块 schedule 实体 + Job |

---

## 8. 已确认决策

| # | 议题 | 决策 |
|---|------|------|
| 1 | 工厂必填还是可选？ | **可选**。排程与手动均允许空（空=全租户工厂）。 |
| 2 | 互斥冲突时跳过还是排队？ | **跳过并告警**（创建接口返回业务错误；定时任务记日志跳过）。 |
| 3 | 是否预留 `runMode=SIMULATION`？ | **是**。Phase 1 加字段与枚举；SIMULATION 逻辑后置，创建时暂拒。 |
| 4 | Net Change 脏标第一批来源？ | FO 变更 + BOM 批准 + MRP 参数变更（Phase 4）。 |

互斥细化（Phase 1 实现）：

- 全厂 Run（`factoryId=null`）：租户内存在任意 `RUNNING` 则拒绝
- 单厂 Run：同厂 `RUNNING`，或全厂 `RUNNING`，则拒绝

<style>
@page {
  size: A4 landscape;
  margin: 12mm;
}

.markdown-preview.markdown-preview table {
  display: table;
  width: 100%;
  max-width: 100%;
  table-layout: fixed;
  overflow: visible;
}


.markdown-preview.markdown-preview th,
.markdown-preview.markdown-preview td {
  overflow-wrap: anywhere;
  word-break: break-word;
  white-space: normal;
}

.markdown-preview.markdown-preview td code,
.markdown-preview.markdown-preview th code {
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
</style>

# P1 资料权限 MVP 分阶段设计

> 本文按 MVP 原则重排 [03-P1资料权限设计.md](./03-P1资料权限设计.md) 的实施顺序：先交付公司、工厂、仓库三个维度的通用资料范围，其余特殊控制按实际需要分阶段决定是否实施。
>
> - 依据：[01-现状与问题.md](./01-现状与问题.md)、[02-权限现状与交付运维指南.md](./02-权限现状与交付运维指南.md)、03、[05-P1前置完成项.md](./05-P1前置完成项.md)，以及 2026-10-12 的代码。
> - 与 03 的关系：03 是完整的目标设计。本文决定先做哪些、怎样简化、其余部分什么时候做。已纳入本文阶段的内容以本文为准；阶段 2 各项的做法沿用 03 的对应章节。
> - 状态：待评审。阶段 0 的本地验证已完成；`.github/workflows/test.yml` 暂不加入，测试只在本机执行。

---

## 目录

- [〇、结论](#〇结论)
- [一、评估](#一评估)
- [二、阶段划分](#二阶段划分)
- [三、MVP 范围](#三mvp-范围)
- [四、MVP 设计](#四mvp-设计)
- [五、阶段 0：技术验证](#五阶段-0技术验证)
- [六、测试与验收](#六测试与验收)
- [七、阶段 2：按需项](#七阶段-2按需项)
- [八、移出本设计的事项](#八移出本设计的事项)
- [九、工作量与排期](#九工作量与排期)
- [十、风险与对策](#十风险与对策)
- [十一、待确认事项](#十一待确认事项)

---

## 〇、结论

**可以按 MVP 分阶段，建议这样做。** 03 的主体是一套通用机制：范围挂在角色指派上，读取由 Hibernate 过滤器在 ORM 层统一加条件，写入只约束用户直接操作的单据。这套机制不按单据类型写代码，新增单据登记一次即受控。03 的其余内容，例如页面上下文、来源单据校验、导出快照、单据链、行规则、分级管理，多数是在这套机制上补精度或补体验，可以等通用部分上线、看到实际需求后再逐项决定。

**MVP（阶段 1）只交付组织范围：**

- 指派上按公司、工厂、仓库设范围，类型只有"全部"和"指定"。
- 读：登记过的单据头、明细、库存台账一律按范围过滤。列表、详情、明细分页、导出、打印、单据选择器、监控走同一套条件，业务代码不用改。
- 写：只过滤用户正在操作的那类单据；新建、修改的单头必须落在范围内；库存过账的仓库必须在范围内。
- 存量指派迁移为"公司 = 全部"，上线时行为不变；总开关可以一键恢复 P0 行为。

**有三项要留在 MVP。** 它们看起来像特殊功能，实际是通用机制成立的前提：

1. **过滤器要对每个 EntityManager 生效。** FI 发票、贷项的批量动作在 `REQUIRES_NEW` 新事务里逐张 `findById`，例如 `ApInvoiceActionProcessor`。如果只在请求的 OSIV Session 上启用过滤器，这些新事务会照常读到范围外的发票，过账的连带处理执行完，才由写守卫在 flush 时拦下并回滚；以后在新事务里做的读取则会直接漏出去。
2. **用户发起的异步导出、导入要带发起人的范围。** 超过 5000 行的导出在异步线程执行，按 03"非 Web 线程不受限"的默认规则会导出全部数据。所以导出、导入不能整体延后。最小做法是执行时按发起人重新求范围，不需要 03 的范围快照；能延后的是快照和下载时的覆盖比较。
3. **动态权限表达式要能求出权限串。** 四个 FI 批量动作接口写成 `hasAuthority('/fi/ap-invoices:' + #request.action?.permissionAction)`。求不出权限串，就判断不了读写模式和主资源：这些写接口会被当成读接口处理，过账要用的连带资料可能被过滤掉，范围也变成全部指派的并集。

**收益主要在风险和复杂度，不在工期。** 工期从 03 的 24–30 人日（P1-0 加 P1-a）降到约 20–23 人日。降幅不大，但以下机制不再进入第一版：页面上下文请求头；约 50 个 `isAuthenticated()` 接口的逐个声明；25 个参照建单接口的来源校验；导出范围快照；单据链脱敏；"所属"与"含下级"的动态求值；"仅本页"共享方式；管理范围上限；写守卫 LOG 模式。运行时机制收窄为读过滤、单头写守卫、过账仓库校验三类，导出、导入和下拉只是套用这三类。

**分期一览（人日，粗估）：**

| 阶段 | 内容 | 估算 |
|---|---|---|
| 阶段 0 技术验证 | 集成测试基座与 CI；验证过滤器行为，确定绑定方式；复核绕过过滤器的批量 DML | 3–4 |
| 阶段 1 MVP | 指派范围、范围求值、过滤器登记与绑定、单头写守卫、过账仓库校验、导出导入封口、组织下拉、管理界面、测试矩阵 | 17–19 |
| 阶段 2 按需 | 页面上下文、单据链、导出快照、批量反馈、参照配置、银行账户、所属与下级、行规则、分级管理等，每项写明触发条件 | 每项 0.5–5 |

---

## 一、评估

### 1. 判断标准

逐项看 03 的内容，分三类处理：

- **通用部分：** 不按单据类型写代码，靠登记或一处切面覆盖全部单据，以后新增的单据登记一次即受控。放进 MVP。
- **前提或封口：** 不做的话，通用机制会被整条路径绕过，或者在某类接口上判断错误。放进 MVP，只做最小版本。
- **可延后：** 不做的后果只是精度不够或体验不好，而且影响面可以在上线前说清楚。放到阶段 2，写明触发条件。

### 2. 03 各项的评估

| 03 的内容 | 本文结论 | 理由 |
|---|---|---|
| 指派范围表；存量回填"公司 = 全部"（5.1、5.5） | 阶段 1 | 通用部分的数据基础 |
| "所属"类型、"含下级公司"（5.1、6.1） | 阶段 2-7 | 便利功能。"所属"还要求用户换厂时联动驱逐缓存。MVP 用"指定"表达，界面预填被指派人的所属公司 |
| 范围求值与多指派合并（6.1、6.2） | 阶段 1 | 通用 |
| 范围跟随权限串（8.2） | 阶段 1 | 通用。用方法参数对 `@PreAuthorize` 求值，静态与动态写法一并覆盖 |
| 求不出权限串时为空范围，靠 `@DataScope` 逐个声明（8.2、附录 C） | 改为取用户全部指派的并集 | 上限仍是本人范围，与 03 页面上下文的缺省规则一致；省去约 50 个接口的逐个声明 |
| 页面上下文请求头（8.6） | 阶段 2-1 | 只影响多角色、且各角色范围不同的用户；结果偏宽，但不超出本人范围 |
| 读模式过滤全部登记资源（7.1、8.3） | 阶段 1 | 通用，并且是防止借道读取的关键 |
| "共享 / 仅本页"两种方式（7.1） | MVP 只有"共享" | "仅本页"的参照配置在 MVP 不登记，行为与现在相同 |
| 受控资源清单（7.2） | 阶段 1 登记业务单据与台账 | 参照配置、公司银行账户、用户、客户不登记；盘点单改按仓库维度（4.4 节） |
| 写模式只过滤主资源；写守卫（8.4） | 阶段 1 | 通用 |
| 过账校验仓库（8.4） | 阶段 1，放在库存流水服务里 | 流水只有 `StockTransactionLedgerServiceImpl.persist` 一个写入点，不必走 Hibernate 事件 |
| 批量写"条数不符即拒绝"（8.4） | 阶段 2-4 | 范围外的 ID 查不到，不越权；"先删明细"的写法靠登记规则保证安全（4.6 节） |
| 参照建单来源校验（8.5、附录 B） | 阶段 2-12，个别入口按需 | 05 已补来源组织一致性；目标单头由写守卫把关后，来源被间接约束（4.7 节） |
| 组织下拉过滤（8.6） | 阶段 1，按全部指派的并集 | 成本低，能减少"选了却存不进"的 403 |
| 导出范围快照、他人下载覆盖校验（5.3、8.7） | 阶段 2-3；MVP 只做封口 | 执行时按发起人重新求范围；他人的文件只允许范围为"全部"的人下载 |
| 导入以写模式执行（8.7） | 阶段 1 | 只有一个处理器，套一层写模式即可 |
| 单据链（7.4） | 阶段 2-2 | 节点详情由各模块的 enricher 用 JPA 加载，过滤后范围外节点自动没有单号和状态 |
| 监控看板（7.4） | 不需要处理 | 健康指标只读物料主数据；生产进度走 JPQL，自动按 `/report/monitors:read` 的范围过滤 |
| 行规则（5.2、6.3、附录 D） | 阶段 2-8 | 03 本来就放在 P1-b |
| 管理范围上限、HR 按公司分级（9.2） | 阶段 2-9 | 单 HR 的交付模型下不需要；现在持有用户管理权限的人本来就能指派任意角色 |
| 有效范围查询（9.4） | 阶段 2-10 | MVP 在指派列表显示范围摘要 |
| 写守卫 LOG 模式（8.11） | 不做 | 存量指派都是"全部"，守卫不会触发；试点出问题用总开关回退 |
| P1-0 的预置 SYS 角色、删除草稿表、`putIfAbsent`、02 勘误 | 移出本设计 | 与资料范围互不依赖（第八节） |
| P1-0 的测试 CI 与 Testcontainers | 阶段 0 | Testcontainers 基座已在本地跑通（第五节）。CI 工作流暂不加入 |

### 3. 影响 MVP 的代码事实

| 事实 | 位置 | 对 MVP 的影响 |
|---|---|---|
| FI 批量动作在 `REQUIRES_NEW` 中逐张处理 | `ApInvoiceActionProcessor`、`ArInvoiceActionProcessor`、`ApCreditMemoActionProcessor`、`ArCreditMemoActionProcessor` | 过滤器必须在新建的 EntityManager 上也生效（4.5 节） |
| 三个异步监听器都把发起人的 `Authentication` 放进执行线程 | `ExportJobEventListener`、`ImportJobEventListener`、`MrpRunEventListener` | 不能用"线程上有身份就受限"作为默认规则，否则 MRP 只能算到发起人的工厂；导出、导入要显式套范围 |
| 动态权限表达式 7 处 | 4 个 FI `/action`（写），3 个单据链接口（读） | 权限串要结合方法参数求值 |
| 权限动作不是 read 的查询接口只有 1 个 | `POST /scm/purchase-orders/pending-mrp-items/page`（`:create`） | 只需一处显式声明读模式；GET 接口全部是 `:read` |
| 库存流水只有一个写入点 | `StockTransactionLedgerServiceImpl.persist`，各 `record*Line` 共用；倒冲走 `recordBackflushLine` | 仓库校验放在这里，倒冲按方法豁免 |
| 退货类"批量带入"要求明细属于单头的原始来源单，单头工厂取自来源单 | `PurchaseReturnItemServiceImpl`、`StockIssueReturnItemServiceImpl`、`CustomerReturnItemServiceImpl` | 加上 05 的一致性校验，参照建单只需校验目标单头 |
| 单据链节点由 10 个 enricher 用 `findAllById` 补详情 | `SalesOrderPeggingEnricher` 等 | 范围外节点自动拿不到单号、状态、订单数量 |
| 导出处理器 7 个，导入处理器 1 个 | `DataExportHandler`、`DataImportHandler` 的实现类 | 导出、导入封口只涉及两个服务和两个监听器 |
| 出货对账单读取公司银行账户 | `DeliveryBillingStatementServiceImpl` | 工厂级单据会跨维度读取公司级资料；MVP 不登记银行账户 |
| `mrp_runs.factory_id`、`mrp_schedules.factory_id` 可空，空值表示全部工厂 | `MrpServiceImpl.assertNoConflictingRunningRun` | 登记时要声明空值语义（4.4 节） |
| 批量删除常按请求 ID 先删明细 | `DeliveryServiceImpl.deleteDeliveryBulk`、`SalesOrderServiceImpl.deleteSalesOrderBulk`、`MrpServiceImpl.deleteMrpRunBulk` | 明细和同一菜单下操作的子表必须登记到单头的路径，写模式才会一起过滤 |
| 受控表与单据链上的 `@Modifying` 约 16 处 | `MrpResultRepository`、`SalesOrderItemRepository`、`MaterialCostRepository`、`OrderPeggingRepository` 等 | 批量 DML 不经过过滤器。阶段 0 已复核，用户路径不用改调用（4.6 节） |
| 改公司国家码时的未结案检查必须看全量（05 第 2 节） | `CompanyServiceImpl.applyCountryCode` 调用 `RemoteSdOpenDocumentService`、`RemoteScmOpenDocumentService` | 它在 `/basis/companies:update` 的写模式下执行，主资源是公司，不登记；销售、采购、委外订单都不会被过滤 |
| 按租户共享的 `@Cacheable` 都不含受控资料 | 各组织下拉、科目树、业务伙伴、MRP 参数等缓存 | MVP 不用改缓存；以后登记 MRP 参数时要另行处理（阶段 2-5） |
| 评估时没有 `@SpringBootTest` 或数据库集成测试；CI 只有部署工作流 | `.github/workflows/deploy.yml` | 本地 Testcontainers 基座已建立（第五节）。CI 工作流仍暂缓 |
| 原生 SQL 里只剩单据链追溯涉及业务数据 | `OrderPeggingRepository` | 05 已删除 `existsOpenByCompanyId` |

---

## 二、阶段划分

```mermaid
flowchart LR
    S0["阶段 0 技术验证<br/>测试基座、过滤器行为、绑定方式"] --> S1["阶段 1 MVP<br/>公司、工厂、仓库读写范围"]
    S1 --> OBS["试点与观察<br/>按组织逐步收窄范围"]
    OBS --> S2["阶段 2 按需项<br/>出现触发条件才做"]
```

- 阶段 0 的结论决定阶段 1 的过滤器绑定方式，必须先做完。
- 阶段 1 的前端可以和后端并行。
- 阶段 2 各项互相独立，按触发条件逐项立项；没有出现触发条件的就不做。

---

## 三、MVP 范围

### 1. 包含

| # | 内容 | 章节 |
|---|---|---|
| 1 | `user_role_scopes` 表；存量指派回填"公司 = 全部"；组织列索引 | 4.1 |
| 2 | 授权明细随权限快照缓存；组织目录；范围求值 | 4.2 |
| 3 | 控制器切面：求权限串、定读写模式、写入上下文 | 4.3 |
| 4 | 约 60 个实体登记（单头、明细、台账）与登记校验测试 | 4.4 |
| 5 | 过滤器绑定到所有 EntityManager | 4.5 |
| 6 | 写模式主资源过滤、单头写守卫、过账仓库校验 | 4.6 |
| 7 | 参照建单"新建类"入口核对 | 4.7 |
| 8 | 导出、导入封口 | 4.8 |
| 9 | 公司、工厂、仓库下拉按范围过滤 | 4.9 |
| 10 | 指派范围 API、校验、范围摘要；前端范围编辑器 | 4.10 |
| 11 | 总开关、错误语义、日志、i18n | 4.11 |
| 12 | 单元测试、结构测试、集成测试矩阵 | 第六节 |

### 2. 不包含，以及上线后的实际效果

| 不做的内容 | MVP 上线后的效果 | 何时再做 |
|---|---|---|
| 页面上下文 | 多角色、且各角色范围不同的用户，下拉和 `isAuthenticated()` 接口按他全部指派的并集返回 | 阶段 2-1 |
| 单据链特殊处理 | 范围外节点仍显示类型、ID、挂钩数量、物料，但没有单号、状态、订单数量；根节点不做可见性校验 | 阶段 2-2 |
| 导出范围快照 | 异步导出在执行时重新求范围；他人的导出文件只有范围为"全部"的人能下载 | 阶段 2-3 |
| 批量写反馈 | 范围外的 ID 按不存在处理：删除类跳过，动作类计入失败明细 | 阶段 2-4 |
| 参照配置隔离（会计期间、成本政策、科目确定、税务确定、物料工厂设置、货源清单、MRP 参数、库存期间） | 不受控，与现在相同 | 阶段 2-5 |
| 公司银行账户 | 不受控，与现在相同 | 阶段 2-6 |
| "所属""含下级公司" | 只能逐个指定；用户换厂要手工改指派 | 阶段 2-7 |
| 行规则、HR 分级与管理范围上限、有效范围查询、客户本人业务员 | 不提供 | 阶段 2-8 至 2-11 |
| 来源单据显式校验 | 依靠 05 的组织一致性和目标单头写守卫 | 阶段 2-12，个别入口 |

---

## 四、MVP 设计

本节只写 MVP 的做法；与 03 相同的部分注明出处。接口路径省略 `/api/v1` 前缀。

### 1. 数据模型与迁移

```sql
CREATE TABLE lychee_erp.user_role_scopes
(
	id bigserial NOT NULL,
	tenant_id bigint NOT NULL,
	user_role_id bigint NOT NULL,
	dimension varchar(20) NOT NULL,
	scope_type varchar(10) NOT NULL,
	value_id bigint NULL,
	created_at timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at timestamp without time zone NULL DEFAULT CURRENT_TIMESTAMP,
	created_by bigint NULL,
	updated_by bigint NULL,
	CONSTRAINT user_role_scopes_pkey PRIMARY KEY (id),
	CONSTRAINT fk_user_role_scopes_user_role FOREIGN KEY (user_role_id)
		REFERENCES lychee_erp.user_roles (id) ON DELETE CASCADE,
	CONSTRAINT ck_user_role_scopes_dimension CHECK (dimension IN ('COMPANY', 'FACTORY', 'WAREHOUSE')),
	CONSTRAINT ck_user_role_scopes_type CHECK (scope_type IN ('ALL', 'LIST')),
	CONSTRAINT ck_user_role_scopes_value CHECK ((scope_type = 'LIST') = (value_id IS NOT NULL))
);

CREATE INDEX idx_user_role_scopes_user_role ON lychee_erp.user_role_scopes (user_role_id);
CREATE UNIQUE INDEX uk_user_role_scopes ON lychee_erp.user_role_scopes
	(user_role_id, dimension, scope_type, COALESCE(value_id, 0));
```

| 列 | 说明 |
|---|---|
| `dimension` | `COMPANY` 公司 / `FACTORY` 工厂 / `WAREHOUSE` 仓库 |
| `scope_type` | `ALL` 全部；`LIST` 指定 |
| `value_id` | `LIST` 时的组织 ID |

**规则：**

- 一条指派可以有多行，同一维度的多行取并集。
- 某个维度没有行，表示不单独设定，从上级维度推导（4.2 节）。
- 一行都没有，表示"无资料范围"：功能照常可用，但看不到、也改不了受控单据。
- 同一维度不能既有 `ALL` 又有 `LIST`，保存时拒绝。
- 删除指派时由外键级联删除范围行，因为 `deleteAllInBatch` 不触发实体级联。
- 以后加"所属""含下级公司"时，放宽 CHECK 约束、加一列即可，已有数据不用迁移。

**迁移（随阶段 1 发版）：**

1. 建表；adm 新增实体 `UserRoleScope`。
2. 回填存量指派：每条现有 `user_roles` 插入一行 `COMPANY / ALL`，SQL 同 03 5.5 节第 2 步（去掉 `include_children` 列）。
3. 组织列索引：为下面还没有 `(tenant_id, <组织列>)` 前缀的表补索引，使用 `CREATE INDEX IF NOT EXISTS`。更长的唯一索引只要以这两列开头，视为已经有。2026-10-16 用本地库 `pg_index` 对比：明细的单头外键列都已有索引，不用再补。`purchase_orders` 现有的 `factory_id` 单列索引、`stock_on_hand` 与 `inventory_balances` 里排在第三列的仓库列，都不算这个前缀。

    | 维度 | 要补索引的表 |
    |---|---|
    | 公司 | `sales_orders` |
    | 工厂 | `purchase_requisitions`、`purchase_orders`、`outsource_orders`、`goods_receipts`、`purchase_returns`、`customer_returns`、`stock_issues`、`stock_issue_returns`、`stock_transfers`、`production_orders`、`production_reports`、`production_backflush_exceptions`、`mrp_runs`、`mrp_schedules`、`mrp_results`、`factory_orders` |
    | 仓库 | `physical_inventories`、`stock_on_hand`、`stock_transactions`、`inventory_balances` |

**今后凡是写 `user_roles` 的脚本**（租户初始化、数据修补）都要同时插入范围行，否则新指派是"无资料范围"。

### 2. 范围求值

**单条指派 g：**

- 公司集合 C(g)：公司行的并集；没有公司行时为空。
- 工厂集合 F(g)：有工厂行时取工厂行的并集；没有时取 C(g) 下的全部工厂。
- 仓库集合 W(g)：有仓库行时取仓库行的并集；没有时取 F(g) 下的全部仓库。
- "全部"始终保留为标记，不展开成 ID 列表。这样既能跳过过滤，也能覆盖以后新建的组织。

| 指派的范围设定 | 公司级单据 | 工厂级单据 | 仓库（台账、盘点） |
|---|---|---|---|
| 公司 = 全部 | 全部 | 全部 | 全部 |
| 公司 = C1 | C1 | C1 下的工厂 | 这些工厂下的仓库 |
| 工厂 = F1 | 无 | F1 | F1 下的仓库 |
| 工厂 = F1，仓库 = W1 | 无 | F1 | W1 |
| 公司 = C1，工厂 = F1 | C1 | F1 | F1 下的仓库 |
| 仓库 = W1 | 无 | 无 | W1 |
| 不设范围 | 无 | 无 | 无 |

组织只向下覆盖，不向上推导（同 03 6.1 节）。工厂岗位需要引用公司级单据（例如出货引用销售订单）时，指派要同时设公司范围。

**多条指派：** 对权限串 a，取持有 a 的全部有效指派，各维度求并集；任一指派在某维度为"全部"，并集就是"全部"。求不出唯一权限串时（4.3 节），取用户全部有效指派的并集。

**组织目录 `OrgDirectory`：** 只需要"工厂 → 公司""仓库 → 工厂"两张映射。接口放在 common，实现复用现有的 `Remote*Service`，按租户缓存，组织主数据增删改时驱逐。MVP 不需要公司树和部门树。

**缓存：** 授权明细（指派 ID、该指派的权限串集合、范围行）随 `UserAuthorities` 放进 `user-authorities` 缓存，结构放在 common 供各模块使用。指派的增删改已经 `@CacheEvict(allEntries = true)`，不用另加驱逐。组织展开在求值时进行；同一请求内，同一权限串只求一次。

### 3. 确定权限串与读写模式

**切面 `DataScopeAdvice`** 包住所有 `@RestController` 处理器方法，在方法鉴权之后执行：

1. **求权限串。** 用一个"记录型"根对象重新求值 `@PreAuthorize` 表达式：`hasAuthority(x)` 记下 x 并返回 true；`hasAnyAuthority(...)` 全部记下；`isAuthenticated()` 和 `@platformSecurity` 一律返回 true、不记。变量取方法参数，所以 `'/fi/ap-invoices:' + #request.action?.permissionAction` 和 `#orderType.readAuthority` 都能求出实际的串。
   - 记到一个：就是它。
   - 记到多个：取各自范围的并集。现在只有 `/fi/ap-credit-memos/refundable/page` 一处，两个都是 read。
   - 一个都没记到（`isAuthenticated()`）：取用户全部指派的并集。
   - 代码里目前没有 `or` 写法。记录型求值遇到 `or` 会短路漏记，所以结构测试禁止新增。
2. **定模式。** 权限串的动作为 `read` 时是读模式，其余动作是写模式；求不出权限串时按读模式。例外用 `@DataScopeMode(READ)` 声明，目前只有 `pending-mrp-items/page`。导出、导入的权限串不在注解上，由服务层切换（4.8 节）。
3. **写入上下文**：权限串、模式、有效范围、主资源路径（权限串去掉动作的部分）。方法结束时恢复原上下文。

**上下文的默认值：**

- **Web 请求线程**在切面之前没有上下文时按"空范围"处理，作为兜底。
- **非 Web 线程**没有上下文时视为系统作业，不受限。MRP 计算（`MrpRunEventListener`）、`MrpScheduleJob`、`ExchangeRateSyncJob` 都属于这一类，MRP 必须看到全部数据。
- **业务代码**用 `DataScope.call(authority, mode, action)` 切换，结束时恢复。

**为什么用并集而不是空范围：** 03 要求求不出权限串时为空，再对每个接口声明豁免或页面上下文。MVP 改为并集，因为上限仍是用户本人的范围；而且这类接口里只有导入会写受控资料，已在 4.8 节处理。代价是多角色用户在这些接口上看到的比单个页面宽，需要时由阶段 2-1 补上。

### 4. 受控资源登记

**登记方式：** 每个受控实体声明自己的过滤器，名称为 `ds_<表名>`。

```java
@Entity
@Table(name = "purchase_orders")
@DataScopeResource(path = "/scm/purchase-orders", dimension = Dimension.FACTORY, field = "factoryId")
@FilterDef(name = "ds_purchase_orders", parameters = @ParamDef(name = "ids", type = Long.class),
        applyToLoadByKey = true)
@Filter(name = "ds_purchase_orders", condition = "factory_id in (:ids)")
public class PurchaseOrder extends AuditableEntity { ... }

@Entity
@Table(name = "purchase_order_items")
@DataScopeResource(path = "/scm/purchase-orders", parent = PurchaseOrder.class, parentField = "purchaseOrderId")
@FilterDef(name = "ds_purchase_order_items", parameters = @ParamDef(name = "ids", type = Long.class),
        applyToLoadByKey = true)
@Filter(name = "ds_purchase_order_items",
        condition = "purchase_order_id in (select h.id from purchase_orders h where h.factory_id in (:ids))")
public class PurchaseOrderItem extends AuditableEntity { ... }
```

- **读模式**启用全部登记实体中、所属维度不是"全部"的过滤器。
- **写模式**只启用登记在主资源路径下的过滤器：单头、明细，以及同一菜单下操作的子表。
- 03 用三个按维度共用的过滤器，再给每个资源加一个行过滤器。MVP 改为每个实体一个过滤器，"读全部、写只过滤主资源"就只是启用哪些过滤器的区别。阶段 2 的行规则可以直接扩展同一个过滤器的条件。
- 连接串用 `currentSchema=lychee_erp`。子查询里的表名不加 schema 前缀；委外组件的两层子查询同样可以解析。阶段 0 已在采购订单明细和委外订单组件上确认。

**登记规则：**

1. **同一菜单下操作的明细和子表，登记到单头的路径。** 例如 MRP 结果登记为 `/pp/mrp-runs`。批量删除普遍按请求 ID 先删明细（1.3 节），只有登记在同一路径下，写模式才会把范围外单据的明细一起过滤掉。
2. **子表有自己的组织字段时按自己的字段过滤**，例如 MRP 结果的 `factory_id`；没有时经单头子查询过滤。两级明细（委外订单组件 → 委外明细 → 单头）用两层子查询。
3. **组织字段可空的单头**（`mrp_runs`、`mrp_schedules`，空值表示全部工厂）：
   - 读模式下，空值记录对有工厂范围的人可见，其下 MRP 结果仍按结果自身的工厂过滤；
   - 写模式下，空值记录只对工厂维度为"全部"的人可见，新建或改成空值同样要求"全部"；
   - 条件里加一个参数控制空值是否可见，例如 `factory_id in (:ids) or (:nullVisible = 1 and factory_id is null)`。
4. **盘点单按仓库维度登记。** 盘点单一单一仓，明细就是该仓的账面数量；按工厂登记会让只管 W11 的人看到 W12 的账面。其他 WM 单据一单多仓，仍按工厂登记（同 03）。

**MVP 登记清单：**

| 模块 | 单头与台账（维度） | 同路径登记的明细与子表 |
|---|---|---|
| FI | `journal_entries`、`ap_invoices`、`ar_invoices`、`ap_credit_memos`、`ar_credit_memos`、`payments`、`fixed_assets`、`asset_depreciations`、`cost_calculations`、`cost_allocations`、`material_costs`（公司） | 凭证分录；发票明细与收付款计划；贷项明细；收付款明细；成本计算明细 |
| SD | `sales_orders`、`sales_forecasts`（公司）；`deliveries`（工厂） | 订单明细、预测明细、出货明细 |
| SCM | `purchase_requisitions`、`purchase_orders`、`outsource_orders`（工厂） | 请购明细；订单明细；委外明细与组件 |
| WM | `goods_receipts`、`purchase_returns`、`customer_returns`、`stock_issues`、`stock_issue_returns`、`stock_transfers`（工厂）；`physical_inventories`（仓库）；台账 `stock_on_hand`、`stock_transactions`、`inventory_balances`（仓库） | 各单据明细、盘点明细 |
| PP | `production_orders`、`production_reports`、`production_backflush_exceptions`、`planned_orders`、`mrp_runs`、`mrp_schedules`、`factory_orders`（工厂） | 生产订单组件；报工组件；MRP 结果（按自有工厂字段）；工厂订单明细 |

合计约 60 个实体，以登记校验测试的清单为准。

**不登记，行为与现在相同：**

| 资料 | 原因 |
|---|---|
| 公司、工厂、仓库、部门 | 组织主数据。维护页不按范围隔离；下拉在返回前过滤（4.9 节） |
| 会计期间、成本政策、科目确定、税务确定、物料工厂设置、货源清单、MRP 参数、库存期间 | 组织级参照配置，被各单据当参照读取；需要时在阶段 2-5 做"仅本页"隔离 |
| 公司银行账户 | 出货对账单（工厂级）会读取，登记后只有工厂范围的人打印会缺数据。见阶段 2-6 |
| 用户、客户 | 见阶段 2-9、2-11 |
| 物料、BOM、供应商、汇率等其他主数据 | 租户内共享（同 03 7.3 节） |
| `order_peggings` | 系统联结表；节点详情由各单据的过滤器把关 |

**登记校验（启动时执行，并有对应的单元测试）：**

- 字段存在；声明了同名过滤器；明细的父实体已登记；路径格式正确。
- 凡是有 `company_id`、`factory_id`、`warehouse_id` 列的实体，要么已登记，要么列在上表的排除清单里并写明原因。这样以后新增的单据表不会被漏掉。

### 5. 过滤器绑定

**要求：** 每个新建的 EntityManager 都要按当前线程的上下文启用过滤器。代码里有四种来源，都要覆盖：

| 来源 | 例子 |
|---|---|
| OSIV：请求一开始就创建，那时上下文还没确定 | 所有 Web 请求 |
| `REQUIRES_NEW` 新事务 | FI 发票、贷项的动作处理器 |
| 非事务的共享 EntityManager | `ExportJobServiceImpl.executeExportJob`（`NOT_SUPPORTED`） |
| 异步线程 | 导出、导入监听器 |

**做法（阶段 0 已选定）：** `entityManagerInitializer` 加上 `DataScope.call` 对已打开 Session 的重新绑定。备选 `@FilterDef(autoEnabled = true)` 未做原型，不采用。

- 在 `LocalContainerEntityManagerFactoryBean` 上设置 Spring 6.1 起提供的 `entityManagerInitializer`：每个 EntityManager 创建时，按当前上下文启用过滤器并绑定参数。`REQUIRES_NEW` 因此在新事务里生效；应付发票批量动作里，范围外的发票按不存在处理，失败明细不带单号。
- 切面写入上下文、`DataScope.call` 切换和恢复时，对当前线程已绑定的 Session 重新绑定一次。OSIV 和 `NOT_SUPPORTED`（异步导出执行）走这条路径，因为 Session 在上下文确定之前就已经打开。
- 异步线程必须自己调用 `DataScope.call`。没有上下文的线程不启用过滤器，定时作业因此不受限。
- 在已经打开的 Session 上切换范围之前先 `clear()`。否则过滤启用前装进一级缓存的实体，再次 `find` 仍会返回。
- "全部"的维度不启用过滤器，不产生任何额外条件；空集合用哨兵值 `-1`，保证条件为假。
- 范围条件加在根实体的 `WHERE`，不进 `LEFT JOIN` 的 `ON`。`DynamicSpecifications.fetch` 的 count 查询不带 fetch join，但带同一条 `WHERE`。第一页没满时 Spring Data 不另发 count。
- `@TenantId` 与资料范围条件同时出现在 `WHERE`。`findById`、`findAllById`、`existsById` 对范围外记录按不存在处理。`getReferenceById` 以及懒加载的多对一，在访问属性时抛 `EntityNotFoundException`，不返回 null，也不抛 `EntityFilterException`。

### 6. 写入控制

**写模式主资源过滤。** 只启用主资源路径下的过滤器。范围外的单据和明细查不到：单条接口返回 404，批量接口按不存在处理。过账写库存、回写来源数量、倒冲、生成凭证等连带处理读写的是其他资源，不受影响。

**单头写守卫。** 在 `AuditableEntity` 上追加一个实体监听器：

- **生效范围：** 写模式下，对主资源路径下登记了组织字段的实体生效。读模式本不应写受控单头；如果出现（例如导入漏了切换模式），同样按当前范围校验，作为兜底。
- **新增**（`persist` 时）：组织字段必须在写范围内。ID 是自增列，`save()` 当场执行插入，异常当场抛出；导入处理器逐行 try/catch，越界行自然记为该行失败。
- **修改**（flush 时）：新值必须在写范围内。旧值已由过滤保证在范围内，只校验新值。显式 flush 直接抛出 `DataScopeDeniedException`；提交时包在 `TransactionSystemException` → `RollbackException` 里。`GlobalExceptionHandler` 沿 cause 链找到它，返回 403。`persist` 同样直接抛出，不包装。
- **删除**不校验：删除前必须先加载，加载已经过滤。
- 所有单头实体都继承 `AuditableEntity`。没有继承的只有 `SysDocSequence` 和 `ProductionOrderComponent`，前者不受控，后者是明细。

**过账仓库校验。** 在 `StockTransactionLedgerServiceImpl.persist` 中，写模式下要求流水的仓库在写范围的仓库集合内；调拨的调出、调入两笔都校验。

- `recordBackflushLine` 豁免：倒冲的原料仓通常不归报工人员管（同 03）。
- 系统作业不校验。
- `StockLedgerReconciliationServiceImpl` 直接 `saveAll`，属于对账工具，不经过这一校验。

**批量写。** 范围外的 ID 查不到，不越权。"先删明细"的写法依靠 4.4 节规则 1：明细登记在同一路径下，只删得到范围内单据的明细。阶段 0 复核了受控表和单据链上的 15 处 `@Modifying`：用户路径传入的 ID 都来自已经过滤的加载，不用改调用。`deleteOldProposedOrders`、`deleteEmptyRuns`、`MrpResultRepository.deleteByIds` 只在 MRP 运算里执行，运算不受限。读接口没有对受控表做“查不到就新建”。现存量在过账时补行，工厂和仓库取自已经加载的单头。

**越界：** 抛 `DataScopeDeniedException`（继承 `AccessDeniedException`），返回 403 和 `error.data.scope.denied`，记 WARN 日志，带上租户、用户、权限串、实体、组织值。

### 7. 参照建单

MVP 不另做来源校验。依据有三条：

1. 05 已完成来源组织一致性：收货、领料、调拨、出货、工厂订单、委外拉计划订单。采购订单引用请购另有 `validation.purchase_order.factory_mismatch`。
2. 退货类单据（采购退货、领料退回、客户退货）的单头工厂取自原始来源单，"批量带入"的明细必须属于该来源单。
3. 写守卫保证目标单头在写范围内。来源与目标同组织，来源也就落在同一范围里。

**一项核对任务：** 下列"新建类"入口会从来源单生成新单头，实现时要确认新单头的组织取自来源，而不是取自请求参数。发现取自请求的，按 05 的方式补一致性校验。

| 入口 | 来源 |
|---|---|
| `POST /fi/ap-invoices/from-goods-receipt` | 收货单 |
| `POST /fi/ar-invoices/from-delivery` | 出货单 |
| `POST /fi/ap-credit-memos/from-ap-invoice`、`POST /fi/ar-credit-memos/from-ar-invoice` | 发票 |
| `POST /fi/fixed-assets/from-ap-invoice-lines` | 应付发票明细 |
| `POST /scm/purchase-orders/from-mrp-results`、`/from-pr-items` | MRP 结果、请购明细 |
| `POST /pp/planned-orders/from-mrp-results`、`/bulk-convert-to-mo` | MRP 结果、计划订单 |

**已知残留：** 工厂级单据引用公司级来源（出货引用销售订单，工厂订单引用销售订单或预测）时，05 只保证同公司。只有工厂范围、没有公司范围的人，如果知道 ID，可以引用本公司里自己看不到的销售订单。界面上的选择器已按范围过滤，不会列出这些单据。

### 8. 导出与导入（最小封口）

| 环节 | MVP 做法 |
|---|---|
| 创建导出作业（count 与同步生成） | `ExportJobServiceImpl.createExportJob` 用 `DataScope.call(handler.requiredAuthority(), READ, ...)` 包住 |
| 异步导出 | `executeExportJob` 取到处理器后同样包住，范围按发起人当前的授权明细重新求值，不存快照。期间发起人的范围若被收窄，文件按收窄后的范围生成 |
| 下载 | 创建者本人可以下载。其他人（持有 `/report/export-jobs:read`）对该处理器权限串的范围必须三个维度都是"全部"，否则 403 |
| 导入（同步与异步） | `ImportJobServiceImpl` 的同步路径和 `executeImportJob` 都用 `DataScope.call(handler.requiredAuthority(), WRITE, ...)` 包住。现有唯一的处理器写 `material_costs`：范围外公司的行在 `persist` 时被拒，记为该行失败 |
| MRP 异步计算、定时作业 | 系统作业，不受限。发起 MRP 运行时，单头写守卫已经校验过工厂 |

### 9. 组织下拉

`GET /basis/companies/list`、`GET /basis/factories/list`、`GET /wm/warehouses/list` 是 `isAuthenticated()` 接口，按用户全部指派的并集过滤后返回：

| 下拉 | 返回 |
|---|---|
| 公司 | 公司集合，加上工厂集合中各工厂所属的公司（后者只用于显示层级） |
| 工厂 | 工厂集合，加上仓库集合中各仓库所属的工厂 |
| 仓库 | 仓库集合 |

- 过滤放在提供下拉的接口方法里。`Remote*Service` 和现有的按租户缓存继续返回全集，供内部逻辑使用。
- 部门下拉 MVP 不过滤，因为部门不是范围维度。

### 10. 管理面

**接口：**

- `POST /adm/user-roles`、`PUT /adm/user-roles/{id}`、`POST /adm/user-roles/bulk-create` 增加 `scopes`，元素为 `dimension`、`scopeType`、`valueId`。
  - 新建时必填，空列表表示"无资料范围"。
  - 修改时 `null` 表示不变，非 `null` 表示整体替换。
  - 批量指派时，同一组范围用于全部所选角色。
- `UserRoleResponse` 增加 `scopes` 和 `scopeSummary`。后者给列表显示，例如"公司：C1；工厂：F1"；没有范围时为"无资料范围"。

**保存时校验**，不通过报 `validation.user.role.scope.invalid`：维度与类型合法；`LIST` 的组织存在且属于本租户；同一维度不混用"全部"和"指定"。P0 的 `assertNotSelf` 照常生效，不能改自己的指派范围。

**不做管理范围上限。** 现在持有 `/adm/users:create`、`/adm/users:update` 的人本来就能指派任意角色，MVP 沿用这个信任模型；交付时 HR 的指派设为"公司 = 全部"。多名 HR 分公司管理时再做（阶段 2-9）。

**前端：**

| 位置 | 改动 |
|---|---|
| `src/pages/adm/users/components/UserRoleForm.tsx` | 范围编辑器：公司、工厂、仓库各一行，选"不单独设定 / 全部 / 指定"，指定时多选组织。新建时预填被指派人的所属公司（作为"指定"），保存前必须确认。底部按规则显示生效摘要，例如"公司级单据：C1；工厂级单据：C1 下全部工厂；库存：上述工厂下全部仓库"；一行都没有时醒目提示"无资料范围" |
| `src/pages/adm/users/components/UserRolePicker.tsx` | 批量指派时选一次范围，用于所选角色 |
| `src/pages/adm/users/columns/userRoleColumns.tsx` | 增加"资料范围"列，显示 `scopeSummary` |
| `src/requestConfig.tsx`、各业务页面 | 不改。列表和下拉由后端收窄；保存被拒时显示后端消息 |
| i18n | zh-CN、en-US、vi-VN 三套文案 |

### 11. 开关、错误语义与日志

```yaml
lychee:
  security:
    data-scope:
      enabled: true   # false：不启用过滤器、写守卫和过账仓库校验，恢复 P0 行为
```

| 场景 | 返回 |
|---|---|
| 读取范围外的单条记录 | 404，与不存在相同，不泄露记录是否存在 |
| 列表、导出 | 不含范围外记录 |
| 新建或修改到范围外；过账到范围外的仓库 | 403 `error.data.scope.denied` |
| 批量接口中有范围外的 ID | 按不存在处理：删除类跳过，动作类计入失败明细且不带单号 |
| 下载他人的导出文件，而范围不是"全部" | 403 |

- 新增 i18n 键 `error.data.scope.denied`、`validation.user.role.scope.invalid`，三种语言都要写。
- 每个请求求出的范围摘要记 DEBUG 日志；越界记 WARN 日志（4.6 节）。

### 12. 上线与回退

1. 发布阶段 1，`enabled = true`。存量指派都是"公司 = 全部"，不启用任何过滤器，行为不变。
2. 试点：先收窄一个工厂的一线岗位（仓管、生产），观察一到两周的 403 日志、用户反馈和慢查询。
3. 按组织逐步推开。需要引用销售订单的工厂岗位（出货、计划、工厂订单），指派时同时设公司范围。
4. 回退：把 `enabled` 设为 `false` 并重启，恢复 P0 行为。表结构保留，不回滚迁移。

---

## 五、阶段 0：技术验证

**状态：** 本地验证已完成（2026-10-16）。`.github/workflows/test.yml` 暂不加入；镜像构建仍使用 Dockerfile 的 `-x test`。

**测试基座：** Testcontainers PostgreSQL 15，执行全量 Liquibase。测试 changelog 在正式脚本前后分别关闭、恢复外键检查，空库才能跑完种子数据。本机命令：

```
.\gradlew.bat :lychee-erp:test --tests com.lychee.erp.db.* --no-daemon
```

**验证清单：**

| # | 验证项 | 用例 |
|---|---|---|
| 1 | `applyToLoadByKey` 对 `findById`、`findAllById`、`existsById`、`getReferenceById` 的效果 | 采购订单 |
| 2 | 多对一懒加载指向被过滤的实体时，是返回 null、抛 `EntityFilterException`，还是不过滤 | `PaymentLine.apInvoice`、`ProductionReport.productionOrder` |
| 3 | Specification 分页（含 count）与 `DynamicSpecifications.fetch` 的 fetch join：条件加在 ON 还是 WHERE，对 LEFT JOIN 的影响 | 收货单列表、MRP 结果页 |
| 4 | 明细经单头子查询的写法：不加 schema 前缀能否解析；两层子查询 | 采购订单明细、委外订单组件 |
| 5 | 绑定方式：OSIV、`REQUIRES_NEW`、`NOT_SUPPORTED`、异步线程、定时作业五种情形，过滤器是否都按预期启用或不启用 | `ApInvoiceActionProcessor`、异步导出、`MrpScheduleJob` |
| 6 | 同一 Session 切换上下文后，一级缓存里的实体会不会绕过过滤 | `DataScope.call` 前后各 `find` 一次 |
| 7 | 写守卫异常在 `persist`、flush、提交三个时点的包装形式，全局异常处理能否解包 | 新建、修改采购订单 |
| 8 | `@TenantId` 与过滤器同时生效时生成的 SQL | 任一单头 |
| 9 | 复核受控表与单据链上的 `@Modifying`（约 16 处），以及读接口里"查不到就新建"的写法 | 逐个过清单 |
| 10 | 数百个仓库 ID 的 IN 列表的执行计划 | 库存余额 |

**完成标准：** 采购订单（单头加明细）、现存量、应付发票批量动作三个原型已在 `DataScopePrototypeIT` 通过。绑定方式已写入 4.5 节。

**结论：**

| # | 结论 |
|---|---|
| 1、2 | 范围外的按键加载和懒加载多对一都按不存在处理，异常类型是 `EntityNotFoundException` |
| 3 | 范围条件在 `WHERE`；fetch join 仍是 `LEFT JOIN` |
| 4 | 子查询不加 schema 前缀；两层子查询有效 |
| 5、6 | 绑定见 4.5 节。已打开的 Session 切换范围前要 `clear()` |
| 7 | 写守卫的三种包装和 403 解包见 4.6 节 |
| 8 | 租户条件与资料范围条件同时出现在 `WHERE` |
| 9 | 15 处 `@Modifying` 不用改调用，见 4.6 节 |
| 10 | 400 个仓库 ID 的 `IN` 被收成 `warehouse_id = ANY(bigint[])`。只有租户和仓库时全表扫描；再带 `inventory_period_id` 时走 `idx_inventory_balances_warehouse`。不为此改过滤器。要不要另加 `(tenant_id, warehouse_id)` 索引，阶段 1 再定 |

---

## 六、测试与验收

1. **单元测试：** 4.2 节表格的每一行；多指派并集与"全部"标记；权限串求值（静态、7 处动态、`isAuthenticated()`、复合表达式）；读写模式判定；单头写守卫，含空值组织；过账仓库校验与倒冲豁免；下拉过滤规则；指派范围校验。
2. **结构测试：**
   - 4.4 节的登记校验，以及"有组织列的实体必须登记或列入排除清单"。
   - 路径以 `/page`、`/list` 结尾、权限动作不是 read 的处理器，必须声明 `@DataScopeMode`，防止以后新增的选择器被当成写模式。
   - `@PreAuthorize` 不得使用 `or`。
3. **集成测试矩阵（Testcontainers）：**
   - **数据：** 公司 C1、C2；工厂 F1 属于 C1，F2 属于 C2；每个工厂两个仓库 W11、W12、W21、W22。
   - **用户：** 全部；公司 C1；工厂 F1；工厂 F1 + 仓库 W11；公司 C1 + 工厂 F1；无范围。

| 场景 | 验证点 |
|---|---|
| 采购订单 | 列表、详情、明细分页、修改、审核、批量删除、从请购生成。范围外的详情和修改返回 404，批量删除跳过 |
| 收货单过账 | 过账到 W12 时，工厂 F1 + 仓库 W11 的用户 403，工厂 F1 的用户成功；采购订单已收数量照常回写 |
| 调拨过账 | 调出、调入仓都校验 |
| 报工过账 | 倒冲的原料仓不在范围内也能过账 |
| 现存量、库存余额 | 按仓库过滤；`suggest-allocations` 按全部指派的并集 |
| 盘点单 | 按仓库可见 |
| 销售订单与出货 | 只有工厂范围的用户看不到销售订单；加上公司范围后，出货页能显示订单号 |
| 应付发票批量动作 | 在 `REQUIRES_NEW` 中，范围外的发票计入失败且不带单号，范围内的成功 |
| MRP | 全厂运行（工厂为空）对工厂用户可见、不能删除；MRP 结果按工厂过滤 |
| 改公司国家码 | 只有部分工厂范围的人，在其他工厂仍有未结案单时被拒（05 第 2 节） |
| 导出 | 同步、异步各一次，结果按发起人范围生成；他人下载规则 |
| 导入 | 物料标准成本里范围外公司的行记为失败，其余行成功 |
| 组织下拉 | 公司、工厂、仓库三个下拉按并集返回 |
| "全部"用户 | 以上场景的结果与关闭开关时一致 |

4. **性能：** 在十万级数据量下，对比主要列表页在"全部"、公司 C1、工厂 F1 三类用户下的执行计划和耗时。
5. **验收标准：** 矩阵全部通过；"全部"用户的结果与开关关闭时一致；现有单元测试全部通过。

---

## 七、阶段 2：按需项

每项都写明什么情况下需要做；没有出现触发条件的就不做。估算单位为人日。

| # | 项目 | 触发条件 | 做法 | 估算 |
|---|---|---|---|---|
| 2-1 | 页面上下文 | 多角色用户反映下拉、选择器偏宽，或经常选到存不进的组织 | 03 8.6 节：前端带当前页面路径，后端按该页面的读权限收窄 | 1.5 |
| 2-2 | 单据链收口 | 范围外节点的数量、物料被视为敏感 | 根节点不可见时返回 404；enricher 没补到详情的节点隐藏数量和物料，标为"无权查看"（03 7.4 节） | 0.5–1 |
| 2-3 | 导出范围快照 | 范围受限的主管需要下载他人的导出文件 | 03 5.3、8.7 节：创建时记快照，下载时比较覆盖 | 1 |
| 2-4 | 批量写反馈 | 用户因"静默跳过"产生困惑 | 03 8.4 节：条数不符即 403 | 1–1.5 |
| 2-5 | 参照配置"仅本页" | 各公司、各厂分别维护会计期间、成本政策、MRP 参数等 | 03 7.1 节的"仅本页"方式。MRP 参数有按租户的缓存，登记前要改为缓存全集、返回前过滤 | 1.5–2 |
| 2-6 | 公司银行账户 | 账户信息要求按公司隔离 | 登记为公司维度；出货对账单等工厂级打印改为按出货工厂所属公司取账户，不受当前范围限制 | 1 |
| 2-7 | "所属"与"含下级公司" | HR 维护指定清单的负担大；集团有多层公司 | 03 5.1、6.1 节；用户所属组织变更时驱逐权限缓存 | 1–1.5 |
| 2-8 | 行规则（本部门、本人） | 需要按部门或制单人限制 | 03 5.2、6.3 节与附录 D，扩展各实体过滤器的条件；含前端行规则列 | 4–5 |
| 2-9 | HR 按公司分级与管理范围上限 | 多名 HR 各管一个公司 | 03 9.2 节与 P1-b | 2–3 |
| 2-10 | 有效范围查询 | "为什么看不到"的排查工作量大 | 03 9.4 节 | 1.5 |
| 2-11 | 客户"本人业务员" | 销售团队提出要求 | 03 7.2 节 | 1 |
| 2-12 | 来源单据显式校验 | 4.7 节的核对中，发现无法用组织一致性解决的入口 | 03 8.5 节，逐个入口处理 | 每个 0.5 |

---

## 八、移出本设计的事项

下列事项原在 03 的 P1-0，与资料范围互不依赖，另行安排：

- 预置 `SYS_IT_ADMIN`、`SYS_HR_ADMIN`，租户初始化 SQL 模板，以及发版自动给 `SYS_IT_ADMIN` 补权的标准片段（03 5.5 节第 3 步、11.3 节）。
- 删除草稿表 `data_permissions`、`role_permission_delegations`、`role_hierarchy`，以及对应的实体和仓库类（03 5.5 节第 4 步）。
- 明细分页的 `putIfAbsent` 改为 `put`（27 个服务类）。明细经单头过滤后不会越出范围，这是语义修正。
- 02 文档勘误（03 1.2 节）。

---

## 九、工作量与排期

估算单位为人日，按一名熟悉代码的后端和一名前端计，只作排期参考。

**阶段 0（3–4，后端）**

| 任务 | 估算 |
|---|---|
| Testcontainers 基座、全量迁移、CI 测试工作流 | 1–1.5 |
| 过滤器行为验证与三个原型，确定绑定方式 | 1.5–2 |
| `@Modifying` 与"查不到就新建"复核 | 0.5 |

**阶段 1（17–19）**

| 任务 | 估算 |
|---|---|
| 表结构、迁移（回填、索引）、实体、授权明细加载与缓存 | 1.5–2 |
| 组织目录、范围求值、上下文、切面（权限串求值、模式判定） | 2.5 |
| 过滤器绑定落地 | 0.5–1 |
| 约 60 个实体登记、登记校验测试 | 2.5 |
| 单头写守卫、过账仓库校验、异常映射 | 1.5 |
| 导出、导入封口 | 1 |
| 组织下拉过滤 | 0.5 |
| 指派范围 API 与校验 | 1.5 |
| 参照建单"新建类"入口核对 | 0.5 |
| 集成测试矩阵 | 2.5–3 |
| 前端：范围编辑器、摘要列、批量指派、i18n | 3 |

后端是关键路径，阶段 0 加阶段 1 约 4 周；前端在阶段 1 开始后并行。作为对比，03 的 P1-0 加 P1-a 是 24–30 人日。

---

## 十、风险与对策

| 风险 | 影响 | 对策 |
|---|---|---|
| 过滤器在按键加载、多对一关联、连接查询中的行为与预期不同 | 页面报错或漏数 | 阶段 0 先验证；集成测试矩阵覆盖 |
| 某些 EntityManager 没有启用过滤器 | 范围外的数据被读出；写入只剩写守卫一层 | 绑定覆盖五种情形；矩阵包含 `REQUIRES_NEW` 与异步导出 |
| 工厂级页面读取公司级资料 | 只有工厂范围的人，在出货、工厂订单、MRP 页面看不到订单号，打印缺内容 | 这些岗位同时设公司范围；界面摘要明确显示"公司级单据：无"；试点阶段验证 |
| 批量写先按请求 ID 处理子表 | 误改范围外单据的子表 | 子表登记到单头路径；复核 `@Modifying` |
| 并集比单个页面的范围宽 | 多角色用户在下拉、辅助接口看到更多 | 上限是本人范围；需要时做阶段 2-1 |
| 新指派忘记设范围 | 用户看不到数据 | 预填所属公司；醒目提示"无资料范围"；指派列表显示摘要 |
| 性能下降 | 列表变慢 | "全部"时不加条件；补索引；压测 |
| 缓存滞后 | 改范围后最长 10 分钟才生效 | 指派变更时整体驱逐（现有）；单实例部署；多实例前改分布式缓存 |
| 已知残留：单据链节点结构、跨维度引用来源、参照配置不受控 | 有限的暴露 | 本文已写明；按阶段 2 的触发条件处理 |

---

## 十一、待确认事项

下面几点是业务取舍，都给了默认建议；有不同意见再调整。

| # | 问题 | 默认建议 |
|---|---|---|
| 1 | MVP 不隔离参照配置和公司银行账户 | 接受，行为与现在相同；有需求时做 2-5、2-6 |
| 2 | 只有工厂范围的人能否看公司级单据（销售订单、财务单据） | 不能（同 03）。需要引用销售订单的工厂岗位，指派时同时设公司范围 |
| 3 | WM 单据的仓库限制 | 单据按工厂可见，盘点单按仓库可见；库存台账和过账按仓库 |
| 4 | 他人导出文件的下载 | 只允许创建者和范围为"全部"的人 |
| 5 | 单据链的残留暴露 | 接受，到阶段 2-2 再处理 |
| 6 | MRP 全厂运行（工厂为空） | 有工厂范围的人可见；只有工厂维度为"全部"的人能新建、修改、删除 |
| 7 | 新指派的默认范围 | 预填被指派人的所属公司，保存前确认 |

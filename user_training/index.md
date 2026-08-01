# Lychee ERP 用户教育训练文档

> 编写日期：2026-08-01  
> 状态：**骨架已建立，中文内容逐步填充中**  
> 语言策略：**仅维护中文（zh）与越南文（vi）两套**；先完成中文，再同步越南文

## 目标

面向终端用户与关键管理员，提供可课堂讲授、可自学跟练的操作文档。  
与 [`system_design/`](../system_design/)（研发设计）、`lychee-backend/docs/`（schema / 实现计划）分离：**本文档只讲「谁、何时、点哪里、结果怎样」**。

## 如何浏览（VitePress）

在仓库根目录 `lychee-doc` 执行：

```bash
pnpm install
pnpm docs:dev
```

然后打开本地站点，从 [训练首页](./) 或站点导航「用户训练」进入。正式环境将部署构建产物（见仓库根 [`README.md`](../README.md)）。

## 语言与版本同步

| 约定 | 说明 |
|------|------|
| 主语言 | 中文，目录 [`zh/`](./zh/) |
| 第二语言 | 越南文，目录 [`vi/`](./vi/)，中文稳定后再翻译 |
| 不维护 | 英文用户手册（系统界面三语文案仍可保留 en） |
| 同步规则 | 以中文为源；改中文后必须在 PR / 变更记录中标注「待同步 vi」；vi 文件路径与 zh 一一对应 |
| 术语 | 统一见 [`glossary.md`](./glossary.md)；缩写（SO/PO/GR 等）两语共用 |

写作规范与截图约定见 [`00-conventions.md`](./00-conventions.md)。

## 文档分层

| 层级 | 目录 | 用途 |
|------|------|------|
| L0 总纲 | 本文件 + 约定 + 术语表 | 训练计划、索引、语言策略 |
| L0.5 整体流程 | `zh/00-overview/` | 跨模块业务全景、价值链概念图（不写逐步点击） |
| 入门 | `zh/01-getting-started/` | 登录、界面、导出中心 |
| L1 角色手册 | `zh/02-roles/` | 按岗位一天怎么干活 |
| L2 流程剧本 | `zh/03-process-playbooks/` | 端到端场景（主战场） |
| 速查 | `zh/04-module-quickref/` | 模块入口、状态、禁忌（薄文档） |
| 运维开通 | `zh/05-admin-ops/` | 菜单/权限/导出等上线配置 |

建议阅读顺序：**总纲 → 入门（登录）→ 整体流程 → 角色手册 → 流程剧本**。

## 角色矩阵（训练分班参考）

| 角色 | 主要模块 | 概念（OV） | 优先剧本 |
|------|----------|------------|----------|
| 全体 | — | OV-01 | 系统入门 |
| 系统管理员 | ADM | OV-01 | 权限与菜单开通 |
| 主数据维护 | BASIS / MM / SD 客户 / SCM 供应商 | OV-01 | PB-01 |
| 销售 | SD | OV-02 | PB-02 |
| 采购 | SCM | OV-03 | PB-03、PB-06 |
| 仓储 | WM | OV-03、OV-05 | PB-03、PB-05 |
| 生产计划 | PP | OV-04 | PB-04 |
| 财务 | FI | OV-03、OV-05 | PB-03、PB-05 |

## 优先流程剧本（中文优先完成顺序）

| 编号 | 文档 | 场景 |
|------|------|------|
| PB-01 | [主数据就绪](./zh/03-process-playbooks/PB-01-master-data-ready.md) | 公司/工厂/物料/客户/供应商就绪 |
| PB-02 | [销售出货](./zh/03-process-playbooks/PB-02-sales-to-delivery.md) | SO → DN |
| PB-03 | [采购入库与应付](./zh/03-process-playbooks/PB-03-procure-to-pay.md) | PR → PO → GR → AP |
| PB-04 | [计划到生产回馈](./zh/03-process-playbooks/PB-04-mrp-to-production.md) | BOM → FO → MRP → PLO → MO → MOR |
| PB-05 | [库存与财务关账](./zh/03-process-playbooks/PB-05-period-close.md) | 库存期末 ↔ 成本结算 / 会计期间 |
| PB-06 | [导出与打印](./zh/03-process-playbooks/PB-06-export-and-print.md) | 供应商 Excel、订购单打印 / PDF、导出中心 |

## 中文文档索引

### 整体流程

- [本节索引](./zh/00-overview/)
- [OV-01 系统整体流程地图](./zh/00-overview/01-system-process-map.md)
- [OV-02 销货闭环（概念）](./zh/00-overview/02-order-to-cash.md)
- [OV-03 采购闭环（概念）](./zh/00-overview/03-procure-to-pay.md)
- [OV-04 计划生产（概念）](./zh/00-overview/04-plan-to-produce.md)
- [OV-05 关账协作（概念）](./zh/00-overview/05-period-close-collaboration.md)

### 入门

- [系统入门](./zh/01-getting-started/01-system-overview.md)
- [导出中心使用说明](./zh/01-getting-started/02-export-center.md)

### 角色手册

- [系统管理员](./zh/02-roles/role-admin.md)
- [主数据维护](./zh/02-roles/role-master-data.md)
- [销售](./zh/02-roles/role-sales.md)
- [采购](./zh/02-roles/role-procurement.md)
- [仓储](./zh/02-roles/role-warehouse.md)
- [生产计划](./zh/02-roles/role-production.md)
- [财务](./zh/02-roles/role-finance.md)

### 模块速查

- [模块速查索引](./zh/04-module-quickref/)

### 运维开通

- [菜单与权限开通](./zh/05-admin-ops/01-menu-and-permission.md)
- [导出功能上线检查清单](./zh/05-admin-ops/02-export-go-live-checklist.md)

## 越南文

见 [`vi/`](./vi/)。目录结构与 `zh/` 镜像；当前为占位，待中文剧本试讲稳定后启动翻译。

## 资产

截图统一放在 [`assets/screenshots/`](./assets/screenshots/)，按模块分子目录；规范见约定文档。

## 进度约定

1. 课堂第 0 节使用 **OV-01** 建立全景；专篇 OV-02～05 作预习/串讲。  
2. 先填满 **PB-01～PB-06** 中文剧本并可在训练环境走通。  
3. 再补齐角色手册与模块速查。  
4. 中文试讲一轮后冻结术语表，启动 `vi/` 同步（含 `vi/00-overview/` 镜像）。  
5. 新功能以「增量训练包」形式追加剧本，同步更新本索引与 OV 总图（若影响主价值链）。

# 多租户运行栈

本目录描述 Lychee 的部署怎么随租户变多。部署单位是 **栈**：一台 ECS 上的一套 Compose（Postgres、Keycloak、backend、frontend、nginx）。同一份镜像可以进任意栈，差别只在该机的 `.env` 和证书目录。

两个彼此独立的选择：

| 轴 | 取值 | 含义 |
|----|------|------|
| 环境 | `prod` / `test` / `demo` | 数据是正式业务、待发布版本，还是对外演示 |
| 放置 | `dedicated` / `shared` | 这一台机器只服务一个大租户，还是多个小租户共用 |

```text
现在                                  本波要加                        以后有小租户再加
khh-prod（已有，大租户）               khh-test（大租户测试）           shared-prod
  khh.lycheetech.com（入口兼 issuer）    khh-test.lycheetech.com         {标签}.lycheetech.com
                                     demo（演示，共用形态）            auth.lycheetech.com（issuer）
                                       demo.lycheetech.com           shared-test
                                       auth-demo.lycheetech.com      {标签}-test.lycheetech.com
                                                                     auth-test.lycheetech.com

lycheetech.com：产品介绍与帮助站，不属于任何栈。khh-prod 切换当天停用它的 ERP 入口，不做跳转。
```

khh 保持独立库、独立 Keycloak、独立 OSS。演示和小租户不进 khh 的机器。小租户正式、测试各准备一台共用栈，本波不购买。

数据库以现有库重新生成 Liquibase 基线，空库可以直接建出来；新租户由开通函数从模板租户复制系统配置。各栈的 Keycloak 库互不复制，khh-test 只从正式恢复业务库。

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | 现网就是 khh 正式栈；没有测试和演示；空库建不起来，新租户没有配置来源 |
| [02-目标架构.md](./02-目标架构.md) | 栈、大小租户、演示、域名、发布、数据边界 |
| [03-环境契约.md](./03-环境契约.md) | `.env`、生成脚本、Nginx、Keycloak、备份恢复、OSS 权限、CI |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：本波做数据库基线、khh-test、demo 和 khh-prod 切换；共用栈只留契约 |
| [05-khh正式issuer切换.md](./05-khh正式issuer切换.md) | 先行步骤：正式 issuer 改到 `khh.lycheetech.com/oidc` |
| [06-数据库基线与租户开通.md](./06-数据库基线与租户开通.md) | Liquibase 重新基线、模板租户、开通函数、增量规则 |

相关实现（设计时点）：

- 编排：`lychee-infra/deploy/docker-compose.yml`
- 反代：`lychee-infra/deploy/docker/nginx/conf.d/default.conf`
- 数据库初始化：`lychee-infra/deploy/docker/postgres/init.sql`
- 备份与恢复：`lychee-infra/backup/scripts/`
- 后端部署配置：`lychee-erp/src/main/resources/application-prod.yaml`
- Liquibase：`lychee-erp/src/main/resources/db/changelog/`
- 前端运行时配置：`lychee-frontend/docker-entrypoint.sh`、`config/env.config.ts`、`src/services/auth/config.ts`
- 发布：`lychee-backend/.github/workflows/deploy.yml`、`lychee-frontend/.github/workflows/deploy.yml`
- 日志：[`../20260819-logging-sjs/SLS.md`](../20260819-logging-sjs/SLS.md)（Project `lychee-prod`，即 khh 正式栈）

# 07. 测试栈共用正式 Keycloak

> 变更日期：2026-11-20。**状态：设计。** 未开工。
> 修订 [02](./02-目标架构.md) 里「每栈一个 Keycloak、测试栈自有 issuer」，以及 [03](./03-环境契约.md) §8、§9 的测试账号对应。
> 2026-11-20：认证地址只由 `ISSUER_HOST` 决定，脚本不设配对表。本机起不起 Keycloak、起不起 `pdf`，由 `COMPOSE_PROFILES` 决定，不再设 `ISSUER_MODE`。02 里「把这一对写进配对表」改为只改该测试栈的 `.env`。
> 同日补充：`COMPOSE_FILE` 写入 `.env`；`COMPOSE_PROFILES` 不允许空白。补上 `khh-test` 的切换顺序、4GB 内存账、备份恢复和 Nginx 模板。

测试栈不运行、不管理 Keycloak。`ISSUER_HOST` 填写配对正式栈的 issuer 主机：用户、口令、realm、签名密钥都在那一台 Keycloak 里。业务库、OSS bucket、CDN、备份前缀仍按栈分开。测试机不持有正式 bucket 的密钥。

各栈共用一份 `docker-compose.yml`，不按栈复制。`postgres`、`backend`、`frontend`、`nginx` 每次都启动。`keycloak` 与 `pdf` 是 Compose profile，起不起写在该机 `.env` 的 `COMPOSE_PROFILES`。脚本不按 `STACK_ID` 拒绝某个 issuer，也不按主机内存拒绝某组 profile。

`khh-test` 实际未使用。PDF 容器限额默认 `1536m`。测试机若再跑本机 Keycloak（默认 `768m`），约 4GB 的主机余量不够。先落这一对，以后的测试栈同样不把 `keycloak` 写入 `COMPOSE_PROFILES`，不再单独做 Keycloak 开通。

## 1. 谁跑 Keycloak

| 栈 | `COMPOSE_PROFILES` | issuer |
|----|--------------------|--------|
| 正式栈（`khh-prod`，以后的 `shared-prod`、`{标签}-prod`） | 含 `keycloak`。主机能同时放下 `pdf` 时再加 `pdf` | 该栈自己的 `ISSUER_HOST` |
| 测试栈（`khh-test`，以后的 `shared-test`、`{标签}-test`） | 含 `pdf`，不含 `keycloak` | `.env` 里的 `ISSUER_HOST`，填写配对正式栈 |
| `demo` | `keycloak`。4GB 上不含 `pdf` | `https://auth-demo.lycheetech.com/oidc` |

现在要写入的 issuer：

| 栈 | `ISSUER_HOST` | 何时 |
|----|---------------|------|
| `khh-test` | `khh.lycheetech.com` | 本篇实施 |
| `shared-test` | `auth.lycheetech.com` | 建共用栈时。不另设 `auth-test.lycheetech.com` |
| `{标签}-test` | 该正式栈的用户 Host | 大租户再拆出独享栈时 |
| `demo` | `auth-demo.lycheetech.com` | 本机 Keycloak，realm `demo` |

现在这三台：

| 栈 | 主机 | `COMPOSE_PROFILES` |
|----|------|--------------------|
| `khh-prod` | 约 8GB 之前 | `keycloak` |
| `khh-prod` | 约 8GB 之后 | `keycloak,pdf` |
| `khh-test` | 维持约 4GB | `pdf` |
| `demo` | 维持约 4GB | `keycloak` |

`khh-test.lycheetech.com` 只做用户入口，不提供 `/oidc/`。

## 2. 登录

以 `khh-test` 为例。其他不含 `keycloak` profile 的栈相同：realm 仍由当前页面的 Host 决定，登录跳到 `ISSUER_HOST`。

1. `TENANT_HOSTS` 把 `khh-test.lycheetech.com` 解成 realm `kimhiephoa`。
2. `KEYCLOAK_URL` 为 `https://khh.lycheetech.com/oidc`。前端跳到该 Keycloak，回调 `https://khh-test.lycheetech.com/auth/callback`，登出回到 `https://khh-test.lycheetech.com`。
3. token 的 `iss` 是 `https://khh.lycheetech.com/oidc/realms/kimhiephoa`，`sub` 是该 Keycloak 的用户 ID。
4. 测试机的 backend 用同一个 `KEYCLOAK_URL` 验签，再用本机业务库的 `users.idp_user_id` 对上 `sub`。

前端认证代码不改。`redirectUri` 继续用 `window.location.origin`。用户 Host 与 issuer 都在 `lycheetech.com` 下，会话检查 iframe 与现有约定相同。

正式 realm 的 client `lychee-erp-web` 在正式站登记之外，加上要登录该 realm 的其他 Host。`kimhiephoa` 这一次加上：

| 项 | 值 |
|----|----|
| 合法重定向 | `https://khh-test.lycheetech.com/auth/callback` |
| 登出回跳 | `https://khh-test.lycheetech.com` |
| Web Origin | `https://khh-test.lycheetech.com` |

共用栈以后同样：realm 只建在跑着 Keycloak 的那一台。该 realm 的 client 登记这个租户的正式 Host 和测试 Host。测试栈不导入 realm、不复制用户。

`KC_HOSTNAME` 留在 `COMPOSE_PROFILES` 含 `keycloak` 的机器上。不含 `keycloak` 的机器，Nginx 不反代 `/oidc/`。

同一把 token 被 issuer、client、`sub` 都相同的 backend 接受。测试站登录得到的 token 拿去调该正式站的 API 同样通过。口令、停用、重置都改 `ISSUER_HOST` 上的那一个用户。那台 Keycloak 停机时，把 `ISSUER_HOST` 指到它的栈一起无法登录。

同一个浏览器同时打开正式站和测试站时，两边共用这一台 Keycloak 的会话。前端 `monitorSession` 发现会话被登出后会跳转登录。在测试站退出，正式站已打开的页面会跟着跳到登录页，未保存的表单会丢失。本篇仍用一个 client `lychee-erp-web`。以后若要按 `azp` 隔开两台站的 token，可在同一 realm 另建 public client，backend 已按 `KEYCLOAK_CLIENT_ID` 校验 `azp`，本篇不改。

从测试站打开个人中心时，账号页在正式 issuer 上，并带上测试站的 `appHome`。`kimhiephoa` 是存量 realm，Account theme 须已是 `lychee`，页眉返回链接才回到 `appHome`。仍是默认主题时，链接回到正式站。Keycloak 的 `+` 只从带路径的合法重定向推导登出回跳，盖不住站点根路径，所以登出回跳要显式写上正式站和测试站的根地址。

脚本不核对此处的 `STACK_ID` 与 `ISSUER_HOST`。`ISSUER_HOST` 写成另一台 Keycloak 时，配置仍会生成。登录要那台 Keycloak 的 client 已登记本机 Host 的回调，并且该主机的 DNS 指向正在运行的 Keycloak。

## 3. 配置

`COMPOSE_PROFILES` 这个键必须存在，值可以为空。空值表示不起 `keycloak` 和 `pdf`。非空时只允许 `keycloak`、`pdf`、`keycloak,pdf`、`pdf,keycloak`，不含空格或制表符。含空白的值直接失败，不先 trim 再接受。Compose 按逗号切开后不会去掉名字前的空格，`" pdf"` 会被静默忽略，服务不起、部署仍成功。重复的名字同样失败。

解析放在 `deploy/read-env.sh`，供 `render-stack-config.sh`、`deploy-service.sh`、`restore_from_oss.sh`、`backup_to_oss.sh` 调用。各脚本不再各自切这串名字。

`COMPOSE_FILE` 也写在 `.env`，各栈相同，值只能是 `docker-compose.yml:docker-compose.issuer.yml`。缺失或值不同则 `render-stack-config.sh` 失败。Compose 从项目目录的 `.env` 读取这个键，手工执行 `docker compose` 不用再 export。不改用 `docker-compose.override.yml`：覆盖文件还不存在时，Compose 仍只读主文件，`extra_hosts` 会静默丢掉，backend 访问本机 issuer 会走公网回环，验签失败后 API 全部 401。`COMPOSE_FILE` 指向尚未生成的文件时，Compose 直接失败。

`khh-test` 在约 4GB 上的 `deploy/.env`：

```text
STACK_ID=khh-test
STACK_PLACEMENT=dedicated
LYCHEE_ENV=test
TENANT_HOSTS=khh-test.lycheetech.com=kimhiephoa
ISSUER_HOST=khh.lycheetech.com
COMPOSE_PROFILES=pdf
COMPOSE_FILE=docker-compose.yml:docker-compose.issuer.yml
PDF_MEM_LIMIT=1024m
```

`khh-prod` 约 8GB 之前 `COMPOSE_PROFILES=keycloak`，升配并完成 §6 的 `pdf` 发布后写成 `keycloak,pdf`。`demo` 在 4GB 上写成 `keycloak`，`ISSUER_HOST=auth-demo.lycheetech.com`。这两台不覆盖内存限额，用 §4 的缺省。三台都写同一个 `COMPOSE_FILE`。`khh-test` 只把 `pdf` 收到 `1024m`，backend 仍用缺省 `1g`。

`KEYCLOAK_URL` 仍由 `ISSUER_HOST` 推出，公式不变。名单不含 `keycloak` 时本机没有 Keycloak 进程，公式只用于 backend 和 frontend。

名单含 `keycloak` 时，脚本行为与现在的本机签发相同：

- 独享栈的 `ISSUER_HOST` 必须是 `TENANT_HOSTS` 里的一个 Host。
- 共用栈的 issuer 在 `TENANT_HOSTS` 之外，并写进 Nginx 的 `server_name`。
- `location /oidc/` 反代到 `lychee-keycloak`。
- backend 加 `extra_hosts`，让容器经本机访问 issuer。

名单不含 `keycloak` 时：

- `ISSUER_HOST` 不得等于本机 `TENANT_HOSTS` 里的任何一个 Host。这个名字的 DNS 指着本机，同时本机又不提供 `/oidc/`，指到这里的登录会一起失败。脚本在这里失败退出。
- 不再要求独享栈的 `ISSUER_HOST` 出现在本机 `TENANT_HOSTS` 里。
- `ISSUER_HOST` 不写进 Nginx 的 `server_name`。本机不认这台 issuer 的 Host。
- `location /oidc/` 返回 404。
- 不给 backend 加 `extra_hosts`。容器按公网 DNS 访问 `ISSUER_HOST` 拉 JWKS。正式机安全组已经放行 443。

`render-stack-config.sh` 写出 `deploy/docker-compose.issuer.yml`（不入库，与 `stack.conf` 一样）。`.gitignore` 增加这一路径。名单含 `keycloak` 时，主机名取该机的 `ISSUER_HOST`：

```yaml
services:
  backend:
    extra_hosts:
      - "khh.lycheetech.com:host-gateway"
```

名单不含 `keycloak` 时，文件内容是：

```yaml
services: {}
```

不写空文件，也不写值为空的 `extra_hosts:`。后者在 Compose v2 里是 null，校验会失败。主 `docker-compose.yml` 去掉写死的 `extra_hosts`。

仓库里的脚本调用 `docker compose` 时不另传 `-f docker-compose.yml`。单独的 `-f` 会盖过 `.env` 里的 `COMPOSE_FILE`，backend 再次丢掉 `extra_hosts`。`restore_from_oss.sh` 的 `compose()` 只保留 `--project-directory`。

## 4. 编排

`docker-compose.yml` 仍是一份。`keycloak` 加上 `profiles: [keycloak]`，`pdf` 加上 `profiles: [pdf]`。`postgres`、`backend`、`frontend`、`nginx` 不写 `profiles`。

`backend` 和 `nginx` 去掉 `depends_on: keycloak`。profile 未开启时，依赖一个未启用的服务会让 Compose 直接失败。

Compose 从 `deploy/.env` 读取 `COMPOSE_PROFILES`。`docker compose up -d` 不带服务名时，只启动无 profile 的服务和名单里的 profile。`khh-test` 因此跳过 Keycloak、拉起 `pdf`。`demo` 拉起 Keycloak、跳过 `pdf`。

在命令行点名服务会临时打开该服务的 profile。`deploy-service.sh` 发布 `pdf` 时，若 `COMPOSE_PROFILES` 不含 `pdf`，在 `render-stack-config.sh` 成功之后、拉取镜像和改写 `.env` 标签之前退出，并写明名单不含 `pdf`。手工 `docker compose up -d keycloak` 或 `docker compose up -d pdf` 也会绕过名单，不作为启动方式。

`khh-test` 上已有的 `lychee-keycloak` 容器用 `docker rm -f lychee-keycloak` 删除，不只是 stop。停着的容器以后被 start 会重新占用 768m，并对外提供一套已经不用的 Keycloak。`docker compose up -d` 不会替这份名单停掉已经在跑、但不在当前 profile 里的旧容器。keycloak 库和数据目录留在测试机，本次不删。Postgres 仍创建 `keycloak` 角色和库。Compose 先对整份文件做插值，再按 profile 过滤，因此 `KC_DB_PASSWORD`、`PDF_IMAGE`、`PDF_TAG`、`LYCHEE_PDF_TOKEN` 等键留在 `.env`，名单不含对应 profile 时也要有。`PDF_TAG=00000000` 能通过插值，但不是可以拉取的标签。以后新建的测试栈沿用同一份初始化脚本，库可以照旧创建，只是没有进程使用。

`/oidc/admin/` 与 master realm 的管理入口只留在 `COMPOSE_PROFILES` 含 `keycloak` 的机器上，并且只经 SSH 隧道。现仓 `stack.conf.template` 里这两处 `return 404` 和 `docker-compose.yml` 里的 `KC_HOSTNAME_ADMIN` 都还注释着。实施时在含 `keycloak` 的生成结果里恢复：`KC_HOSTNAME_ADMIN=http://127.0.0.1:8080/oidc`，Nginx 对 `/oidc/admin/` 与 `/oidc/realms/master/` 返回 404，其余 `/oidc/` 反代到 Keycloak。不含 `keycloak` 时整个 `location /oidc/` 为 404。模板要有这一个分支，不能把反代写死。

内存限额用变量，缺省就是现在的数。要改的栈在 `.env` 覆盖。`JAVA_OPTS_APPEND` 与 `JAVA_TOOL_OPTIONS` 仍是 `MaxRAMPercentage=70.0`，随 cgroup 限额变化。Postgres 不设上限。

```yaml
mem_limit: ${KEYCLOAK_MEM_LIMIT:-768m}
mem_limit: ${BACKEND_MEM_LIMIT:-1g}
mem_limit: ${FRONTEND_MEM_LIMIT:-64m}
mem_limit: ${NGINX_MEM_LIMIT:-64m}
mem_limit: ${PDF_MEM_LIMIT:-1536m}
```

`pdf` 的 `shm_size: 256m` 仍写死，计在 `pdf` 的 `mem_limit` 之内。文件头的注释改为：各栈是否启动 `pdf` 看 `COMPOSE_PROFILES`，不再要求三台都升到约 8GB 才部署这份 compose。

## 5. 业务库备份与恢复

`backup_to_oss.sh` 现在固定导出 `lychee_erp` 和 `keycloak`。`COMPOSE_PROFILES` 不含 `keycloak` 时只导出 `lychee_erp`。测试机上留着的 keycloak 库不再每天上传。含 `keycloak` 时两库都导出。

`--from-prod` 仍只允许 `khh-test` 恢复 `lychee_erp_` 业务库。任何栈都拒绝把 keycloak 备份恢复到另一栈。

`COMPOSE_PROFILES` 不含 `keycloak` 时：

- 传了 `--idp-map` 就失败退出，不静默忽略，也不出现「将改写 `users.idp_user_id`」的确认文案。
- 对象键指向 `keycloak_` 备份时失败退出，不执行 `compose stop/start keycloak`。
- `--from-prod` 恢复业务库后不改写 `users.idp_user_id`，也不导出映射。备份里的 ID 就是 `ISSUER_HOST` 那台 Keycloak 的 `sub`。`LYCHEE_PLATFORM_ADMINS` 写那台 Keycloak 的用户 ID，格式仍是 `<realm>:<用户 ID>`。

若测试库已经被旧脚本改写成另一套 ID，再做一次 `--from-prod` 恢复，让 ID 回到该 Keycloak 的用户。

以后的测试栈若从它的 `ISSUER_HOST` 所在正式栈恢复业务库，同样跳过改写。不把一家正式库恢复进另一家测试栈或 `demo`。

`restore_from_oss.sh` 的 `compose()` 按 §3 去掉单独的 `-f`。

## 6. 内存与上线顺序

`bootstrap-ecs.sh` 在每台机器上另起 `loongcollector`，限额 `256m`，不在 `docker-compose.yml` 里。4GB 规格的 ECS，Linux 可见内存大约 3.7–3.8 GiB。内核与 `dockerd`、`containerd` 大约再占 250–350 MiB。

按缺省限额把 `pdf` 和业务容器加在一起是 `2688m`，再加 `loongcollector` 的 `256m` 是 `2944m`。留给 Postgres 和页缓存大约只剩 500–600 MiB。`khh-test` 维持约 4GB 时不用 `pdf` 的缺省值，按 §3 写成 `PDF_MEM_LIMIT=1024m`，backend 仍为 `1g`：

| 服务 | mem_limit |
|------|-----------|
| `pdf` | `1024m` |
| `backend` | `1g` |
| `frontend` | `64m` |
| `nginx` | `64m` |
| `loongcollector` | `256m` |
| 合计 | `2432m` |

这样大约还剩 1 GiB 给操作系统和 Postgres。大的 PDF 可能先碰到 `1024m` 的容器上限。出现容器被杀或主机杀进程时，把 `khh-test` 升配，不要把 `keycloak` 和 `pdf` 写进同一个 `COMPOSE_PROFILES`。脚本不检查这组名字与主机内存。

带 profile 的这份 compose 可以部署到每一台。新旧 `render-stack-config.sh` 对 `khh-test` 的 `ISSUER_HOST` 不能同时通过：合入前不能改成正式 issuer，合入后也不能带着 `khh-test.lycheetech.com` 去跑新脚本。

合入 infra `main` 之前，现有脚本要求独享栈的 `ISSUER_HOST` 属于 `TENANT_HOSTS`。`khh-test` 若先改成 `khh.lycheetech.com`，合入前的前后端自动发布会失败。合入之后，新脚本在名单不含 `keycloak` 时又要求 `ISSUER_HOST` 不属于 `TENANT_HOSTS`。只先写 `COMPOSE_PROFILES=pdf`、留下 `ISSUER_HOST=khh-test.lycheetech.com`，合入后的自动发布同样失败。`deploy-service.sh backend` 只重建 backend，不重建 frontend，`env-config.js` 里的 `KEYCLOAK_URL` 不会变。

`khh-prod` 和 `demo` 可以在合入前把 `COMPOSE_PROFILES` 写成 `keycloak`。旧脚本不读这个键，`ISSUER_HOST` 仍在本机 `TENANT_HOSTS` 里，两边都通过。`COMPOSE_FILE` 先不要写。写上之后、生成文件还不存在时，任何 `docker compose` 都会失败。

`khh-test` 在 infra `main` 合入后、下一次自动发布改到容器之前，在机器上一次做完：

1. 取到含本篇的 infra `main`。
2. 改 `.env`：`ISSUER_HOST=khh.lycheetech.com`，`COMPOSE_PROFILES=pdf`，`COMPOSE_FILE=docker-compose.yml:docker-compose.issuer.yml`，以及 `PDF_MEM_LIMIT=1024m`。
3. 执行 `render-stack-config.sh`。
4. `docker rm -f lychee-keycloak`。
5. 在 `deploy/` 执行不带服务名的 `docker compose up -d`，同时重建 backend、frontend、nginx。

若自动发布抢先跑了新脚本，缺少新键或 `ISSUER_HOST` 仍是 `khh-test.lycheetech.com` 时，`render-stack-config.sh` 失败，运行中的容器保持不变。接着按上面五步做完。

`khh-prod` 约 8GB 之前保持 `COMPOSE_PROFILES=keycloak`。`PDF_TAG` 仍可以是占位 `00000000`，profile 未打开时不会拉取。升配后：

1. 把 `COMPOSE_PROFILES` 改为 `keycloak,pdf`。
2. 先执行一次 `deploy-service.sh pdf <真实的 8 位标签>`。它在 `render-stack-config.sh` 成功之后、拉取镜像和改写 `PDF_TAG` 之前检查名单；名单含 `pdf` 才继续，并把真实标签写入 `.env`。
3. 再执行不带服务名的 `docker compose up -d`。

跳过第 2 步直接整栈启动，会去拉 `:00000000` 并失败。`demo` 在 4GB 上保持 `COMPOSE_PROFILES=keycloak`，不发布 `pdf`。

`lychee-pdf` 的部署工作流在调用 `deploy-service.sh` 之前已经 `git reset --hard origin/main`。拒绝发布 `pdf` 的判断用的是这份新脚本，失败信息写明名单不含 `pdf`。

## 7. 实施清单

- [ ] 正式 realm `kimhiephoa` 的 client `lychee-erp-web` 登记测试站的回调、登出和 Web Origin。登出回跳显式包含 `https://khh.lycheetech.com` 与 `https://khh-test.lycheetech.com`，不用 `+` 代替根路径。Account theme 确认为 `lychee`。以后每加一个要登录该 realm 的 Host，只在这台 Keycloak 的 client 上登记对应三项，并核对登出回跳是该 Host 的根地址。
- [ ] `.env.example` 增加 `COMPOSE_PROFILES` 与 `COMPOSE_FILE` 的说明。`COMPOSE_PROFILES` 键必须存在，值可以为空，不允许空白字符，名字只能是 `keycloak`、`pdf`。`COMPOSE_FILE` 固定为 `docker-compose.yml:docker-compose.issuer.yml`。列出可选的 `KEYCLOAK_MEM_LIMIT`、`BACKEND_MEM_LIMIT`、`FRONTEND_MEM_LIMIT`、`NGINX_MEM_LIMIT`、`PDF_MEM_LIMIT`。不增加 `ISSUER_MODE`，不写配对表。`khh-test` 的 `.env` 写成 §3。`khh-prod`、`demo` 按 §1 与 §6 写 `COMPOSE_PROFILES`。
- [ ] `.gitignore` 增加 `deploy/docker-compose.issuer.yml`。
- [ ] `read-env.sh` 提供 `COMPOSE_PROFILES` 的解析，按 §3 拒绝空白、未知名字和重复。`render-stack-config.sh`、`deploy-service.sh`、`restore_from_oss.sh`、`backup_to_oss.sh` 都调用它。
- [ ] `render-stack-config.sh`：校验 `COMPOSE_FILE`。含 `keycloak` 时沿用本机签发的放置校验，issuer 进 `server_name`，`/oidc/` 反代，写出带 `extra_hosts` 的 `docker-compose.issuer.yml`。不含 `keycloak` 时，`ISSUER_HOST` 不得出现在本机 `TENANT_HOSTS`，issuer 不进 `server_name`，`/oidc/` 为 404，生成文件为 `services: {}`。不核 `STACK_ID` 与 `ISSUER_HOST` 的组合。
- [ ] `docker/nginx/stack.conf.template`：`/oidc/` 能按上面两种结果生成。含 `keycloak` 时恢复 `/oidc/admin/` 与 `/oidc/realms/master/` 的 404。
- [ ] `docker-compose.yml`：`keycloak` 使用 profile `keycloak`，`pdf` 使用 profile `pdf`；去掉 backend、nginx 对 keycloak 的 `depends_on`；去掉写死的 `extra_hosts`；`mem_limit` 改为 §4 的变量；恢复 `KC_HOSTNAME_ADMIN`；改掉文件头「三台都升到约 8GB 才部署」的注释。
- [ ] `deploy-service.sh` 不设置 `COMPOSE_FILE`，也不传单独的 `-f`。发布 `pdf` 时，若名单不含 `pdf`，在 `render-stack-config.sh` 成功之后、拉取镜像和改写标签之前退出，并写明名单不含 `pdf`。
- [ ] `backup_to_oss.sh`：名单不含 `keycloak` 时只备份 `lychee_erp`。
- [ ] `restore_from_oss.sh`：`compose()` 去掉单独的 `-f`。名单不含 `keycloak` 时，`--idp-map` 失败退出，确认文案不写 IdP 改写，并拒绝 `keycloak_` 备份。`--from-prod` 不改写 `users.idp_user_id`。
- [ ] `lychee-infra/README.md`：`khh-test` 的 issuer 改为 `khh.lycheetech.com`，不再写测试栈自带 issuer，也不再把 `--idp-map` 写成恢复后的必要步骤。删掉「三台升到约 8GB 之前不要部署带 `pdf` 的 compose」。启动步骤改为先 `render-stack-config.sh`，再依靠 `.env` 里的 `COMPOSE_FILE` 执行 `docker compose up -d`。
- [ ] 按 §6 切换 `khh-test`：删除 `lychee-keycloak`，整栈 `docker compose up -d`。确认 `https://khh-test.lycheetech.com/oidc/` 为 404，登录跳到 `khh.lycheetech.com` 后回到测试站，同一用户能打开测试库里的数据。个人中心的返回链接回到测试站。
- [ ] 用该用户的 token 调一次正式站 API，确认会通过。这是 §2 的边界，用来核对而不是要修掉。同一浏览器先登录两边，再在测试站退出，确认正式站会跳到登录页。
- [ ] `khh-prod` 未到约 8GB、`demo` 仍是 4GB 时，`COMPOSE_PROFILES` 不含 `pdf`。`khh-prod` 升配后按 §6 先发布 `pdf` 标签，再整栈启动。

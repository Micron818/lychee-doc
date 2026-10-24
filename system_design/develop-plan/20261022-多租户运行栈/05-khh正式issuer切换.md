# 05. khh 正式 issuer 切换

> 先于 [04-实施清单.md](./04-实施清单.md) 的其余改造，只在现网 khh 正式栈执行。  
> 不新建测试机或演示栈，不改镜像、Nginx 配置、业务库和 OSS。  
> 本步骤之后 `lycheetech.com` 暂时仍是 ERP 入口。[04 §3.8](./04-实施清单.md) 切换当天停用它，不做跳转。

目标：Keycloak 对外地址从 `https://lycheetech.com/oidc` 改为 `https://khh.lycheetech.com/oidc`。

`lycheetech.com` 仍是 ERP 入口。用户从 `lycheetech.com` 或 `khh.lycheetech.com` 打开页面，登录跳到 `khh.lycheetech.com/oidc`，回调回到打开时的那个 Host。租户代码仍是 `kimhiephoa`。切换后已打开的页面需要重新登录。管理控制台从 [https://lycheetech.com/oidc](https://lycheetech.com/oidc) 改为 `https://khh.lycheetech.com/oidc`。

issuer 由服务器 `deploy/.env` 注入：

| 变量 | 新值 | 用在 |
|------|------|------|
| `KC_HOSTNAME` | `https://khh.lycheetech.com/oidc` | Keycloak |
| `KEYCLOAK_URL` | `https://khh.lycheetech.com/oidc` | backend 的 `issuer-base-uris`，frontend 的 `env-config.js` |
| `DOMAIN_NAME` | `khh.lycheetech.com` | backend 的 `extra_hosts`，让容器解析 issuer 主机 |

`KC_HTTP_RELATIVE_PATH=/oidc`、`API_BASE_URL`、`KEYCLOAK_REALM` 保持不变。`.env` 被 git 忽略，不要提交。

Nginx 两个 Host 已经把 `/oidc/` 转到 Keycloak，这次不改 `default.conf`。`proxy_pass` 使用静态容器名，Nginx 只在启动或 reload 时解析 IP。重建 `keycloak`、`backend`、`frontend` 后必须 `nginx -s reload`，否则会继续连旧 IP。

---

## 1. 执行

在正式机 `/home/deployer/lychee/lychee-infra/deploy`。

1. 打开 `https://khh.lycheetech.com/oidc/realms/kimhiephoa/.well-known/openid-configuration`。切换前 `issuer` 应为 `https://lycheetech.com/oidc/realms/kimhiephoa`。确认 client `lychee-erp-web` 的重定向、登出回跳、Web Origin 已包含 `https://lycheetech.com` 与 `https://khh.lycheetech.com`。
2. 同时修改 `.env` 的 `KC_HOSTNAME`、`KEYCLOAK_URL`、`DOMAIN_NAME` 为上表。路径不要写成 `/oidc/oidc`。
3. 重建三个容器，再让 Nginx 重新解析容器 IP：

```bash
docker compose up -d keycloak backend frontend
docker compose exec nginx nginx -s reload
```

使用 `up -d`，不要只 `restart`。`restart` 不会换上新的 `extra_hosts`，前端入口脚本也不会重写 `env-config.js`。`nginx -s reload` 在 `up -d` 返回且三个容器已接入 `lychee-net` 之后执行。Keycloak 进程可能仍在启动；reload 解决的是旧 IP，不必为了等 Keycloak 再重启 Nginx。

4. 再读 discovery。`issuer` 必须是 `https://khh.lycheetech.com/oidc/realms/kimhiephoa`。backend 日志中不能出现 issuer 不匹配或公钥拉取失败。
5. 在 `https://khh.lycheetech.com/oidc` 把 realm `kimhiephoa` 的会话全部登出，使旧 refresh token 失效。
6. 用 `https://lycheetech.com` 与 `https://khh.lycheetech.com` 各登录一次。登录页在 `khh.lycheetech.com`，回调回到打开时的 Host，登录后接口正常。切换前已打开的页面应要求重新登录。
7. 打开 `https://lycheetech.com/oidc` 应进入新 issuer。Keycloak 按 `KC_HOSTNAME` 跳转。

---

## 2. 回退

把 `KC_HOSTNAME`、`KEYCLOAK_URL` 改回 `https://lycheetech.com/oidc`，`DOMAIN_NAME` 改回 `lycheetech.com`，然后：

```bash
docker compose up -d keycloak backend frontend
docker compose exec nginx nginx -s reload
```

用户再登录一次。

---

## 3. 与后续发布的关系

之后的 `main` 部署会 `git reset --hard origin/main` 并重建业务容器，不会覆盖被忽略的 `.env`。这次 issuer 会保留。那些发布若重建 `backend` 或 `frontend`，同样要在完成后对 Nginx 执行 `nginx -s reload`。

[04 §3.8](./04-实施清单.md) 之后：

- `.env` 的 `KC_HOSTNAME`、`KEYCLOAK_URL`、`DOMAIN_NAME` 由 `ISSUER_HOST=khh.lycheetech.com` 取代，三处地址由 Compose 推出。
- Nginx 在运行时解析容器地址，重建业务容器后不再需要 reload。
- client `lychee-erp-web` 删除 `https://lycheetech.com` 的重定向、登出回跳与 Web Origin。
- 管理台不再从公网打开，改经 SSH 隧道进入 `http://127.0.0.1:8080/oidc/admin/`（[03 §8](./03-环境契约.md)「管理入口」）。

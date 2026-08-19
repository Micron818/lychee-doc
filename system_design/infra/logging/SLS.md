# 应用日志：阿里云 SLS

> 目标：用户汇报 `traceId` 后，开发在 SLS 控制台按 ID 查出该请求全部日志，**不必 SSH 登录 AP 主机**。  
> 状态：**已在生产验证通过**（LoongCollector Docker 采集 `lychee-backend` stdout）。

## 1. 推荐方式

**SLS + LoongCollector 以 Docker 容器安装，采集 Compose 服务 `backend` 的 stdout。**  
应用零改动，AccessKey 不进业务容器。不要在 Spring 中接 SLS SDK / Logback Appender。


| 方式                               | 结论      |
| -------------------------------- | ------- |
| LoongCollector Docker（官方推荐，本期采用） | **采用**  |
| Spring 直写 SLS                    | **不采用** |
| Docker `aliyun` logging driver   | **不采用** |
| 自建 Loki / ELK                    | **不采用** |


生产 **不要** 开启 datasource-proxy SQL 日志（`decorator.datasource.enabled` 保持 `false`）。

后端已将请求级 `traceId`（26 位 ULID）写入 MDC，日志样例如下：

```text
2026-08-19T14:03:32.096+07:00  WARN [01M0CDA4D4HYCH63FFVN6VJ2CP] 1 --- [lychee-erp-api] [nio-9000-exec-3] c.l.e.a.e.GlobalExceptionHandler         : ConflictException: validation.material.delete.blocked.by.bom
```

同一请求：响应体 `traceId`、响应头 `X-Trace-Id`、所有 `log.*` 共用该 ID。

## 2. 架构

```text
浏览器 / 前端
    │  错误页或响应头 X-Trace-Id
    ▼
Compose 服务 backend（容器名 lychee-backend，stdout 带 [traceId]）
    │  Docker json-file
    ▼
LoongCollector 容器（挂载 docker.sock + 主机根目录只读）
    ▼
SLS Project lychee-prod / Logstore lychee-backend
    ▼
查询：traceId: <用户给的 ID>；正文在字段 content
```

业务编排仍是 `deploy/docker-compose.yml`，**不要**把 LoongCollector 写进该 Compose。主机 `docker logs lychee-backend` 仅作兜底。

## 3. 已落地资源


| 项              | 值                           |
| -------------- | --------------------------- |
| 地域             | `ap-southeast-1`（须与 ECS 一致） |
| Project        | `lychee-prod`               |
| Logstore       | `lychee-backend`            |
| Logtail 配置名    | `lychee-backend`            |
| 机器组 / 用户自定义 ID | `lychee-prod-app`           |


容器过滤用的是 Compose **自动标签**，不是 `container_name` Label（该 Label 不存在）：


| Docker 属性                          | 值                | SLS 用法                            |
| ---------------------------------- | ---------------- | --------------------------------- |
| `container_name`                   | `lychee-backend` | 容器 **Name**，本期不用                  |
| Label `com.docker.compose.service` | `backend`        | **采用**（对应 compose 服务名 `backend:`） |


## 4. 安装 LoongCollector（Docker）

在运行业务 Compose 的 **同一台 ECS** 上执行。将 `ALIYUN_LOGTAIL_USER_ID` 换成阿里云主账号 ID。

```bash
docker run -d \
    --name loongcollector \
    --restart always \
    -v /:/logtail_host:ro \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --env ALIYUN_LOGTAIL_CONFIG=/etc/ilogtail/conf/ap-southeast-1/ilogtail_config.json \
    --env ALIYUN_LOGTAIL_USER_ID=<阿里云账号ID> \
    --env ALIYUN_LOGTAIL_USER_DEFINED_ID=lychee-prod-app \
    aliyun-observability-release-registry.ap-southeast-1.cr.aliyuncs.com/loongcollector/loongcollector:v3.3.3.0-f44ebb3-aliyun
```

说明：

- 镜像地域与 SLS Project 一致（新加坡）。
- `ALIYUN_LOGTAIL_USER_DEFINED_ID` 必须与 SLS 机器组标识 `lychee-prod-app` 相同。
- `/:/logtail_host:ro` 与 `docker.sock` 为官方 Docker 安装所需挂载，用于读容器 stdout。
- `--restart always`：采集器应按基础设施常驻。崩溃、Docker 守护进程重启、主机 reboot 后都会拉起；这与阿里云 LoongCollector Docker 安装说明一致。`unless-stopped` 在有人 `docker stop` 后，reboot 也不会再起来，排障时容易漏采。需要临时停采集用 `docker stop loongcollector` 即可，当前会话内不会立刻被拉起；reboot 后会再启动（这是 `always` 与 `unless-stopped` 的差别）。

SLS：机器组类型选 **用户自定义标识**，标识填 `lychee-prod-app`。

## 5. Logtail 配置

数据接入类型：**多行-文本日志**；输入：**Docker 标准输出**（`service_docker_stdout`）。  
不要选「主机文本文件」，也不要按 `/var/lib/docker/containers/<哈希>/` 填路径。

配置名 `lychee-backend`，机器组 `lychee-prod-app`，目标 Logstore `lychee-backend`：

```json
{
    "aggregators": [],
    "global": {},
    "inputs": [
        {
            "Type": "service_docker_stdout",
            "Stdout": true,
            "Stderr": false,
            "BeginLineRegex": "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}",
            "BeginLineTimeoutMs": 3000,
            "BeginLineCheckLength": 10240,
            "IncludeLabel": {
                "com.docker.compose.service": "backend"
            }
        }
    ],
    "processors": [
        {
            "Type": "processor_regex",
            "FullMatch": false,
            "SourceKey": "content",
            "Regex": "\\[(?<traceId>[0-9A-HJKMNP-TV-Z]{26})\\]",
            "Keys": [
                "traceId"
            ],
            "KeepSource": true,
            "KeepSourceIfParseError": true,
            "NoKeyError": false,
            "NoMatchError": false
        }
    ]
}
```

要点：

- `IncludeLabel` 只采 Compose 服务 `backend`，不会带上 postgres / nginx / keycloak / frontend。
- `BeginLineRegex` 把异常堆栈并进同一条（行首为 ISO 时间戳）。
- `KeepSource: true`：**必须保留**，否则只有 `traceId`、看不到 stdout 正文。
- 正文在字段 `**content**`；`_source_` 仅为 `stdout`/`stderr`，不是日志内容。
- 启动阶段没有 `[ULID]` 的行会触发 `NoMatchError`（不丢 `content`）。需要时可将 `NoMatchError` 改为 `false` 减少采集器告警。

Logstore 索引：开启全文索引；字段 `traceId` 类型 **text**（processor 已写出该字段）。

## 6. 查询

1. 控制台：[SLS](https://sls.console.aliyun.com/) → Project `lychee-prod` → Logstore `lychee-backend`。
2. 视图用 **原始日志**，或 SQL 选出 `content`（索引字段 JSON 里可能只看到 `traceId`、容器元数据）。
3. 查询：

```text
traceId: 01M0CDA4D4HYCH63FFVN6VJ2CP
```

```text
traceId: 01M0CDA4D4HYCH63FFVN6VJ2CP
| SELECT content, traceId, _container_name_
```

全文兜底：

```text
"01M0CDA4D4HYCH63FFVN6VJ2CP"
```

`content` 应与 `docker logs lychee-backend` 中对应行一致。

## 7. 开发权限（RAM）

开发 **不要** 开通 ECS SSH。RAM 用户只授该 Project 只读。  
可用 `AliyunLogReadOnlyAccess`；收紧时：

```json
{
  "Version": "1",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "log:ListProject",
        "log:GetProject",
        "log:ListLogStore",
        "log:GetLogStore",
        "log:GetLogStoreLogs",
        "log:GetHistograms",
        "log:GetIndex",
        "log:GetLogging"
      ],
      "Resource": [
        "acs:log:*:*:project/lychee-prod",
        "acs:log:*:*:project/lychee-prod/*"
      ]
    }
  ]
}
```

## 8. 明确不做

- **不要** 在 Spring 中增加 SLS Appender 或 SDK。
- **不要** 把生产 SQL（datasource-proxy）打进 SLS。
- **不要** 把 Postgres / Nginx / Keycloak 与应用日志混在同一 Logstore。
- **不要** 用 Label `container_name` 过滤（不存在该标签）。
- **不要** 按容器哈希目录做文件采集（重建后 ID 会变）。

## 9. 后续可选

- 生产关掉 ANSI 颜色（`spring.output.ansi.enabled`），避免干扰行首正则。
- Nginx access 单独 Logstore。
- 对 `ERROR` 做告警。


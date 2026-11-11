# 主站

Lychee 对外站点，基于 VitePress。只构建本目录。仓库上一级的 `system_design/` 是研发设计，不在这里编译，也不发布。

## 目录

| 路径 | 说明 |
|------|------|
| [`intro/`](./intro/) | 系统介绍 |
| [`user_training/`](./user_training/) | 用户训练（中文为源，`vi/` 为镜像） |
| [`.vitepress/`](./.vitepress/) | VitePress 配置 |

站点页面使用 `index.md`。`README.md` 与 `user_training/00-conventions.md` 只在仓库里阅读，已从构建中排除。

## 本地预览

```bash
cd lychee-doc/site
pnpm install
pnpm docs:dev
```

| 命令 | 说明 |
|------|------|
| `pnpm docs:dev` | 本地预览 |
| `pnpm docs:build` | 构建到 `.vitepress/dist` |
| `pnpm docs:preview` | 预览构建产物 |

## 发布

`.github/workflows/site.yml` 在拉取请求里只构建。合并到 `main` 且改动了 `site/` 时，把 `.vitepress/dist` 同步到产品站。系统设计文档不在产物里。

## 语言

- 用户训练只维护中文与越南文
- 中文为源；`user_training/vi` 与 `zh` 路径一一对应
- 不维护英文用户手册

# Lychee Doc

Lychee ERP 文档仓库：用户教育训练 + 系统设计。  
浏览站点基于 **VitePress**（SSG）。

## 目录

| 路径 | 说明 |
|------|------|
| [`user_training/`](./user_training/) | 用户训练（中文源，越南文后续同步） |
| [`system_design/`](./system_design/) | 系统设计（研发向） |
| [`.vitepress/`](./.vitepress/) | VitePress 配置 |

> 各目录站点首页文件必须命名为 **`index.md`**（不是 `README.md`）。VitePress 只会把 `index.md` 映射为 `/path/`。

## 本地浏览（推荐给培训师）

```bash
cd lychee-doc
pnpm install
pnpm docs:dev
```

浏览器打开终端提示的本地地址（默认 `http://localhost:5173/`）。

| 命令 | 说明 |
|------|------|
| `pnpm docs:dev` | 本地开发预览（热更新） |
| `pnpm docs:build` | 构建静态站点到 `.vitepress/dist` |
| `pnpm docs:preview` | 预览构建产物 |

若使用 npm：`npm install` / `npm run docs:dev`。

## 部署

1. CI 或本机执行 `pnpm docs:build`
2. 将 `.vitepress/dist` 发布到 Nginx 静态目录或 OSS
3. 建议独立域名或路径，例如 `https://docs.example.com/` 或 `/training/`

## 语言策略

- 用户训练仅维护 **中文（zh）** 与 **越南文（vi）**
- 中文为源；`user_training/vi` 与 `zh` 路径镜像同步
- 不维护英文用户手册

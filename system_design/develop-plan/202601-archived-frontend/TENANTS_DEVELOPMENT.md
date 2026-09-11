# Lychee ERP - Tenants 模組開發指南

## 📋 專案概述

這是一個基於 React + Ant Design Pro + UmiJS 的 ERP 前端專案，已實現租戶（Tenants）管理模組。

## 🚀 快速開始

### 環境要求
- Node.js >= 20.0.0
- pnpm (推薦) 或 npm

### 安裝依賴
```bash
pnpm install
```

### 啟動開發服務器
```bash
# 方式1: 使用腳本
scripts/start-dev.bat

# 方式2: 直接命令
pnpm run start:dev
```

### 訪問地址
- 前端應用: http://localhost:8000
- 後端API: http://localhost:9000
- API文檔: http://localhost:9000/v3/api-docs

## 🏗️ 專案結構

```
src/
├── pages/admin/tenants/          # 租戶管理頁面
│   ├── index.tsx                # 主頁面
│   └── components/
│       └── TenantForm.tsx       # 租戶表單組件
├── services/tenants/            # 租戶API服務
│   ├── index.ts
│   └── tenantsService.ts
├── services/auth/               # 認證服務
└── components/                  # 共用組件
```

## 🔧 已實現功能

### 租戶管理
- ✅ 租戶列表查詢（分頁、搜索、篩選）
- ✅ 新建租戶
- ✅ 編輯租戶
- ✅ 刪除租戶（單個/批量）
- ✅ 狀態管理（啟用/停用）

### 菜單管理
- ✅ 菜單列表查詢（分頁、搜索、篩選）
- ✅ 新建菜單
- ✅ 編輯菜單
- ✅ 刪除菜單（單個/批量）

### 技術特性
- ✅ OIDC 認證集成
- ✅ Token 自動注入
- ✅ 響應攔截器
- ✅ 權限控制
- ✅ 代理配置
- ✅ OpenAPI 自動生成

## 📡 API 接口

### 租戶相關接口
- `GET /api/tenants` - 獲取租戶列表
- `GET /api/tenants/:id` - 獲取租戶詳情
- `POST /api/tenants` - 創建租戶
- `PUT /api/tenants/:id` - 更新租戶
- `DELETE /api/tenants/:id` - 刪除租戶
- `DELETE /api/tenants/batch` - 批量刪除租戶

### 菜單相關接口
- `POST /api/v1/menu/page` - 獲取菜單列表
- `POST /api/v1/menu` - 創建菜單
- `PUT /api/v1/menu/:id` - 更新菜單
- `POST /api/v1/menu/bulk-delete` - 批量刪除菜單

### 數據模型
```typescript
interface Tenant {
  id?: string;
  name: string;           // 租戶名稱
  code: string;           // 租戶代碼
  description?: string;   // 描述
  status: 'ACTIVE' | 'INACTIVE';  // 狀態
  createdAt?: string;
  updatedAt?: string;
}
```

## 🔐 認證配置

專案已集成 OIDC 認證，配置位於：
- `src/services/auth/config.ts` - 認證配置
- `src/services/auth/authService.ts` - 認證服務
- `src/requestConfig.ts` - 請求攔截器

## 🛠️ 開發指南

### 添加新的API接口
1. 在 `src/services/tenants/tenantsService.ts` 中添加新的API函數
2. 在對應的頁面組件中使用

### 添加新的頁面
1. 在 `src/pages/` 下創建頁面組件
2. 在 `config/routes.ts` 中添加路由配置
3. 更新權限配置（如需要）

### 自定義組件
1. 在 `src/components/` 下創建共用組件
2. 在 `src/components/index.ts` 中導出

## 🧪 測試

```bash
# 運行測試
pnpm test

# 測試覆蓋率
pnpm run test:coverage

# 類型檢查
pnpm run type-check
```

## 📦 構建部署

```bash
# 開發環境構建
pnpm run build:dev

# 測試環境構建
pnpm run build:test

# 生產環境構建
pnpm run build:prod
```

## 🔍 故障排除

### 常見問題
1. **API請求失敗**: 檢查後端服務是否啟動（http://localhost:9000）
2. **認證失敗**: 檢查 Keycloak 配置
3. **代理問題**: 檢查 `config/proxy.ts` 配置

### 調試工具
- 瀏覽器開發者工具
- React DevTools
- Network 面板查看API請求

## 📚 相關文檔
- [Ant Design Pro 文檔](https://pro.ant.design/)
- [UmiJS 文檔](https://umijs.org/)
- [Ant Design 組件庫](https://ant.design/)

## 🤝 貢獻指南
1. Fork 專案
2. 創建功能分支
3. 提交更改
4. 推送到分支
5. 創建 Pull Request

# 頁面開發指南

本指南旨在標準化新頁面的開發流程，以系統管理中的 **菜單管理** 為例。

## 開發步驟

開發一個新的資源管理頁面（如菜單管理）主要包含以下步驟：

### 1. 建立 Service 層

Service 層負責與後端 API 進行數據交互。

-   **路徑**: `src/services/system/menu`

#### a. 定義數據模型 (`model.ts`)

在 `src/services/system/menu/model.ts` 文件中，根據 `docs/openapi.json` 的定義，建立 TypeScript 類型。

例如，菜單 (`Menu`) 和菜單分頁請求 (`MenuPageRequest`) 的類型。

```typescript
// src/services/system/menu/model.ts

import { PageRequest } from '../../common/api.typings';

export interface Menu {
  id: number;
  name: string;
  code: string;
  locale?: string;
  parentId?: number;
  path?: string;
  component?: string;
  icon?: string;
  route?: string;
  sortOrder?: number;
  isVisible?: boolean;
  statusOptionId?: number;
  // ... 其他從 openapi.json 中得到的審計字段
  createdAt: string;
  updatedAt: string;
  createdByName: string;
  updatedByName: string;
}

export interface MenuRequest extends Omit<Menu, 'id' | 'createdAt' | 'updatedAt' | 'createdByName' | 'updatedByName'> {}

export type MenuPageRequest = PageRequest<Partial<Menu>>;

```

#### b. 撰寫 API 請求 (`api.ts`)

在 `src/services/system/menu/api.ts` 中，實現與後端 API 端點對應的請求函數。通常使用 `request` 庫。

-   `getMenuPage`: 獲取菜單分頁列表
-   `createMenu`: 新增菜單
-   `updateMenu`: 更新菜單
-   `deleteMenuBulk`: 批量刪除菜單

```typescript
// src/services/system/menu/api.ts
import { request } from '@umijs/max';
import { Menu, MenuRequest, MenuPageRequest } from './model';
import { PageResponse } from '../../common/api.typings';

const API_PREFIX = '/api/v1/menu';

export async function getMenuPage(params: MenuPageRequest) {
  return request<PageResponse<Menu>>(`${API_PREFIX}/page`, {
    method: 'POST',
    data: params,
  });
}

export async function createMenu(data: MenuRequest) {
  return request<Menu>(API_PREFIX, {
    method: 'POST',
    data,
  });
}

// ... 其他 API 函數
```

#### c. 導出模塊 (`index.ts`)

在 `src/services/system/menu/index.ts` 中，導出 `api.ts` 和 `model.ts` 的所有內容。

```typescript
// src/services/system/menu/index.ts
export * from './api';
export * from './model';
```

### 2. 建立 Page 層

Page 層是使用者操作的介面。

-   **路徑**: `src/pages/system/menu`

#### a. 頁面主組件 (`index.tsx`)

`src/pages/system/menu/index.tsx` 是頁面的入口。通常使用 `@ant-design/pro-table` 來快速搭建帶有查詢、表格和分頁功能的頁面。

-   使用 `useRef` 創建 `ActionType` 來操作表格。
-   使用 `useState` 管理模態框（如新增/編輯）的顯示狀態。
-   實現數據請求、新增、編輯和刪除的邏輯。

#### b. 表格列定義 (`columns/index.tsx`)

將 ProTable 的 `columns` 定義抽離到 `src/pages/system/menu/columns/index.tsx` 文件中，使主組件更簡潔。

-   定義各數據字段的展示方式。
-   定義操作列，包含編輯和刪除按鈕，並綁定相應事件。

#### c. 編輯/新增表單 (`components/CreateForm.tsx`)

創建 `src/pages/system/menu/components/CreateForm.tsx` 組件，用於新增和編輯菜單。

-   使用 `ProForm` 相關組件構建表單。
-   接收 `onCancel` 和 `onSubmit` 回調函數來處理表單的關閉和提交。
-   在編輯模式下，使用 `initialValues` 屬性回填表單數據。

### 3. 路由和菜單配置

1.  在 `config/routes.ts` 中添加新頁面的路由配置。
2.  (如果菜單是動態加載的) 在數據庫中添加對應的菜單項，確保用戶登入後可以看到並訪問該頁面。

遵循以上步驟，可以快速、標準化地完成一個新的管理頁面的開發。

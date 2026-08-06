# ERP系统Layout布局指南

本文档旨在为后续AI开发人员提供Lychee ERP系统的布局规范和指导原则。

## 1. 整体布局结构

系统采用Ant Design ProComponents提供的混合布局（mix layout）模式，包含以下几个主要部分：

1. 顶部导航栏（Header）
2. 侧边菜单栏（Sider）
3. 内容区域（Content）
4. 底部区域（Footer）

### 1.1 布局配置

系统布局配置位于 `config/defaultSettings.ts` 文件中：

- `navTheme`: light（浅色主题）
- `colorPrimary`: #1890ff（拂晓蓝主色调）
- `layout`: mix（混合布局）
- `contentWidth`: Fluid（流式宽度）
- `fixedHeader`: false（不固定头部）
- `fixSiderbar`: true（固定侧边栏）
- `title`: Lychee ERP（系统标题）

### 1.2 页面容器

所有页面内容应使用 `PageContainer` 组件包装，该组件提供了统一的页面间距和基础样式。

```tsx
import { PageContainer } from '@ant-design/pro-components';

const MyPage: React.FC = () => {
  return (
    <PageContainer>
      {/* 页面内容 */}
    </PageContainer>
  );
};
```

## 2. 导航和路由

### 2.1 路由配置

系统路由配置位于 `config/routes.ts`，采用集中式配置管理。

主要路由包括：
- `/dashboard`: 系统仪表板
- `/admin`: 管理模块，包含子路由
  - `/admin/tenants`: 租户管理
  - `/admin/options`: 选项管理
- `/auth/callback`: 认证回调页面
- 异常页面路由：/403、/500、/404

### 2.2 菜单结构

菜单结构根据路由配置自动生成，通过 `name` 和 `icon` 字段定义菜单项的显示文本和图标。

## 3. 头部区域

### 3.1 用户信息

右上角显示当前登录用户信息，包含用户名和下拉菜单。

功能包括：

- 个人中心（跳转到认证服务器账户页面）
- 退出登录

### 3.2 国际化

头部右侧提供语言切换功能。

## 4. 内容区域

### 4.1 页面结构

所有业务页面必须使用 `PageContainer` 包装，确保统一的外观和体验。

### 4.2 表格页面布局

针对不同类型的表格页面，推荐以下布局方式：

#### 4.2.1 单表格（5个字段以下）

- 使用 `EditableProTable` 展示数据并支持行内编辑
- 操作按钮放置在表格工具栏
- 支持多行同时编辑和批量保存

#### 4.2.2 单表格（超过5个字段）

- 使用 `ProTable` 展示关键字段
- 提供详情查看功能（可使用 `ProDescriptions`）
- 新增/编辑使用 `Drawer` 形式维护数据

#### 4.2.3 主明细表

- 上方展示主表，下方展示明细表
- 可使用 `ProCard` 进行区域划分
- 主表选择行时加载对应明细数据
- 明细表优先使用 `EditableProTable` 支持行内编辑

#### 4.2.4 主-明细-明细表

- 主表在上方，两个明细表在下方使用Tabs切换
- 使用 `ProCard` 和 `Tabs` 组件进行布局管理
- 明细表优先使用 `EditableProTable` 或 `Drawer` 方式维护

#### 4.2.5 复杂多表关系

- 根据业务逻辑合理安排布局
- 使用 `Tabs`、`Steps` 或折叠面板等方式管理多个表格
- 考虑拆分为多个页面并通过导航关联
- 各表格根据字段数量选择合适的编辑方式

## 5. 底部区域

底部区域显示版权信息："2025 Lychee Inc."

## 6. 响应式设计

布局已内置响应式支持，能够在不同设备尺寸下自动调整：

- 大屏幕：完整展示侧边栏和内容
- 中等屏幕：折叠侧边栏
- 小屏幕：隐藏侧边栏，通过按钮展开

## 7. 主题和样式

### 7.1 主题定制

通过 `defaultSettings.ts` 配置主题颜色和布局模式。

### 7.2 样式扩展

全局样式定义在 `src/global.style.ts` 文件中，可根据需要添加自定义样式。

## 8. 开发建议

1. 所有页面组件应导出为默认组件（export default）
2. 使用TypeScript进行类型检查
3. 遵循现有代码风格和命名规范
4. 充分利用ProComponents提供的高级组件
5. 对于复杂的交互逻辑，建议拆分成独立组件

## 9. Service调用

### 9.1 查询操作（R）
- 在ProTable或EditableProTable的request属性中直接调用service方法
- 使用分页和搜索参数进行数据查询
- 示例：
  ```typescript
  <ProTable
    request={getTenantsPage}
  />
  ```

### 9.2 增删改操作（CUD）
- 使用useRequest Hook封装CRUD操作
- 为每个操作设置成功和失败的回调处理
- 示例：
  ```typescript
  // 删除操作
  const { run: delRun, loading: deleteLoading } = useRequest(deleteTenant, {
    manual: true,
    onSuccess: () => {
      messageApi.success('删除成功');
      actionRef.current?.reloadAndRest?.();
    },
    onError: () => {
      messageApi.error('删除失败，请重试');
    },
  });
  ```

### 9.4 错误处理
- 为所有service调用提供统一的错误处理机制
- 在onError回调中显示用户友好的错误信息

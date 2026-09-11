# ProTable 多列排序 (Multiple Sorter) 踩坑与解决方案记录

在使用 `@ant-design/pro-table` 时，如果尝试使用多列排序（即配置 `sorter: { multiple: x }`），会遇到两个底层的已知缺陷。本文档记录了这两个问题的根本原因及相应的解决方案。

## 问题一：配置 `multiple` 后，点击表头不触发 `request`，且查询时 `sort` 参数为空 `{}`

### 🔍 现象描述
当把某列的 `sorter: true` 改为 `sorter: { multiple: 1 }` 后，点击表头排序时，表格不会重新发起请求（不触发 `request`）。同时，点击查询按钮时，`request` 接收到的 `sort` 参数始终为 `{}`。

### 🐞 根本原因
在 `@ant-design/pro-table` 的底层源码 (`es/Table.js`) 中，有一个内部变量 `useLocaleSorter` 用于判断当前是**本地排序**还是**服务端排序**：
```javascript
var useLocaleSorter = useMemo(function () {
  var _columns = loopColumns(propsColumns);
  return _columns === null || _columns === void 0 ? void 0 : _columns.every(function (column) {
    return column.sorter !== true;
  });
}, [loopColumns, propsColumns]);
```
当所有开启排序的列都使用 `{ multiple: x }` 时，`column.sorter !== true` 的判断结果全部为 `true`。这导致 ProTable 误以为当前使用的是**本地排序**，从而在内部拦截了 `onSortChange` 事件，阻止了 `proSort` 状态的更新和 `request` 的触发。

### 💡 解决方案
在 `columns` 定义中，塞入一个隐藏的“幽灵列”，其 `sorter` 严格设置为 `true`，从而打破 `every` 循环的条件，强制开启服务端排序：

```tsx
export const getColumns = (): ProColumns<any>[] => {
  return [
    // --- 增加一个隐藏的幽灵列，专门用来绕过 ProTable 的本地排序误判 ---
    {
      title: 'dummy',
      dataIndex: 'dummy',
      hideInTable: true,
      hideInSearch: true,
      hideInForm: true,
      hideInSetting: true,
      sorter: true, // 关键：只要有任何一列是严格的 true，就能强制开启服务端排序
    },
    // --------------------------------------------------------
    // ... 其他正常列
    {
      title: 'Factory',
      dataIndex: 'factoryId',
      sorter: { multiple: 1 },
    }
  ];
};
```

---

## 问题二：绕过问题一后，多列排序的优先级 (`multiple`) 失效

### 🔍 现象描述
在使用了“幽灵列”成功触发 `request` 后，对配置了 `multiple: 1` 和 `multiple: 2` 的多列进行排序时，发现 `request` 中接收到的 `sort` 参数并没有按照 `multiple` 指定的优先级排序，而是始终按照列在 `columns` 数组中定义的先后顺序来排序。

### 🐞 根本原因
在 `@ant-design/pro-table` 的源码 (`es/utils/genProColumnToColumn.js`) 中，它将 `ProColumns` 转换为底层 Ant Design `Table` 认识的 `columns` 时，存在状态传递丢失的 Bug：
```javascript
// ⚠️ 关键 Bug 在这里：它只在 sorter === true 时，才把受控的 sortOrder 传给底层的 Table！
sortOrder: sorter === true ? sortOrder : undefined,
```
当列配置为 `sorter: { multiple: 1 }` 时，`sorter === true` 为 `false`，导致传给底层 Ant Design `Table` 的 `sortOrder` 变成了 `undefined`。底层 `Table` 因此失去了受控状态，无法正确维护多个列的排序优先级，最终退化为按照列的自然顺序返回排序结果。

### 💡 解决方案
放弃依赖 ProTable 自动维护的 `sortOrder`，在组件外部通过 `useState` 手动维护排序状态，并将其强制注入到 `columns` 中，让底层 Ant Design `Table` 恢复完全受控模式。

```tsx
import { useState, useMemo } from 'react';
import { SortOrder } from 'antd/es/table/interface';

export default function MyTable() {
  // 1. 在组件内部定义排序状态
  const [sortState, setSortState] = useState<Record<string, SortOrder>>({});

  // 2. 修改 columns 的定义，手动传入 sortOrder
  const columns = useMemo(() => {
    const baseColumns = getColumns(); // 获取基础列配置
    
    // 遍历列，手动将 sortState 注入到 sortOrder 中
    return baseColumns.map(col => {
      if (col.sorter && typeof col.sorter === 'object' && 'multiple' in col.sorter) {
        const dataIndexStr = Array.isArray(col.dataIndex) ? col.dataIndex.join('.') : col.dataIndex as string;
        return {
          ...col,
          sortOrder: sortState[dataIndexStr] || null, // 强制注入受控的 sortOrder
        };
      }
      return col;
    });
  }, [sortState]); // 依赖项加入 sortState

  return (
    <ProTable
      columns={columns}
      request={async (params, sort, filter) => {
        // 3. 在 request 中更新排序状态
        setSortState(sort);
        
        // 处理默认排序等逻辑
        const finalSort = Object.keys(sort).length > 0 ? sort : { 'defaultField': 'ascend' };
        return fetchData(params, finalSort);
      }}
    />
  );
}
```

通过这种方式，底层 `Table` 的每一列都能获取到正确的 `sortOrder`，多列排序的 `multiple` 优先级逻辑就能正常生效并传递给 `request`。
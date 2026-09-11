# ProCard 嵌套 ProTable 时键盘左右键无法滚动的问题

## 问题描述
在使用 Ant Design Pro 的 `ProCard` 嵌套 `ProTable` 时，如果 `ProTable` 的列比较多出现了横向滚动条，默认情况下无法使用键盘的左右方向键（Left/Right Arrow）来控制表格的横向滚动。用户只能通过鼠标拖动滚动条来查看隐藏的列，这在数据录入或查看时体验不佳。

## 尝试过的方案

### 方案一：在 ProCard.TabPane 上设置 tabIndex 和 onKeyDown (失败)
最初尝试在 `ProCard.TabPane` 或 `ProCard` 上直接监听键盘事件：
```tsx
<ProCard.TabPane
  tabIndex={-1}
  style={{ outline: 'none' }}
>
  <ProTable />
</ProCard.TabPane>
```
**结果**：按键盘左右键时，整个 Tab 区域会出现焦点边框（即使设置了 `outline: 'none'`），且由于焦点不在表格内部，表格的横向滚动无法被触发。

### 方案二：在 ProTable 外层包裹 div (成功但有冗余)
在 `ProTable` 外层包裹一个带有 `tabIndex` 的 `div`，并在这个 `div` 上监听键盘事件：
```tsx
<div
  onKeyDown={handleTableKeyboardScrollV2}
  tabIndex={0}
  style={{ outline: 'none' }}
>
  <ProTable />
</div>
```
**结果**：可以正常工作，但增加了一层不必要的 DOM 结构。

## 最终解决方案

利用 `ProTable` 提供的 `cardProps` 属性，直接将焦点和键盘事件绑定到 `ProTable` 内部的卡片容器上。

### 1. 核心代码实现

```tsx
<ProTable
  // ... 其他属性
  cardProps={{
    tabIndex: 0,
    style: { 
      outline: 'none', 
      padding: 0, 
      backgroundColor: 'var(--ant-color-bg-container)' // 关键：覆盖默认的 focus 背景色
    },
    onKeyDown: handleTableKeyboardScrollV2,
  }}
/>
```

### 2. 键盘滚动处理函数 (`handleTableKeyboardScrollV2`)

```typescript
export const handleTableKeyboardScrollV2 = (e: React.KeyboardEvent<HTMLDivElement>) => {
  const target = e.target as HTMLElement;
  
  // 确保按下的是左右方向键
  if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
    // 找到当前焦点内的表格内容区域
    const tableContent = target.querySelector('.ant-table-body') || target.querySelector('.ant-table-content');
    
    if (tableContent) {
      e.preventDefault(); // 阻止默认的页面滚动行为
      // 根据方向键调整 scrollLeft，每次滚动 50px
      tableContent.scrollLeft += e.key === 'ArrowRight' ? 50 : -50;
    }
  }
};
```

## 注意事项与坑点

**淡绿色背景问题**：
当通过 `cardProps` 设置 `tabIndex: 0` 后，`ProTable` 的外层卡片变得可以获取焦点。Ant Design Pro 的 `.ant-pro-card:focus` 默认带有一个淡蓝/淡绿色的背景色（`rgb(230, 244, 255)`）。

当用户点击表格区域时，卡片获取焦点，整个表格背景会变成淡绿色，视觉体验很奇怪。

**修复方法**：
在 `cardProps.style` 中显式指定 `backgroundColor: 'var(--ant-color-bg-container)'`。这样既能利用主题变量适配暗黑/明亮模式，又能覆盖掉 `:focus` 状态下的默认背景色。
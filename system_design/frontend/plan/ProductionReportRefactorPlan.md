# 生产报工(Production Report) 前端重构执行计划

## 1. 目标与背景

当前生产报工单的“倒扣料明细”的生成和保存分为了多个割裂的步骤：先保存主单，再打开预览弹窗生成明细，勾选确认后再分别保存明细，这破坏了业务上的事务一致性。
后端 API 已经在 `ProductionReportRequest` 的 Payload 中引入了 `components` 字段，支持主单和明细一起传递并保持事务一致性提交。

本次重构旨在：
- **消除多步操作**：实现输入产量后自动计算倒扣料，并一键提交主单与明细。
- **界面优化**：把表单作用域提升，使其覆盖 `basic` 和 `items` 两个页签，使用 `EditableProTable` 替代原来的明细展示和弹窗。
- **保留业务灵活性**：在 `items` 页签中，用户可以对自动生成的缺料行进行干预、修改批次仓库，或添加/删除物料行。

## 2. 实施步骤

### 步骤 1: API 与 Model 层确认
1. 确认 `src/services/pp/production-report/model.ts` 中 `ProductionReportRequest` 已包含 `components?: ProductionReportComponentRequest[]` 字段。
2. 确认 `calculateBackflushComponents` 接口工作正常（在目前的预览功能中已验证）。

### 步骤 2: 重构 `ProductionReportForm` 结构，扩大 `ProForm` 作用域
1. 在 `src/pages/pp/production-reports/components/ProductionReportForm.tsx` 中。
2. 将 `ProForm` 的层级提升到 `ProCard` 之外。让它包裹住 `basic` 和 `items` 两个 TabPane。
3. 确保在创建态 (`!currentId`) 时，不再隐藏 `items` 页签，而是允许用户点击查看和编辑系统生成的倒冲料明细。

### 步骤 3: 监听数量变化并自动计算倒冲料
1. 在 `ProductionReportForm` 内使用 `Form.useWatch` 监听以下字段：
   - `productionOrderId`
   - `goodQuantity`
   - `scrapQuantity`
2. 引入 `ahooks` 的 `useDebounceEffect`。当上述三个字段有有效值发生改变时，自动触发 `calculateBackflushComponents` 请求。
3. 当数量改变时，无论新建还是编辑状态，都应自动重新计算并覆盖明细数据，以保证产量与物料耗用完全一致。请注意，当在编辑态保存时，后端逻辑会根据 `currentId` 先删除原有全部明细，然后按照最新传入的 `components` 重新写入。
4. 将获取到的明细数据通过 `formRef.current?.setFieldsValue({ components: data })` 写入表单数据中。

### 步骤 4: 在 `items` 页签集成 `EditableProTable`
1. 创建或直接在 `items` TabPane 中引入 `EditableProTable`，绑定表单字段 `name="components"`。
2. 配置列 (`columns`)：
   - 物料编码、物料名称（只读）。
   - 推荐仓库（可下拉选择，用于干预缺料）。
   - 推荐批次（可下拉选择或输入，用于干预缺料）。
   - 数量（可编辑）。
   - 备注。
3. 配置 `recordCreatorProps` 支持手工添加额外领料/替代料。
4. 确保行编辑态可以顺利同步回 Form 的 `components` 字段。

### 步骤 5: 修改提交逻辑并废弃旧组件
1. 修改 `ProductionReportForm` 的 `onFinish` 方法，直接提交 `values` (此时 `values` 中已包含完整的 `components` 数组)。
2. 原有的 `ProductionReportComponentList.tsx` 中的弹窗预览功能（`BackflushPreviewModal`）可以废弃，后续再删除文件。
3. 原有的独立添加/编辑明细的 `ProductionReportComponentForm.tsx` 也可以废弃，后续再删除文件。`items` 的编辑统一使用 `EditableProTable`，但应包含相关的检查和限制逻辑，具体规则在下阶段再进行设计和补充。如果是纯查看模式（非 Draft），则将 `EditableProTable` 设置为只读展示。

## 3. 风险与注意事项
- **自动触发的时机**：需要避免频繁请求，`useDebounceEffect` 延迟时间建议设为 500ms - 800ms。
- **编辑态的防覆盖**：如果用户打开一个已经保存过明细的草稿单据，不应在加载时随意触发覆盖计算，只有当用户**主动修改了数量**时，才提示并重新计算。
- **缺料提示**：在 `EditableProTable` 渲染时，对于缺少批次 (`batchNo` 为空) 且数量大于 0 的行，可以考虑通过红色字体或校验规则给予高亮，提醒用户处理。

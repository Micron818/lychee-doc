# AI Development Prompt: Create a New Resource Management Page

## Context
This prompt has been configured for the following resource:
- **Module**: `sd`
- **Entity**: `SalesOrder` (PascalCase)
- **Entity Var**: `salesOrder` (camelCase)
- **Entity Plural**: `salesOrders` (camelCase variable), `sales-orders` (kebab-case directory/URL)
- **Layout Type**: `MasterDetail`

---

## Objective
Create a complete resource management page for the `SalesOrder` entity, strictly following the project's architecture and existing patterns.

## Core Task
Follow established project patterns by referencing existing modules (like `tenant` service and `tenants` page) and the API definitions in `docs/openapi/api-sd.json`.

## Rules & Conventions
- **Directory Structure**: Services go in `src/services/sd/sales-order` (singular). Pages go in `src/pages/sd/sales-orders` (plural).
- **Imports**: Use `@/` alias for imports where possible.
- **Existing Code**: **Must NOT** delete or modify unrelated existing code.
- **Components**: Always wrap the page content in `PageContainer`.
- **State Management**: Use `useRequest` for async operations to manage loading states and error handling automatically.
- **Data Formatting**: Use `formatCodeName(code, name)` from `@/utils` when displaying "Code - Name" strings (e.g., in table columns, read-only fields, or Select options) to ensure consistent formatting and handle null/empty values gracefully.

---

### **Phase 1: Service Layer Creation**

1.  **Update Endpoints (`src/services/common/endpoints.ts`):**
    *   Add a new key `salesOrders` to the `endpoints` object with the following structure:
        ```typescript
        salesOrders: {
          base: `${API_PREFIX}/sales-orders`,
          page: `${API_PREFIX}/sales-orders/page`,
          detail: (id: Key) => `${API_PREFIX}/sales-orders/${id}`,
          bulkDelete: `${API_PREFIX}/sales-orders/bulk-delete`,
        }
        ```

2.  **Create Service Directory:**
    *   Create a new directory: `src/services/sd/sales-order` (Note: Singular directory name).

3.  **Define Data Models (`model.ts`):**
    *   In the new directory, create `model.ts`.
    *   **Imports**: `BaseEntity` from `@/services/common`.
    *   Define the `SalesOrder` interface based on the `SalesOrderResponseDTO` schema in `openapi/api-sd.json`. **Note**: This interface **MUST extend `BaseEntity`** and should not re-define common fields (id, createdAt, etc.).
    *   Define the `SalesOrderRequest` interface based on the `SalesOrderRequestDTO` schema in `openapi/api-sd.json`.


4.  **Implement API Functions (`api.ts`):**
    *   In the new directory, create `api.ts`.
    *   **Imports**:
        *   `request` from `@umijs/max`
        *   `ApiResponse`, `ProTableParams` from `@/services/common/api.typings`
        *   `endpoints` from `@/services/common/endpoints`
        *   `toPageRequest` from `@/utils`
        *   `SortOrder` from `antd/es/table/interface`
        *   `Key` from `react`
    *   **Functions**:
        *   `getSalesOrderPage(params: ProTableParams, sort: Record<string, SortOrder>)`:
            *   Use `const data = toPageRequest(params, sort);`
            *   Return `request<ApiResponse<SalesOrder[]>>` using `endpoints.salesOrders.page`.
        *   `createSalesOrder(data: SalesOrderRequest)`: POST to `endpoints.salesOrders.base`.
        *   `updateSalesOrder(id: Key, data: SalesOrderRequest)`: PUT to `endpoints.salesOrders.detail(id)`.
        *   `deleteSalesOrderBulk(ids: Key[])`: DELETE to `endpoints.salesOrders.bulkDelete`.
        *   `getSalesOrder(id: Key)`: GET to `endpoints.salesOrders.detail(id)`.

5.  **Export Service Modules (`index.ts`):**
    *   In the new directory, create `index.ts` and export all from `api.ts` and `model.ts`.

---

## Page Layout Parameters (Optional)

When generating a new page, you can specify the layout type if it differs from the standard CRUD pattern.

*   **Layout Type**: `MasterDetail` (e.g. Splitter layout)
*   **Columns**: List key fields if known.

---

### **Phase 2: Page Layer Creation (Standard)**

1.  **Create Page Directory:**
    *   Create a new directory: `src/pages/sd/sales-orders` (Note: Plural directory name).

2.  **Define Table Columns:**
    *   **For Simple Entities (few fields):**
        *   Create a `columns` subdirectory and add `index.tsx` inside it.
        *   **Imports**:
            *   `ColumnEditButton`, `ColumnDeleteButton` from `@/components`.
            *   `SalesOrder` from service model.
        *   **Export Function**:
            *   `export const getColumns = (onEdit: (record: SalesOrder) => void, onDelete: (id: Key) => Promise<void>): ProColumns<SalesOrder>[] => { ... }`
        *   **Actions Column**:
            *   Use `ColumnEditButton` and `ColumnDeleteButton` inside the render function.
            *   Pass `onConfirm={() => onDelete(entity.id)}` to `ColumnDeleteButton`.
    *   **For Complex Entities (many fields, use expandable):**
        *   Create `columns` subdirectory.
        *   **`columns/main.tsx`**: Define the main table columns (key fields only). Action column should only include edit button (no delete).
            *   `export const getColumns = (onEdit: (record: SalesOrder) => void): ProColumns<SalesOrder>[] => { ... }`
            *   Use `buildActionColumn<SalesOrder>(onEdit)` (without delete handler).
        *   **`columns/expanded.tsx`**: Define the detailed fields for the expanded view.
            *   Type: `ProDescriptionsItemProps<SalesOrder>[]`.
            *   Use `span` to control layout (e.g., `span: 1` for single column, `span: 2` for double width in a 4-column layout).
        *   **`columns/index.ts`**: Export both (`export * from './main'; export * from './expanded';`).

3.  **Create Form Component (`components/SalesOrderForm.tsx`):**
    *   Create a `components` subdirectory and add `SalesOrderForm.tsx`.
    *   Use `ModalForm` or `DrawerForm` (from `@ant-design/pro-components`).
    *   **Props**: `open`, `setFormOpen`, `initialValues`, `onFinish`.
    *   **Imports**:
        *   `ProFormInstance` from `@ant-design/pro-components`
        *   `useFormOpenChangeHandler`, `formatCodeName` from `@/utils`
        *   `useRef` from `react`
    *   **Logic**:
        *   Create form ref: `const formRef = useRef<ProFormInstance>();`
        *   Use `useRequest` to handle save logic (create/update).
        *   **Crucial**: The `useRequest` service function **MUST return the Promise** from the API call (e.g., `return isNew ? create(val) : update(id, val)`).
        *   **Configuration**:
            *   Set `manual: true` to prevent automatic execution.
            *   Add `formatResult: (result) => result.success` to properly handle API response format.
            *   In `onSuccess`: 
                *   Show success message (use `message` from `App.useApp()`).
                *   **Important**: Set `submitted` flag to `true` using `formRef.current?.setFieldsValue({ submitted: true })` to prevent the unsaved changes confirmation dialog from appearing when the form closes after a successful save.
                *   Call `onFinish()`.
        *   **Example useRequest configuration**:
            ```typescript
            const { run: saveRun } = useRequest(
              (values: SalesOrderRequest) => isNew ? createSalesOrder(values) : updateSalesOrder(initialValues.id!, values),
              {
                manual: true,
                onSuccess: () => {
                  message.success(intl.formatMessage({ id: 'message.saveSuccess' }));
                  formRef.current?.setFieldsValue({ submitted: true });
                  onFinish();
                },
                formatResult: (result) => result.success
              }
            );
            ```
        *   **Form Open/Close Handler**:
            *   Use `useFormOpenChangeHandler` hook to handle form open/close logic with unsaved changes detection:
            ```typescript
            const handleOpenChange = useFormOpenChangeHandler<SalesOrder>({
              formRef,
              initialValues,
              setFormOpen,
            });
            ```
            *   This hook automatically:
                *   Resets and sets initial values when opening the form.
                *   Detects unsaved changes when closing the form.
                *   Shows a confirmation dialog if there are unsaved changes.
        *   **Form**:
            *   **Important**: Do NOT use `drawerProps={{ destroyOnHidden: true }}` or `modalProps={{ destroyOnClose: true }}`. The form is now reset programmatically via `formRef` when opening.
            *   **Important**: Directly bind `onFinish={saveRun}` (the `run` function from `useRequest`), **do NOT** wrap it in an async function that awaits and returns `true`.
            *   **Example form binding**:
            ```typescript
            <DrawerForm<SalesOrderRequest>
              formRef={formRef}
              onOpenChange={handleOpenChange}
              onFinish={saveRun}
              // ... other props (do NOT include initialValues or drawerProps)
            />
            ```
            *   This ensures proper error handling: when save fails, the form will not reset and user input will be preserved.

4.  **Implement Main Page Component (`index.tsx`):**
    *   In the new directory, create `index.tsx`.
    *   **Imports**: 
        *   `AddButton`, `BatchDeleteButton` from `@/components`.
        *   For expandable pages: `ProDescriptions`, `ExpandAltOutlined`, `ShrinkOutlined` (from `@ant-design/icons`), `Button`, `Tooltip` from `antd`.
    *   **Layout**: Wrap the return JSX in `<PageContainer>` (from `@ant-design/pro-components`).
    *   **State**:
        *   `const actionRef = useRef<ActionType>();`
        *   `useState` for `formOpen`, `currentRow`.
        *   For expandable pages: `expandedRowKeys`, `dataSource`.
    *   **Logic**:
        *   `handleDelete`: Use `useRequest` to wrap `deleteSalesOrderBulk` (for simple entities).
        *   `handleEdit`: set the state `currentRow` and `setFormOpen(true)`.
        *   `columns`: 
            *   Simple: `useMemo(() => getColumns(handleEdit, handleDelete), [handleEdit, handleDelete])`.
            *   Expandable: `useMemo(() => getColumns(handleEdit), [handleEdit])`.
    *   **Components**:
        *   Use `ProTable<SalesOrder>`.
        *   `request`: Call `getSalesOrderPage`.
        *   **For Expandable Pages:**
            *   `onLoad={(dataSource) => setDataSource(dataSource)}`: Sync data for "Expand All" functionality.
            *   **Expandable Config**:
                ```typescript
                expandable={{
                  expandedRowKeys,
                  onExpandedRowsChange: setExpandedRowKeys,
                  expandedRowRender: (record) => (
                    <ProDescriptions
                      column={4}
                      title={false}
                      dataSource={record}
                      columns={expandedColumns}
                    />
                  )
                }}
                ```
        *   `toolBarRender`: 
            *   Use `<AddButton />` and `<BatchDeleteButton />` (pass `selectedRowKeys` and `action` to it).
            *   **For Expandable Pages**, add expand/collapse buttons:
                ```typescript
                toolBarRender={(action, { selectedRowKeys }) => [
                  <BatchDeleteButton key="batchDelete" ... />,
                  <AddButton key="add" ... />,
                  <Tooltip key="expandAll" title={<FormattedMessage id="pages.button.expandAll" />}>
                    <Button
                      icon={<ExpandAltOutlined />}
                      onClick={() => setExpandedRowKeys(dataSource.map(item => item.id!))}
                    />
                  </Tooltip>,
                  <Tooltip key="collapseAll" title={<FormattedMessage id="pages.button.collapseAll" />}>
                    <Button
                      icon={<ShrinkOutlined />}
                      onClick={() => setExpandedRowKeys([])}
                    />
                  </Tooltip>,
                ]}
                ```
        *   `tableAlertRender`: Set to `false` if you prefer `BatchDeleteButton` in toolbar, or keep default if using alert actions.
        *   `onRow`: Implement click-to-select logic and double-click-to-edit functionality:
            ```typescript
            onRow={(data) => ({
              onClick: () => {
                if (data.id === currentRow?.id) return;
                setCurrentRow(data);
              },
              onDoubleClick: () => handleEdit(data),
            })}
            ```
            *   **Click**: Updates `currentRow` to highlight the selected row.
            *   **Double-click**: Calls `handleEdit(data)` to open the form for editing. 
        *   **Form Component**:
            *   Pass `setFormOpen={setFormOpen}` (not `onOpenChange={setFormOpen}`) to the form component:
            ```typescript
            <SalesOrderForm
              key="salesOrderForm"
              onFinish={() => { actionRef.current?.reload(); }}
              initialValues={currentRow}
              open={formOpen}
              setFormOpen={setFormOpen}
            />
            ```

---

### **Phase 2 (Alternative A): Complex Entity Page (With Expandable Details)**

Use this strategy when the entity has many fields that cannot fit comfortably in a single table row.

1.  **Create Page Directory:** `src/pages/sd/sales-orders`.

2.  **Define Columns:**
    *   Create `columns` subdirectory.
    *   **`columns/main.tsx`**: Define the main table columns (key fields only).
    *   **`columns/expanded.tsx`**: Define the detailed fields for the expanded view.
        *   Type: `ProDescriptionsItemProps<SalesOrder>[]`.
        *   Use `span` to control layout (e.g., `span: 4` for full width in a 4-column layout).
    *   **`columns/index.ts`**: Export both (`export * from './main'; export * from './expanded';`).

3.  **Implement Main Page Component (`index.tsx`):**
    *   **Imports**: `ProDescriptions`, `ExpandAltOutlined`, `ShrinkOutlined` (from `@ant-design/icons`), `Tooltip`.
    *   **State**:
        *   `const [expandedRowKeys, setExpandedRowKeys] = useState<readonly React.Key[]>([]);`
        *   `const [dataSource, setDataSource] = useState<readonly SalesOrder[]>([]);`
    *   **Table Config (`ProTable`)**:
        *   `onLoad={(dataSource) => setDataSource(dataSource)}`: Sync data for "Expand All" functionality.
        *   **Expandable**:
            ```typescript
            expandable={{
              expandedRowKeys,
              onExpandedRowsChange: setExpandedRowKeys,
              expandedRowRender: (record) => (
                <ProDescriptions
                  column={4} // Adjust column count as needed (e.g., 3 to 5 for desktop)
                  title={false}
                  dataSource={record}
                  columns={expandedColumns}
                />
              )
            }}
            ```
    *   **Toolbar**:
        *   Add "Expand All" and "Collapse All" buttons:
            ```typescript
            toolBarRender={(action, { selectedRowKeys }) => [
              // ... other buttons
              <Tooltip key="expandAll" title={<FormattedMessage id="pages.button.expandAll" />}>
                <Button
                  icon={<ExpandAltOutlined />}
                  onClick={() => setExpandedRowKeys(dataSource.map(item => item.id!))}
                />
              </Tooltip>,
              <Tooltip key="collapseAll" title={<FormattedMessage id="pages.button.collapseAll" />}>
                <Button
                  icon={<ShrinkOutlined />}
                  onClick={() => setExpandedRowKeys([])}
                />
              </Tooltip>,
            ]}
            ```

---

### **Phase 2 (Alternative B): Editable Table Page (For Simple Resources)**

Use this strategy for simple reference data (e.g., MaterialUnits, Colors, ProductSizes) where inline editing is preferred.

**Use the `EditableTablePage` component from `@/components` for maximum code reuse.**

1.  **Create Page Directory:** `src/pages/sd/sales-orders`.

2.  **Define Columns (`columns/index.tsx`):**
    *   Use `getColumns` with `onEdit` callback only (row-level delete is handled via batch selection):
        ```typescript
        export const getColumns = (
          onEdit: (record: SalesOrder) => void,
        ): ProColumns<SalesOrder>[] => [
          // ... columns
          buildActionColumn<SalesOrder>(onEdit),
        ];
        ```
    *   Use helper functions from `@/utils` for common columns (`buildActionColumn`, `buildStatusOptionColumn`, `buildUpdatedByNameColumn`, `buildUpdatedAtColumn`, `formatCodeName`).
    *   **Formatting Example**:
        ```typescript
        render: (_, record) => formatCodeName(record.materialCode, record.materialName)
        ```

3.  **Implement Main Page Component (`index.tsx`):**
    ```typescript
    import { EditableTablePage } from "@/components";
    import {
      createSalesOrderBulk,
      deleteSalesOrderBulk,
      getSalesOrderPage,
      SalesOrder,
      updateSalesOrderBulk
    } from "@/services/sd/sales-order";
    import { FormattedMessage } from "@umijs/max";
    import { getColumns } from "./columns";

    export default function SalesOrders() {
      return (
        <EditableTablePage<SalesOrder>
          headerTitle={<FormattedMessage id="pages.sd.salesOrders.title" />}
          getColumns={getColumns}
          request={getSalesOrderPage}
          createBulk={createSalesOrderBulk}
          updateBulk={updateSalesOrderBulk}
          deleteBulk={deleteSalesOrderBulk}
        />
      );
    }
    ```

4.  **Optional Props for `EditableTablePage`:**
    *   `createDefaultRecord`: Function to provide default values for new records:
        ```typescript
        createDefaultRecord={(optionCategory, dataSource) => ({
          companyId: dataSource[dataSource.length - 1]?.companyId, // Carry over from previous row
        })}
        ```
    *   `extraToolbarButtons`: Additional toolbar buttons (ReactNode[]).
    *   `beforeSave`: Callback before save, return `false` to cancel.
    *   `afterSave`: Callback after successful save.
    *   `pageSize`: Custom page size (default: 100).
    *   `statusOptionCode`: Custom status option code (default: 'record_status').

---

### **Phase 2 (Alternative C): Master-Detail Page (e.g., Splitter or Linked Tables)**

Use this strategy for entities with complex relationships (e.g., Users & UserRoles, Orders & OrderItems) displayed on the same page.

1.  **State Management (Crucial)**:
    *   **Separate "Selection" from "Editing"**: Do NOT reuse the same state variable for the currently selected row (which drives the detail table) and the form's initial values.
    *   **Why?**: Modifying the selected row state for a "New" operation (which has no ID) will cause the detail table (which relies on a valid ID) to hide its actions or display incorrect data.
    *   **Pattern**:
        ```typescript
        // 1. Tracks the row clicked in the master table. Controls Detail Table visibility/query.
        const [currentRow, setCurrentRow] = useState<Partial<SalesOrder>>();

        // 2. Tracks the data passed to the Add/Edit form.
        const [formInitialSalesOrders, setFormInitialSalesOrders] = useState<Partial<SalesOrder>>();
        ```

2.  **Logic**:
    *   **Selection**: In `onRow.onClick`, update `currentRow`.
    *   **Edit**: In `handleEdit`, update `setFormInitialValues(record)` and open the form.
    *   **Add**: In `AddButton.onClick`, update `setFormInitialSalesOrders({ ...defaults })` and open the form. **Do NOT touch `currentRow`**.
    *   **Double-click to Edit**: Implement `onRow` with both `onClick` and `onDoubleClick`:
        ```typescript
        // Master Table
        onRow={(data) => ({
          onClick: () => {
            if (data.id === currentRow?.id) return;
            setCurrentRow(data);
          },
          onDoubleClick: () => handleEditSalesOrder(data),
        })}
        
        // Detail Table (if applicable)
        onRow={(data) => ({
          onClick: () => {
            if (data.id === currentSalesOrderItem?.id) return;
            setCurrentSalesOrderItem(data);
          },
          onDoubleClick: () => handleEditSalesOrderItem(data),
        })}
        ```

3.  **Components**:
    *   **Master Table**: `ProTable<SalesOrder>`.
    *   **Detail Table**: `ProTable<SalesOrderItem>`.
        *   `params={{ masterId: currentRow?.id }}`
        *   `headerTitle`: Show context (e.g., `${currentRow?.name} Roles`).
        *   **Actions**: Hide "Add" button if no `currentRow?.id` is selected.

---

### **Phase 3: Configuration & Localization**

1.  **Add Localization (`src/locales/en-US/pages.ts`):**
    *   Add keys for the new page title and fields (e.g., `pages.sd.salesOrders.title`).

2.  **Backend Menu Configuration (Note):**
    *   The system uses dynamic routing based on user permissions (`src/app.tsx`).
    *   **Do NOT** modify `config/routes.ts`.
    *   Ensure the backend (`getUserAuthority`) returns a menu item with the path `/sd/sales-orders` that matches the created page directory.

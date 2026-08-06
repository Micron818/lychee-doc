# `useRequest` 這是一個基於 `@ahooksjs/use-request` 的封裝

## useRequest 的不同使用方式

### 1. 基本使用方式
```typescript
function useRequest<R = any, P extends any[] = any, U = any, UU extends U = any>(
  service: CombineService<R, P>,
  options: OptionsWithFormat<R, P, U, UU>,
): BaseResult<U, P>;
```

**用途**：最通用的使用方式，支持自定義格式化和類型轉換。

**示例**：
```typescript
const { data, loading, error } = useRequest(
  (params) => fetch('/api/users', { params }),
  {
    formatResult: (response) => response.data.users,
    onSuccess: (data) => console.log('成功:', data),
    onError: (error) => console.error('失敗:', error),
  }
);
```

### 2. 帶有 ResultWithData 的服務
```typescript
function useRequest<R extends ResultWithData = any, P extends any[] = any>(
  service: CombineService<R, P>,
  options?: BaseOptions<R['data'], P>,
): BaseResult<R['data'], P>;
```

**用途**：當服務返回的數據結構包含 `data` 字段時使用。

**示例**：
```typescript
// 假設 API 返回 { data: User[], code: 200, message: 'success' }
const { data, loading, error } = useRequest(
  (params) => getUsers(params),
  {
    onSuccess: (users) => console.log('用戶列表:', users),
  }
);
// data 會自動提取 response.data
```

### 3. 加載更多功能
```typescript
function useRequest<R extends LoadMoreFormatReturn = any, RR = any>(
  service: CombineService<RR, LoadMoreParams<R>>,
  options: LoadMoreOptionsWithFormat<R, RR>,
): LoadMoreResult<R>;
```

**用途**：實現無限滾動或分頁加載更多數據。

**示例**：
```typescript
const { data, loadMore, loading, noMore } = useRequest(
  (params) => fetchMoreData(params),
  {
    loadMore: true,
    formatResult: (response) => response.data,
    onSuccess: (data) => console.log('加載更多成功'),
  }
);

// 使用
<Button onClick={loadMore} loading={loading} disabled={noMore}>
  加載更多
</Button>
```

### 4. 分頁功能
```typescript
function useRequest<R extends ResultWithData<PaginatedFormatReturn<Item>>, RR extends R = any>(
  service: CombineService<R, PaginatedParams>,
  options: BasePaginatedOptions<RR['data']>,
): PaginatedResult<Item>;
```

**用途**：處理分頁數據，自動管理分頁狀態。

**示例**：
```typescript
const { data, pagination, refresh } = useRequest(
  (params) => getUsersPage(params),
  {
    paginated: true,
    defaultPageSize: 20,
    onSuccess: (data) => console.log('分頁數據:', data),
  }
);

// 使用
<Table
  dataSource={data}
  pagination={{
    current: pagination.current,
    pageSize: pagination.pageSize,
    total: pagination.total,
    onChange: (page, size) => {
      // 自動處理分頁變化
    },
  }}
/>
```

### 5. 實際使用示例

讓我查看一下你項目中的實際使用情況：


[1 tool called]

## 常見的 useRequest 使用模式

### 1. 自動執行請求
```typescript
// 組件掛載時自動執行
const { data, loading, error } = useRequest('/api/users');
```

### 2. 手動執行請求
```typescript
// 需要手動觸發
const { run, loading } = useRequest(deleteUser, {
  manual: true,
  onSuccess: () => message.success('刪除成功'),
});
```

### 3. 帶參數的請求
```typescript
const { data, loading } = useRequest(
  (params) => getUserById(params.id),
  {
    defaultParams: [{ id: 1 }],
  }
);
```

### 4. 依賴請求
```typescript
const { data: user } = useRequest('/api/user');
const { data: profile } = useRequest(
  (userId) => `/api/profile/${userId}`,
  {
    ready: !!user?.id,
    refreshDeps: [user?.id],
  }
);
```

### 5. 輪詢請求
```typescript
const { data } = useRequest('/api/status', {
  pollingInterval: 1000,
  pollingWhenHidden: false,
});
```

### 6. 緩存和防抖
```typescript
const { data } = useRequest('/api/search', {
  debounceWait: 300,
  cacheKey: 'search-results',
  staleTime: 5000,
});
```

## 返回值說明

`useRequest` 返回的對象通常包含：

- `data`: 請求返回的數據
- `loading`: 是否正在請求中
- `error`: 請求錯誤信息
- `run`: 手動執行請求的函數
- `refresh`: 重新執行請求
- `cancel`: 取消請求
- `mutate`: 修改 data 數據


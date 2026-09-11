# 國際化 (i18n) 使用說明

## 支援的語言

- **英文 (en)** - 預設語言
- **越南文 (vi)** - 新增支援
- **簡體中文 (zh_CN)** - 現有支援

## 語言切換方式

### 1. 透過 HTTP Header
```http
Accept-Language: vi
```

### 2. 透過 URL 參數
```http
GET /api/tenants?lang=vi
POST /api/tenants?lang=vi
```

### 3. 透過 API 端點
```http
GET /api/language/validation-messages?lang=vi
```

## 越南文驗證訊息範例

### 租戶相關
- `validation.tenant.name.required` → "Tên thuê bao không được để trống"
- `validation.tenant.code.required` → "Mã thuê bao không được để trống"
- `validation.tenant.domain.required` → "Tên miền thuê bao không được để trống"

### 公司相關
- `validation.company.name.required` → "Tên công ty không được để trống"
- `validation.company.code.required` → "Mã công ty không được để trống"

### 用戶相關
- `validation.user.username.required` → "Tên người dùng không được để trống"
- `validation.user.email.required` → "Email không được để trống"
- `validation.user.fullname.required` → "Họ và tên không được để trống"

## API 測試範例

### 測試越南文驗證
```bash
curl -X POST http://localhost:9000/api/test/tenant-vi \
  -H "Content-Type: application/json" \
  -H "Accept-Language: vi" \
  -d '{}'
```

### 回應範例 (越南文)
```json
{
  "message": "Xảy ra lỗi xác thực",
  "errors": [
    "Tên thuê bao không được để trống",
    "Mã thuê bao không được để trống",
    "Tên miền thuê bao không được để trống"
  ],
  "timestamp": 1703123456789
}
```

## 前端整合範例

```javascript
// 設定越南文
const setVietnamese = () => {
  axios.defaults.headers.common['Accept-Language'] = 'vi';
};

// 獲取越南文驗證訊息
const getVietnameseMessages = async () => {
  const response = await axios.get('/api/language/validation-messages?lang=vi');
  return response.data;
};

// 使用範例
setVietnamese();
const messages = await getVietnameseMessages();
console.log(messages['tenant.name.required']); // "Tên thuê bao không được để trống"
```

## 檔案結構

```
src/main/resources/i18n/
├── messages.properties          # 英文 (預設) - error / validation
├── messages_vi.properties       # 越南文
├── messages_zh_CN.properties    # 簡體中文
├── entities.properties          # 英文 - entity.* 實體顯示名稱 (NotFoundException.resource)
├── entities_vi.properties       # 越南文
├── entities_zh_CN.properties    # 簡體中文
├── enums.properties             # 英文 - enum.* 枚舉標籤
├── enums_vi.properties          # 越南文
├── enums_zh_CN.properties       # 簡體中文
└── README.md                    # 說明文件
```

i18n basename 僅在 `InternationalizationConfig.java` 設定（`messages`、`entities`、`enums`），無需在 `application.yaml` 重複配置。

新增 `entity.*` 鍵時，請寫入 `entities*.properties`；新增 `enum.*` 鍵時，請寫入 `enums*.properties`，三語系同步維護。

## 新增語言支援

1. 在 `InternationalizationConfig.java` 中添加新的 Locale
2. 創建對應的 `messages_xx.properties` 檔案
3. 翻譯所有訊息鍵值
4. 更新相關註釋和文件

**「ERP 前端 + 後端 + CDN + OSS（CDN 簽名 URL）」的架構時序圖**

一、圖片「顯示 / 讀取」流程（CDN 簽名 URL）

```mermaid
sequenceDiagram
    autonumber
    participant FE as ERP Frontend<br/>(Umi Max)
    participant BE as ERP Backend<br/>(Spring Boot / ECS)
    participant CDN as Aliyun CDN<br/>(HTTPS + URL Auth)
    participant OSS as Aliyun OSS<br/>(Private Bucket)

    FE->>BE: GET /api/material-images/{imageId}/signed-url
    BE->>BE: 驗證登入 & 權限<br/>(MATERIAL_VIEW)
    BE->>BE: 查詢 material_image.file_path
    BE->>BE: 產生 CDN 簽名 URL<br/>(expire + auth_key)
    BE-->>FE: 回傳 signed CDN URL

    FE->>CDN: GET image (signed URL)
    CDN->>CDN: 驗證 auth_key / 是否過期

    alt CDN Cache Hit
        CDN-->>FE: 回傳圖片
    else CDN Cache Miss
        CDN->>OSS: HTTPS 回源請求圖片
        OSS-->>CDN: 回傳圖片
        CDN-->>FE: 回傳圖片
    end
```
---

二、圖片「上傳」流程（ERP → OSS）
```mermaid
sequenceDiagram
    autonumber
    participant FE as ERP Frontend
    participant BE as ERP Backend<br/>(Spring Boot / ECS)
    participant OSS as Aliyun OSS<br/>(Private Bucket)

    FE->>BE: POST /api/materials/{id}/images<br/>(multipart/form-data)
    BE->>BE: 驗證登入 & 權限<br/>(MATERIAL_EDIT)
    BE->>BE: 驗證檔案類型 / 大小
    BE->>BE: 生成 OSS 存放路徑
    BE->>OSS: HTTPS 上傳圖片
    OSS-->>BE: 上傳成功
    BE->>BE: 寫入 material_image 資料
    BE-->>FE: 回傳圖片 metadata

```
---

三、圖片「刪除」流程

```mermaid
sequenceDiagram
    autonumber
    participant FE as ERP Frontend
    participant BE as ERP Backend
    participant OSS as Aliyun OSS

    FE->>BE: DELETE /api/material-images/{imageId}
    BE->>BE: 驗證登入 & 權限
    BE->>BE: 刪除 DB 記錄
    BE->>OSS: HTTPS 刪除圖片檔案
    OSS-->>BE: 刪除成功
    BE-->>FE: OK

```

---

四、列表頁「批量取得簽名 URL」（效能優化）
```mermaid
sequenceDiagram
    autonumber
    participant FE as ERP Frontend
    participant BE as ERP Backend

    FE->>BE: POST /api/material-images/signed-urls
    Note right of FE: 傳 imageId list
    BE->>BE: 批量權限檢查
    BE->>BE: 批量產生簽名 URL
    BE-->>FE: 回傳 signed URL map

```

---

五、設計說明
圖片資源存放於阿里雲 OSS（Private Bucket），
所有圖片請求統一經由阿里雲 CDN，並透過 ERP 後端動態產生短效 CDN 簽名 URL。
ERP 後端負責權限與簽名，CDN 負責快取與效能，OSS 僅作為安全儲存層。

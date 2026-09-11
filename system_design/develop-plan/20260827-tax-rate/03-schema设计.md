# 03. Schema 设计

> 未上线：以 Liquibase changeset + `lychee-doc/.../schema_tables` 同步为准。  
> 单据行保留 `tax_rate` 作为 **快照**，不是删掉改成只存税码。

---

## 1. 改什么、不改什么

| 对象 | 动作 |
|------|------|
| `tax_classes` | **新增** 物料/往来税分类 |
| `tax_codes` | **新增** 税码主档 |
| `tax_code_rates` | **新增** 税率有效期档 |
| `tax_determinations` | **新增** 判定矩阵 |
| `companies.country_code` | **新增** ISO 3166-1 alpha-2，开单判定用 |
| `materials.tax_class_id` | **新增**，可空（开单时再卡） |
| `suppliers.tax_class_id` / `customers.tax_class_id` | **新增**，可空 |
| 单据行 `tax_code_id` | **新增**（PO/委外/SO/发货/GR/AP/AR） |
| AP/AR 行 `tax_amount_overridden` | **新增** |
| 单据行 `tax_rate` | **保留**，语义改为税码档快照 |
| `fi_account_determination` | **不改** 唯一键；税科目走税码覆盖 |
| `material_suppliers` | **不加** 税码 |
| `business_partners` | **不加** 税分类 |
| `purchase_requisition_items` | **不加** 税 |
| 单据表头 | **不加** `tax_code_id` / `tax_rate` |

`tax_id`（公司/往来税号）与税码无关，保持原样。

---

## 2. 税分类 `tax_classes`

对标 `valuation_classes`：短码、租户唯一、启用标志。用 `class_scope` 区分物料与往来，避免两张几乎相同的表。

```sql
CREATE TABLE lychee_erp.tax_classes
(
    id              bigserial       NOT NULL,
    tenant_id       bigint          NOT NULL,
    code            varchar(50)     NOT NULL,
    name            varchar(100)    NOT NULL,
    class_scope     varchar(20)     NOT NULL,    -- MATERIAL, PARTNER
    is_active       boolean         NOT NULL DEFAULT true,
    description     text            NULL,
    created_at      timestamp       NULL,
    updated_at      timestamp       NULL,
    created_by      bigint          NULL,
    updated_by      bigint          NULL,
    CONSTRAINT pk_tax_classes PRIMARY KEY (id),
    CONSTRAINT uk_tax_classes UNIQUE (tenant_id, code)
);

CREATE INDEX ix_tax_classes_scope ON lychee_erp.tax_classes (tenant_id, class_scope);

ALTER TABLE lychee_erp.tax_classes
    ADD CONSTRAINT fk_tax_classes_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
```

建议种子（实施可改名，code 稳定）：

| code | class_scope | 用途 |
|------|-------------|------|
| `MAT-GOODS` | MATERIAL | 货物（标准档） |
| `MAT-GOODS-RED` | MATERIAL | 货物低税率 |
| `MAT-SERVICE` | MATERIAL | 服务 |
| `MAT-EXEMPT` | MATERIAL | 免税品 |
| `BP-DOMESTIC` | PARTNER | 国内应税 |
| `BP-OVERSEAS` | PARTNER | 境外/出口 |
| `BP-EXEMPT` | PARTNER | 免税往来 |
| `BP-SMALL` | PARTNER | 小规模/不可抵扣进项场景 |

---

## 3. 税码 `tax_codes`

租户级（与 `gl_accounts` 相同）。国家在税码上，公司用 `country_code` 过滤可选税码。

```sql
CREATE TABLE lychee_erp.tax_codes
(
    id                      bigserial       NOT NULL,
    tenant_id               bigint          NOT NULL,
    code                    varchar(50)     NOT NULL,
    name                    varchar(100)    NOT NULL,
    country_code            varchar(2)      NOT NULL,    -- CN, VN
    direction               varchar(20)     NOT NULL,    -- INPUT, OUTPUT, BOTH
    tax_type                varchar(20)     NOT NULL,    -- STANDARD, REDUCED, ZERO, EXEMPT, NON_TAXABLE
    is_deductible           boolean         NOT NULL DEFAULT true,
    input_gl_account_id     bigint          NULL,
    output_gl_account_id    bigint          NULL,
    is_active               boolean         NOT NULL DEFAULT true,
    description             text            NULL,
    created_at              timestamp       NULL,
    updated_at              timestamp       NULL,
    created_by              bigint          NULL,
    updated_by              bigint          NULL,
    CONSTRAINT pk_tax_codes PRIMARY KEY (id),
    CONSTRAINT uk_tax_codes UNIQUE (tenant_id, code)
);

CREATE INDEX ix_tax_codes_country ON lychee_erp.tax_codes (tenant_id, country_code, direction);

ALTER TABLE lychee_erp.tax_codes
    ADD CONSTRAINT fk_tax_codes_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.tax_codes
    ADD CONSTRAINT fk_tax_codes_input_gl
        FOREIGN KEY (input_gl_account_id) REFERENCES lychee_erp.gl_accounts (id);
ALTER TABLE lychee_erp.tax_codes
    ADD CONSTRAINT fk_tax_codes_output_gl
        FOREIGN KEY (output_gl_account_id) REFERENCES lychee_erp.gl_accounts (id);
```

应用层约束：

- `direction = OUTPUT` ⇒ `is_deductible` 无意义，固定 `true` 或忽略。
- `tax_type IN (ZERO, EXEMPT, NON_TAXABLE)` ⇒ 税率档必须为 0。
- `is_deductible = false` ⇒ `input_gl_account_id` **必填**（过账不能回退 `INPUT_TAX`）。
- 停用税码：判定与开单下拉排除；已有单据快照保留。

建议种子（越南运营主体优先；中国税码一并预置，无 CN 公司则矩阵不引用）：

| code | country | direction | tax_type | deductible | 说明 |
|------|---------|-----------|----------|------------|------|
| `VN-IN-10` | VN | INPUT | STANDARD | true | 进项 10% |
| `VN-IN-8` | VN | INPUT | REDUCED | true | 进项 8% |
| `VN-IN-5` | VN | INPUT | REDUCED | true | 进项 5% |
| `VN-IN-0` | VN | INPUT | ZERO | true | 进项 0% |
| `VN-IN-ND` | VN | INPUT | STANDARD | **false** | 不可抵扣（科目指向费用，种子时指定 6602 或专设科目） |
| `VN-OUT-10` | VN | OUTPUT | STANDARD | n/a | 销项 10% |
| `VN-OUT-8` | VN | OUTPUT | REDUCED | n/a | 销项 8% |
| `VN-OUT-5` | VN | OUTPUT | REDUCED | n/a | 销项 5% |
| `VN-OUT-0` | VN | OUTPUT | ZERO | n/a | 出口零税率 |
| `VN-OUT-EX` | VN | OUTPUT | EXEMPT | n/a | 免税 |
| `CN-IN-13` / `CN-OUT-13` 等 | CN | … | … | … | 13/9/6/0/免税，结构同 VN |

税率数字不在本表。种子税率档见 §4。

---

## 4. 税率档 `tax_code_rates`

一个税码多档；**允许相邻档日期相接，禁止同一税码有效期重叠**。

```sql
CREATE TABLE lychee_erp.tax_code_rates
(
    id              bigserial       NOT NULL,
    tenant_id       bigint          NOT NULL,
    tax_code_id     bigint          NOT NULL,
    rate            numeric(5,2)    NOT NULL,    -- 10.00 = 10%
    valid_from      date            NOT NULL,
    valid_to        date            NULL,        -- NULL = 长期
    remarks         text            NULL,
    created_at      timestamp       NULL,
    updated_at      timestamp       NULL,
    created_by      bigint          NULL,
    updated_by      bigint          NULL,
    CONSTRAINT pk_tax_code_rates PRIMARY KEY (id)
);

CREATE INDEX ix_tax_code_rates_code_date
    ON lychee_erp.tax_code_rates (tax_code_id, valid_from);

ALTER TABLE lychee_erp.tax_code_rates
    ADD CONSTRAINT fk_tax_code_rates_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.tax_code_rates
    ADD CONSTRAINT fk_tax_code_rates_code
        FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id);
ALTER TABLE lychee_erp.tax_code_rates
    ADD CONSTRAINT ck_tax_code_rates_rate
        CHECK (rate >= 0 AND rate <= 100);
ALTER TABLE lychee_erp.tax_code_rates
    ADD CONSTRAINT ck_tax_code_rates_dates
        CHECK (valid_to IS NULL OR valid_to >= valid_from);
```

重叠用应用层校验（保存前查询相交区间）。不要用 EXCLUDE 约束除非团队已在用 btree_gist。

政策调整作业：

```text
旧档 valid_to = 生效日前一天
新档 valid_from = 生效日, valid_to NULL, 同一 tax_code_id
已过账单据不改
```

种子：每个税码一档，`valid_from = 2000-01-01`，`valid_to` 空；VN-IN-10 / VN-OUT-10 的 `rate = 10.00`，ZERO/EXEMPT = 0。

---

## 5. 判定矩阵 `tax_determinations`

对标 `fi_account_determination` 的通配：`company_id` / 两个分类均可空。另加 `country_code`（NOT NULL）：无国家则 VN/CN 无法各写一套国家默认（旧唯一键不含国家，两国会撞车）。

```sql
CREATE TABLE lychee_erp.tax_determinations
(
    id                      bigserial       NOT NULL,
    tenant_id               bigint          NOT NULL,
    country_code            varchar(2)      NOT NULL, -- ISO 3166-1 alpha-2；国家默认按国家各写一套
    company_id              bigint          NULL,     -- NULL = 该国默认
    tax_direction           varchar(20)     NOT NULL, -- INPUT, OUTPUT
    partner_tax_class_id    bigint          NULL,     -- NULL = 通配
    material_tax_class_id   bigint          NULL,     -- NULL = 通配
    tax_code_id             bigint          NOT NULL,
    is_active               boolean         NOT NULL DEFAULT true,
    remarks                 text            NULL,
    created_at              timestamp       NULL,
    updated_at              timestamp       NULL,
    created_by              bigint          NULL,
    updated_by              bigint          NULL,
    CONSTRAINT pk_tax_determinations PRIMARY KEY (id)
);

CREATE UNIQUE INDEX uk_tax_determinations
    ON lychee_erp.tax_determinations (
        tenant_id,
        country_code,
        COALESCE(company_id, 0),
        tax_direction,
        COALESCE(partner_tax_class_id, 0),
        COALESCE(material_tax_class_id, 0)
    );

ALTER TABLE lychee_erp.tax_determinations
    ADD CONSTRAINT fk_tax_det_tenant
        FOREIGN KEY (tenant_id) REFERENCES lychee_erp.tenants (id);
ALTER TABLE lychee_erp.tax_determinations
    ADD CONSTRAINT fk_tax_det_company
        FOREIGN KEY (company_id) REFERENCES lychee_erp.companies (id);
ALTER TABLE lychee_erp.tax_determinations
    ADD CONSTRAINT fk_tax_det_partner_class
        FOREIGN KEY (partner_tax_class_id) REFERENCES lychee_erp.tax_classes (id);
ALTER TABLE lychee_erp.tax_determinations
    ADD CONSTRAINT fk_tax_det_material_class
        FOREIGN KEY (material_tax_class_id) REFERENCES lychee_erp.tax_classes (id);
ALTER TABLE lychee_erp.tax_determinations
    ADD CONSTRAINT fk_tax_det_tax_code
        FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id);
```

应用层：

- `partner_tax_class.class_scope = PARTNER`；物料侧 = `MATERIAL`。
- 税码 `country_code` = 判定行 `country_code`。
- `company_id` 非空时：判定行 `country_code` = 该公司 `country_code`（改公司国家会与矩阵不一致，见 §6）。
- 税码 `direction` 为 `BOTH` 或等于 `tax_direction`。
- 停用行不参与匹配，但占用唯一键——改矩阵用更新，不要插第二条同键停用行。

示例（`country_code = VN`，`company_id` 可空作该国默认；CN 另写一套指向 `CN-*` 税码）：

| 国家 | 方向 | 往来 | 物料 | 税码 |
|------|------|------|------|------|
| VN | INPUT | BP-DOMESTIC | MAT-GOODS | VN-IN-10 |
| VN | INPUT | BP-DOMESTIC | MAT-GOODS-RED | VN-IN-8 |
| VN | INPUT | BP-DOMESTIC | MAT-SERVICE | VN-IN-10 |
| VN | INPUT | BP-SMALL | NULL | VN-IN-ND |
| VN | INPUT | BP-OVERSEAS | NULL | VN-IN-0 |
| VN | OUTPUT | BP-DOMESTIC | MAT-GOODS | VN-OUT-10 |
| VN | OUTPUT | BP-DOMESTIC | MAT-GOODS-RED | VN-OUT-8 |
| VN | OUTPUT | BP-OVERSEAS | NULL | VN-OUT-0 |
| VN | OUTPUT | BP-EXEMPT | NULL | VN-OUT-EX |
| VN | OUTPUT | BP-DOMESTIC | MAT-EXEMPT | VN-OUT-EX |

NULL 表示通配。匹配算法见 `02` §3.2。

---

## 6. 公司国家

```sql
ALTER TABLE lychee_erp.companies
    ADD COLUMN country_code varchar(2) NOT NULL DEFAULT 'VN';

COMMENT ON COLUMN lychee_erp.companies.country_code
    IS 'ISO 3166-1 alpha-2; tax code catalog filter';
```

未上线可用默认 `VN` 回填后，**保留 NOT NULL**。实施中国公司改为 `CN`。  
开账后改国家会使在途单与矩阵不一致：应用层对已有未清 SO/PO/发票的公司拒绝改国家，或仅允许改到无单据的新公司。V1：有未关闭业务单则拒绝修改。允许改时须同步该公司判定行的 `country_code`（或先删公司级判定行），否则公司保存失败。

---

## 7. 主数据外键

```sql
ALTER TABLE lychee_erp.materials
    ADD COLUMN tax_class_id bigint NULL;
ALTER TABLE lychee_erp.materials
    ADD CONSTRAINT fk_materials_tax_class
        FOREIGN KEY (tax_class_id) REFERENCES lychee_erp.tax_classes (id);
CREATE INDEX ix_materials_tax_class ON lychee_erp.materials (tax_class_id);

ALTER TABLE lychee_erp.suppliers
    ADD COLUMN tax_class_id bigint NULL;
ALTER TABLE lychee_erp.suppliers
    ADD CONSTRAINT fk_suppliers_tax_class
        FOREIGN KEY (tax_class_id) REFERENCES lychee_erp.tax_classes (id);

ALTER TABLE lychee_erp.customers
    ADD COLUMN tax_class_id bigint NULL;
ALTER TABLE lychee_erp.customers
    ADD CONSTRAINT fk_customers_tax_class
        FOREIGN KEY (tax_class_id) REFERENCES lychee_erp.tax_classes (id);
```

保存时校验 scope。列表/表单必填可在上线前用数据修补脚本填默认 `MAT-GOODS` / `BP-DOMESTIC`，schema 仍可空以免阻断现有 CRUD 测试数据。

---

## 8. 单据行快照

统一加列（名称一致）：

```sql
-- 对下列每张表明细：
-- purchase_order_items, outsource_order_items,
-- sales_order_items, delivery_items, goods_receipt_items,
-- ap_invoice_lines, ar_invoice_lines

ALTER TABLE lychee_erp.<table>
    ADD COLUMN tax_code_id bigint NULL;

ALTER TABLE lychee_erp.<table>
    ADD CONSTRAINT fk_<table>_tax_code
        FOREIGN KEY (tax_code_id) REFERENCES lychee_erp.tax_codes (id);

CREATE INDEX ix_<table>_tax_code ON lychee_erp.<table> (tax_code_id);
```

AP/AR 额外：

```sql
ALTER TABLE lychee_erp.ap_invoice_lines
    ADD COLUMN tax_amount_overridden boolean NOT NULL DEFAULT false;
ALTER TABLE lychee_erp.ar_invoice_lines
    ADD COLUMN tax_amount_overridden boolean NOT NULL DEFAULT false;
```

`tax_rate` 注释改为：`Snapshot of tax_code_rates.rate at document date; not a live projection`。  
GR 注释同步：`Source tax code + rate snapshot`。

委外：Liquibase 已有 `tax_rate/tax_amount/total_amount`；本波只加 `tax_code_id`，并补 `schema_tables`。

未上线：不必回填历史税码。若测试库已有 `tax_rate <> 0` 的行，可按国家+方向+rate 匹配种子税码回填（实施脚本，非强制）。

行上 **不加** `tax_code` 文本快照（避免与主档改名双源）。列表展示 join 税码；主档改名会影响历史显示，可接受（评估类同样不在行上快照 code）。若打印要冻结名称，报表当时 join 即可；二期不加班 `tax_code`/`tax_code_name`。

---

## 9. 枚举

| 枚举 | 值 |
|------|-----|
| `TaxClassScope` | `MATERIAL`, `PARTNER` |
| `TaxDirection` | `INPUT`, `OUTPUT`, `BOTH`（仅税码；判定行只用 INPUT/OUTPUT） |
| `TaxType` | `STANDARD`, `REDUCED`, `ZERO`, `EXEMPT`, `NON_TAXABLE` |

`EnumController` 同步。不要把税率数字放进枚举。

---

## 10. 模块归属

| 表 / API | 模块 |
|----------|------|
| `tax_classes` / `tax_codes` / `tax_code_rates` / `tax_determinations` CRUD | `lychee-erp-fi` |
| `POST .../tax-determinations/resolve` | `lychee-erp-fi` |
| `RemoteTaxDeterminationService` | 契约 `lychee-erp-common`；实现 FI |
| `RemoteSupplierDTO` / `RemoteCustomerDTO` / `RemoteMaterialDTO` 加 `taxClassId` | common 契约；SCM / SD / MD 实现回填 |
| `companies.country_code` | `lychee-erp-basis` |
| `materials.tax_class_id` | `lychee-erp-md`（物料模块） |
| `suppliers.tax_class_id` | `lychee-erp-scm` |
| `customers.tax_class_id` | `lychee-erp-sd` |
| AP/AR 杂项行取往来分类 | FI：`business_partners.source_id` → Remote 供应商/客户 |
| PO/委外开行、转单调用判定 | SCM |
| SO 开行调用判定 | SD |
| GR/发货复制税码 | WM / SD |
| AP/AR 过账读税码科目 | FI |
| 前端主数据 | `lychee-frontend/src/pages/fi/tax-*` |

跨模块禁止 SCM 直接 import FI 实体。

---

## 11. 数据流（开一行 PO）

```text
1. 解析 company = factory.company；country = company.country_code
2. 读 supplier.tax_class_id、material.tax_class_id（缺则失败）
3. resolve(company, INPUT, partnerClass, materialClass, orderDate [, taxCodeId])
4. INSERT 行：tax_code_id, tax_rate=档, 按公式写金额
5. 表头 SUM
```

AP/AR 杂项行（无上游快照）：

```text
1. company = 发票表头 company_id；documentDate = invoice_date
2. partnerClass = Remote 反查 BP.source_id 的 taxClassId（缺则失败）
3. materialClass = 有物料则 RemoteMaterialDTO.taxClassId，否则 null
4. resolve(...) 后写行
```

AP 过账税行：

```text
1. tax_amount == 0 → 无税行
2. direction 隐含 INPUT
3. is_deductible
     true  → GL = COALESCE(tax_code.input_gl_account_id, resolve(INPUT_TAX))
     false → GL = tax_code.input_gl_account_id（必填，否则失败）
4. 借税额（覆盖或公式）
```

---

## 12. 文档与过期描述对齐

实施时同步：

- `schema_tables`：新四张 FI 表；`companies` / `materials` / `suppliers` / `customers`；七张单据明细。
- `FI_schema_design.md`：税码子域 + AP/AR 行 `tax_code_id`；过账规则。
- `MM_schema_design.md` / `SCM_schema_design.md` / `SD_schema_design.md`：税分类外键。
- `chartExp/Purchase/02`：转单补税率改为判定带出。
- Liquibase：`lychee-erp/src/main/resources/db/changelog/v1/2026/`（格式见 `0710-001-valuation-class-account-determination.sql`）。
- `outsource_order_items.sql`：补齐已存在的税金额列 + 本波 `tax_code_id`。

---

## 13. 与收货 / 财务 / 采购工作台

- GR 继续挂来源行；本波多复制 `tax_code_id`，单价逻辑不动。  
- AP 三单匹配、GRIR、汇差 **不改**；只改税行科目来源。  
- 采购来源清单、末次价 **不改**。  
- 工作台请求可增可选 `taxCodeId`；缺省判定。

# 变体注记与分类发号解耦 + 款色共享图片

> 日期：2026-09-15  
> 关联：`../20260911-mm-refactor-v1`（款色码矩阵）、`../20260911-mm-refactor-v2`（分类编码策略）、`../20260818-report/15-工厂订单与销售订单型号色号展示.md`（样图已按款色取）  
> 状态：设计定稿（评估可行后落文档；实现按 [04](./04-实施清单.md)）

本专题拆开 V2 绑在一起的两件事，并按拆开后的身份做产品图：

```text
物料分类 code_strategy     → 只决定 materials.code 怎么来（公式 / 流水 / 手工）
materials.is_fashion_variant → 这颗 SKU 是否占用款×色×码矩阵的那一格
产品图                     → 只在 is_fashion_variant = true 的 (款, 色) 上共享，不分尺码
```

**不是**退回 V1「有款有码就算变体」。  
**不是** Wave C 按尺码复制 `material_images`。  
**不是**把 BOM / 工厂物料改到款色层（仍按 SKU）。

主流程：

```text
分类 FASHION_VARIANT
  → 强制 is_fashion_variant = true + 公式发号 + 尺码流水 token

分类 MANUAL / SEQUENTIAL
  → 默认 false（挂款号只当属性，OEM 不占格）
  → 用户可勾选 true（须款+码齐全；分色则色在本款池）
  → 可再改回 false（资料面可逆；组合生成该格从 EXISTS 回到 NEW）

变体注记 = true 的 SKU
  → 图片读写 product_model_images(款, 色)，各尺码同一套
非变体 SKU
  → 仍用 material_images（本 SKU）
```

| 文档 | 说明 |
|------|------|
| [01-现状与问题.md](./01-现状与问题.md) | 分类与注记被绑死、图片挂 SKU、Wave C 复制为何不做 |
| [02-目标流程.md](./02-目标流程.md) | 注记写入规则、表单、图片解析、生命周期 |
| [03-schema与数据模型.md](./03-schema与数据模型.md) | `product_model_images` DDL、存量打标与迁图 |
| [04-实施清单.md](./04-实施清单.md) | **开发入口**：已锁定决策、API、改动面、验收 |

---

## 评估结论

**可行，建议做。** 分类策略与变体切面本就回答不同问题；现网 `is_fashion_variant` 的全部消费者（唯一索引、组合生成 `EXISTS`、款号锁组/锁色、三维不可变）已经按**行标记**工作，只是写入仍从分类抄过来。解开写入后，这些切面不用换钥匙。图片消费端（FO/SO）已经按 `ModelColorKey` 取图，存储仍按 SKU，是同一把错钥匙。

对话中已确认：

| # | 事项 | 结论 |
|---|------|------|
| 1 | 能否与分类解耦 | **能**。分类管发号，注记管矩阵身份 |
| 2 | MANUAL + 已选款号是否自动 true | **否**。选了款号不够，避免退回 V1 |
| 3 | MANUAL 可否声明变体 | **可**，显式勾选，默认 false |
| 4 | 勾选后可否改回 false | **可**。EXISTS 是资料面，不是系统异常；方便纠正手误 |
| 5 | 图片共享切面 | **`is_fashion_variant = true` 的 (productModelId, colorId)** |
| 6 | 与本款色池 | 不 FK `product_model_colors.id`，**写入/读取做一致性检查** |
| 7 | 存量迁图 | **仅当时已 true** 的一次性 ETL，copy OSS 到 `product-model/`；运行时禁止 SKU→款色 |
| 8 | 取消注记不删款色图 | 表行仍在。勾选 true **不**提升 SKU 图；true 只读款色图 |

其余锁定见 [04 §2](./04-实施清单.md)。

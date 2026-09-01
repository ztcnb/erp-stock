# API 接口文档

- 基础路径:`http://localhost:9102/api`
- 认证方式:除 `POST /auth/login` 外,所有接口需携带请求头 `Authorization: Bearer <token>`
- 统一响应体:

```json
{ "code": 200, "msg": "操作成功", "data": { } }
```

| code | 含义 |
| --- | --- |
| 200 | 成功 |
| 400 | 业务失败 / 参数校验失败(msg 为具体原因) |
| 401 | 未登录或登录已过期 |
| 403 | 无权限(如非管理员访问用户管理) |
| 500 | 服务器内部错误 |

- 分页接口统一返回 MyBatis-Plus 分页结构:

```json
{ "records": [], "total": 100, "size": 10, "current": 1, "pages": 10 }
```

- 分页通用参数:`page`(默认 1)、`size`(默认 10);日期参数格式 `yyyy-MM-dd`。

## 1. 认证

### POST /auth/login 登录

```json
// 请求
{ "username": "admin", "password": "123456" }
// 响应 data
{
  "token": "eyJhbGciOiJIUzM4NCJ9...",
  "user": { "id": 1, "username": "admin", "realName": "系统管理员", "role": "ADMIN" }
}
```

### GET /auth/info 当前用户信息

## 2. 用户管理(仅 ADMIN)

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /users | 分页,参数 keyword(用户名/姓名) |
| POST | /users | 新增,`{username, password?, realName, role, phone?, status?}`,密码留空默认 123456 |
| PUT | /users/{id} | 编辑,密码留空表示不修改 |
| DELETE | /users/{id} | 删除(内置 admin 与当前登录账号不可删) |

## 3. 基础资料

### 商品分类

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /categories/tree | 完整分类树(children 嵌套) |
| POST | /categories | 新增 `{name, parentId, sort}` |
| PUT | /categories/{id} | 编辑 |
| DELETE | /categories/{id} | 删除(有子分类或商品引用时拒绝) |

### 商品

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /products | 分页,参数 keyword(名称/编码)、categoryId(含子孙分类) |
| GET | /products/all | 全量在售商品(单据选择器) |
| POST | /products | 新增 `{code, name, categoryId, unit, spec?, purchasePrice, salePrice, warnQty?, status?, remark?}` |
| PUT | /products/{id} | 编辑 |
| DELETE | /products/{id} | 删除(被引用时拒绝) |

### 供应商 / 客户 / 仓库

`/suppliers`、`/customers`、`/warehouses` 提供相同风格的接口:`GET`(分页)、`GET /all`(下拉全量)、`POST`、`PUT /{id}`、`DELETE /{id}`。

## 4. 采购管理

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /purchase-orders | 分页,参数 keyword(单号/供应商)、status、startDate、endDate |
| GET | /purchase-orders/{id} | 详情(含 items 明细,明细带商品编码/名称/单位) |
| POST | /purchase-orders | 创建草稿,返回单号 |
| PUT | /purchase-orders/{id} | 编辑草稿(整单覆盖明细) |
| POST | /purchase-orders/{id}/approve | 审核:DRAFT → APPROVED |
| POST | /purchase-orders/{id}/cancel | 作废:DRAFT → CANCELED |
| POST | /purchase-orders/{id}/inbound | 入库:APPROVED → STOCKED(更新库存成本、流水、生成应付) |
| DELETE | /purchase-orders/{id} | 删除草稿/已作废单据 |

创建/编辑请求体:

```json
{
  "supplierId": 1,
  "warehouseId": 1,
  "remark": "9 月补货",
  "items": [
    { "productId": 1, "qty": 100, "price": 43.50 },
    { "productId": 4, "qty": 200, "price": 28.00 }
  ]
}
```

## 5. 销售管理

接口风格与采购完全对称,路径前缀 `/sale-orders`,业务动作为:

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | /sale-orders/{id}/approve | 审核(校验发货仓库库存充足,不足返回 400 及缺货明细) |
| POST | /sale-orders/{id}/outbound | 出库:APPROVED → SHIPPED(条件扣减防超卖、按加权平均成本核算毛利、生成应收) |

创建请求体将 `supplierId` 换为 `customerId`。已出库单据的明细行含 `costPrice`、`costAmount`,单头含 `totalCost`、`grossProfit`。

## 6. 库存管理

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /stocks | 实时库存分页,参数 warehouseId、keyword;返回含 warehouseName、productName、amount(库存金额)、warnQty |
| GET | /stocks/flows | 流水分页,参数 warehouseId、bizType、keyword(商品/单号)、startDate、endDate |
| GET | /stocks/warnings | 预警列表(总库存低于预警线),返回 code、name、total_qty、warn_qty、total_amount |

### 库存盘点

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /stock-takings | 分页,参数 status(DRAFT/FINISHED) |
| GET | /stock-takings/{id} | 详情(含明细) |
| POST | /stock-takings | 创建 `{warehouseId, remark?}`,生成账面快照,返回盘点单号 |
| PUT | /stock-takings/{id}/items | 保存实盘 `{items: [{id, actualQty}]}` |
| POST | /stock-takings/{id}/finish | 完成盘点(生成盘盈/盘亏流水并调整库存) |
| DELETE | /stock-takings/{id} | 删除盘点中的单据 |

## 7. 财务

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | /payables | 应付分页,参数 status(UNPAID/PARTIAL/PAID)、keyword(单号/供应商);返回含 balance 未付余额 |
| GET | /payables/{id}/records | 付款记录列表 |
| POST | /payables/{id}/pay | 付款登记 `{amount, method?, remark?}`,金额不得超过未付余额 |
| GET | /receivables | 应收分页,状态为 UNRECEIVED/PARTIAL/RECEIVED |
| GET | /receivables/{id}/records | 收款记录列表 |
| POST | /receivables/{id}/receive | 收款登记,规则同付款 |

## 8. 报表看板

| 方法 | 路径 | 返回 |
| --- | --- | --- |
| GET | /dashboard/summary | `{monthSaleAmount, monthProfit, monthPurchaseAmount, stockAmount, receivableBalance, payableBalance}` |
| GET | /dashboard/trend | 近 30 天数组 `[{day: "08-03", sale_amount, purchase_amount}]`(连续日期轴) |
| GET | /dashboard/top-products | 近 30 天 TOP10 `[{name, qty, amount}]` |
| GET | /dashboard/category-share | 一级分类占比 `[{name, value}]` |
| GET | /dashboard/warnings | 同 /stocks/warnings |

## 9. 错误示例

```json
// 状态机校验失败
{ "code": 400, "msg": "仅已审核的采购单可执行入库(当前状态: DRAFT)", "data": null }

// 库存不足(审核)
{ "code": 400, "msg": "商品[可口可乐 330ml*24 罐]库存不足,现有 449,需要 999999", "data": null }

// 参数校验失败
{ "code": 400, "msg": "至少需要一行明细; 供应商不能为空", "data": null }

// 未认证
{ "code": 401, "msg": "未登录或登录已过期", "data": null }
```

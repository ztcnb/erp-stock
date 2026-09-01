-- ============================================================
-- 云仓进销存 ERP 管理系统 - 数据库初始化脚本
-- 数据库: erp_stock (PostgreSQL 16)
-- 说明: 本脚本可重复执行,先删除旧表再重建,最后灌入种子数据
-- ============================================================

SET client_encoding = 'UTF8';

DROP TABLE IF EXISTS receivable_record CASCADE;
DROP TABLE IF EXISTS receivable CASCADE;
DROP TABLE IF EXISTS payable_record CASCADE;
DROP TABLE IF EXISTS payable CASCADE;
DROP TABLE IF EXISTS stock_taking_item CASCADE;
DROP TABLE IF EXISTS stock_taking CASCADE;
DROP TABLE IF EXISTS stock_flow CASCADE;
DROP TABLE IF EXISTS stock CASCADE;
DROP TABLE IF EXISTS sale_order_item CASCADE;
DROP TABLE IF EXISTS sale_order CASCADE;
DROP TABLE IF EXISTS purchase_order_item CASCADE;
DROP TABLE IF EXISTS purchase_order CASCADE;
DROP TABLE IF EXISTS warehouse CASCADE;
DROP TABLE IF EXISTS customer CASCADE;
DROP TABLE IF EXISTS supplier CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS product_category CASCADE;
DROP TABLE IF EXISTS sys_user CASCADE;

-- ---------------------------------------------
-- 系统用户表
-- ---------------------------------------------
CREATE TABLE sys_user (
    id          BIGSERIAL PRIMARY KEY,
    username    VARCHAR(50)  NOT NULL UNIQUE,
    password    VARCHAR(100) NOT NULL,
    real_name   VARCHAR(50)  NOT NULL,
    role        VARCHAR(20)  NOT NULL,
    phone       VARCHAR(20),
    status      SMALLINT     NOT NULL DEFAULT 1,
    created_at  TIMESTAMP    NOT NULL DEFAULT now()
);
COMMENT ON TABLE sys_user IS '系统用户表';
COMMENT ON COLUMN sys_user.password IS '密码(BCrypt 加密)';
COMMENT ON COLUMN sys_user.role IS '角色: ADMIN 管理员 / BUYER 采购员 / SELLER 销售员 / STOCKER 仓管员';
COMMENT ON COLUMN sys_user.status IS '状态: 1 启用 / 0 停用';

-- ---------------------------------------------
-- 商品分类表(树形结构)
-- ---------------------------------------------
CREATE TABLE product_category (
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR(50) NOT NULL,
    parent_id  BIGINT      NOT NULL DEFAULT 0,
    sort       INT         NOT NULL DEFAULT 0,
    created_at TIMESTAMP   NOT NULL DEFAULT now()
);
COMMENT ON TABLE product_category IS '商品分类表(parent_id=0 表示根分类)';

-- ---------------------------------------------
-- 商品表
-- ---------------------------------------------
CREATE TABLE product (
    id             BIGSERIAL PRIMARY KEY,
    code           VARCHAR(30)   NOT NULL UNIQUE,
    name           VARCHAR(100)  NOT NULL,
    category_id    BIGINT        NOT NULL REFERENCES product_category (id),
    unit           VARCHAR(10)   NOT NULL,
    spec           VARCHAR(50),
    purchase_price NUMERIC(18,2) NOT NULL DEFAULT 0,
    sale_price     NUMERIC(18,2) NOT NULL DEFAULT 0,
    warn_qty       NUMERIC(18,2) NOT NULL DEFAULT 0,
    status         SMALLINT      NOT NULL DEFAULT 1,
    remark         VARCHAR(200),
    created_at     TIMESTAMP     NOT NULL DEFAULT now()
);
CREATE INDEX idx_product_category ON product (category_id);
COMMENT ON TABLE product IS '商品表';
COMMENT ON COLUMN product.purchase_price IS '参考进价';
COMMENT ON COLUMN product.sale_price IS '参考售价';
COMMENT ON COLUMN product.warn_qty IS '库存预警线(总库存低于该值时预警)';

-- ---------------------------------------------
-- 供应商表
-- ---------------------------------------------
CREATE TABLE supplier (
    id         BIGSERIAL PRIMARY KEY,
    code       VARCHAR(30)  NOT NULL UNIQUE,
    name       VARCHAR(100) NOT NULL,
    contact    VARCHAR(50),
    phone      VARCHAR(20),
    address    VARCHAR(200),
    remark     VARCHAR(200),
    status     SMALLINT     NOT NULL DEFAULT 1,
    created_at TIMESTAMP    NOT NULL DEFAULT now()
);
COMMENT ON TABLE supplier IS '供应商表';

-- ---------------------------------------------
-- 客户表
-- ---------------------------------------------
CREATE TABLE customer (
    id         BIGSERIAL PRIMARY KEY,
    code       VARCHAR(30)  NOT NULL UNIQUE,
    name       VARCHAR(100) NOT NULL,
    contact    VARCHAR(50),
    phone      VARCHAR(20),
    address    VARCHAR(200),
    remark     VARCHAR(200),
    status     SMALLINT     NOT NULL DEFAULT 1,
    created_at TIMESTAMP    NOT NULL DEFAULT now()
);
COMMENT ON TABLE customer IS '客户表';

-- ---------------------------------------------
-- 仓库表
-- ---------------------------------------------
CREATE TABLE warehouse (
    id         BIGSERIAL PRIMARY KEY,
    code       VARCHAR(30)  NOT NULL UNIQUE,
    name       VARCHAR(100) NOT NULL,
    location   VARCHAR(200),
    remark     VARCHAR(200),
    status     SMALLINT     NOT NULL DEFAULT 1,
    created_at TIMESTAMP    NOT NULL DEFAULT now()
);
COMMENT ON TABLE warehouse IS '仓库表';

-- ---------------------------------------------
-- 采购订单表(单头)
-- ---------------------------------------------
CREATE TABLE purchase_order (
    id           BIGSERIAL PRIMARY KEY,
    order_no     VARCHAR(30)   NOT NULL UNIQUE,
    supplier_id  BIGINT        NOT NULL REFERENCES supplier (id),
    warehouse_id BIGINT        NOT NULL REFERENCES warehouse (id),
    status       VARCHAR(20)   NOT NULL DEFAULT 'DRAFT',
    total_qty    NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    remark       VARCHAR(200),
    created_by   BIGINT        REFERENCES sys_user (id),
    created_at   TIMESTAMP     NOT NULL DEFAULT now(),
    approved_at  TIMESTAMP,
    stocked_at   TIMESTAMP
);
CREATE INDEX idx_po_supplier ON purchase_order (supplier_id);
CREATE INDEX idx_po_status ON purchase_order (status);
CREATE INDEX idx_po_created ON purchase_order (created_at);
COMMENT ON TABLE purchase_order IS '采购订单表';
COMMENT ON COLUMN purchase_order.status IS '状态机: DRAFT 草稿 -> APPROVED 已审核 -> STOCKED 已入库; DRAFT 可作废为 CANCELED';

-- ---------------------------------------------
-- 采购订单明细表
-- ---------------------------------------------
CREATE TABLE purchase_order_item (
    id         BIGSERIAL PRIMARY KEY,
    order_id   BIGINT        NOT NULL REFERENCES purchase_order (id) ON DELETE CASCADE,
    product_id BIGINT        NOT NULL REFERENCES product (id),
    qty        NUMERIC(18,2) NOT NULL CHECK (qty > 0),
    price      NUMERIC(18,2) NOT NULL CHECK (price >= 0),
    amount     NUMERIC(18,2) NOT NULL
);
CREATE INDEX idx_poi_order ON purchase_order_item (order_id);
COMMENT ON TABLE purchase_order_item IS '采购订单明细表';

-- ---------------------------------------------
-- 销售订单表(单头)
-- ---------------------------------------------
CREATE TABLE sale_order (
    id           BIGSERIAL PRIMARY KEY,
    order_no     VARCHAR(30)   NOT NULL UNIQUE,
    customer_id  BIGINT        NOT NULL REFERENCES customer (id),
    warehouse_id BIGINT        NOT NULL REFERENCES warehouse (id),
    status       VARCHAR(20)   NOT NULL DEFAULT 'DRAFT',
    total_qty    NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    total_cost   NUMERIC(18,2) NOT NULL DEFAULT 0,
    gross_profit NUMERIC(18,2) NOT NULL DEFAULT 0,
    remark       VARCHAR(200),
    created_by   BIGINT        REFERENCES sys_user (id),
    created_at   TIMESTAMP     NOT NULL DEFAULT now(),
    approved_at  TIMESTAMP,
    shipped_at   TIMESTAMP
);
CREATE INDEX idx_so_customer ON sale_order (customer_id);
CREATE INDEX idx_so_status ON sale_order (status);
CREATE INDEX idx_so_created ON sale_order (created_at);
COMMENT ON TABLE sale_order IS '销售订单表';
COMMENT ON COLUMN sale_order.status IS '状态机: DRAFT 草稿 -> APPROVED 已审核 -> SHIPPED 已出库; DRAFT 可作废为 CANCELED';
COMMENT ON COLUMN sale_order.total_cost IS '销售成本合计(出库时按加权平均成本计算)';
COMMENT ON COLUMN sale_order.gross_profit IS '毛利 = 销售金额 - 销售成本';

-- ---------------------------------------------
-- 销售订单明细表
-- ---------------------------------------------
CREATE TABLE sale_order_item (
    id          BIGSERIAL PRIMARY KEY,
    order_id    BIGINT        NOT NULL REFERENCES sale_order (id) ON DELETE CASCADE,
    product_id  BIGINT        NOT NULL REFERENCES product (id),
    qty         NUMERIC(18,2) NOT NULL CHECK (qty > 0),
    price       NUMERIC(18,2) NOT NULL CHECK (price >= 0),
    amount      NUMERIC(18,2) NOT NULL,
    cost_price  NUMERIC(18,4) NOT NULL DEFAULT 0,
    cost_amount NUMERIC(18,2) NOT NULL DEFAULT 0
);
CREATE INDEX idx_soi_order ON sale_order_item (order_id);
COMMENT ON TABLE sale_order_item IS '销售订单明细表';
COMMENT ON COLUMN sale_order_item.cost_price IS '出库时的加权平均单位成本';

-- ---------------------------------------------
-- 库存表(仓库 + 商品 维度)
-- ---------------------------------------------
CREATE TABLE stock (
    id           BIGSERIAL PRIMARY KEY,
    warehouse_id BIGINT        NOT NULL REFERENCES warehouse (id),
    product_id   BIGINT        NOT NULL REFERENCES product (id),
    qty          NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (qty >= 0),
    avg_cost     NUMERIC(18,4) NOT NULL DEFAULT 0,
    updated_at   TIMESTAMP     NOT NULL DEFAULT now(),
    UNIQUE (warehouse_id, product_id)
);
COMMENT ON TABLE stock IS '实时库存表(数量 + 加权平均成本), CHECK 约束保证库存不出负';
COMMENT ON COLUMN stock.avg_cost IS '加权平均单位成本';

-- ---------------------------------------------
-- 库存流水表
-- ---------------------------------------------
CREATE TABLE stock_flow (
    id           BIGSERIAL PRIMARY KEY,
    warehouse_id BIGINT        NOT NULL REFERENCES warehouse (id),
    product_id   BIGINT        NOT NULL REFERENCES product (id),
    biz_type     VARCHAR(20)   NOT NULL,
    biz_no       VARCHAR(30)   NOT NULL,
    qty_change   NUMERIC(18,2) NOT NULL,
    qty_after    NUMERIC(18,2) NOT NULL,
    price        NUMERIC(18,4) NOT NULL DEFAULT 0,
    amount       NUMERIC(18,2) NOT NULL DEFAULT 0,
    remark       VARCHAR(200),
    created_at   TIMESTAMP     NOT NULL DEFAULT now()
);
CREATE INDEX idx_flow_product ON stock_flow (product_id);
CREATE INDEX idx_flow_warehouse ON stock_flow (warehouse_id);
CREATE INDEX idx_flow_created ON stock_flow (created_at);
COMMENT ON TABLE stock_flow IS '库存流水表';
COMMENT ON COLUMN stock_flow.biz_type IS '业务类型: PURCHASE_IN 采购入库 / SALE_OUT 销售出库 / TAKING_GAIN 盘盈 / TAKING_LOSS 盘亏';
COMMENT ON COLUMN stock_flow.qty_change IS '数量变动(入库为正,出库为负)';
COMMENT ON COLUMN stock_flow.qty_after IS '变动后该仓库该商品的结存数量';

-- ---------------------------------------------
-- 库存盘点单(单头)
-- ---------------------------------------------
CREATE TABLE stock_taking (
    id           BIGSERIAL PRIMARY KEY,
    taking_no    VARCHAR(30) NOT NULL UNIQUE,
    warehouse_id BIGINT      NOT NULL REFERENCES warehouse (id),
    status       VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    remark       VARCHAR(200),
    created_by   BIGINT      REFERENCES sys_user (id),
    created_at   TIMESTAMP   NOT NULL DEFAULT now(),
    finished_at  TIMESTAMP
);
COMMENT ON TABLE stock_taking IS '库存盘点单';
COMMENT ON COLUMN stock_taking.status IS '状态: DRAFT 盘点中 / FINISHED 已完成';

-- ---------------------------------------------
-- 库存盘点明细
-- ---------------------------------------------
CREATE TABLE stock_taking_item (
    id         BIGSERIAL PRIMARY KEY,
    taking_id  BIGINT        NOT NULL REFERENCES stock_taking (id) ON DELETE CASCADE,
    product_id BIGINT        NOT NULL REFERENCES product (id),
    book_qty   NUMERIC(18,2) NOT NULL DEFAULT 0,
    actual_qty NUMERIC(18,2),
    diff_qty   NUMERIC(18,2) NOT NULL DEFAULT 0
);
CREATE INDEX idx_sti_taking ON stock_taking_item (taking_id);
COMMENT ON TABLE stock_taking_item IS '库存盘点明细';
COMMENT ON COLUMN stock_taking_item.book_qty IS '账面数量(创建盘点单时的库存快照)';
COMMENT ON COLUMN stock_taking_item.diff_qty IS '盈亏数量 = 实盘 - 账面(正为盘盈,负为盘亏)';

-- ---------------------------------------------
-- 应付账款表
-- ---------------------------------------------
CREATE TABLE payable (
    id           BIGSERIAL PRIMARY KEY,
    order_no     VARCHAR(30)   NOT NULL,
    supplier_id  BIGINT        NOT NULL REFERENCES supplier (id),
    total_amount NUMERIC(18,2) NOT NULL,
    paid_amount  NUMERIC(18,2) NOT NULL DEFAULT 0,
    status       VARCHAR(20)   NOT NULL DEFAULT 'UNPAID',
    created_at   TIMESTAMP     NOT NULL DEFAULT now()
);
CREATE INDEX idx_payable_supplier ON payable (supplier_id);
COMMENT ON TABLE payable IS '应付账款表(采购入库时生成)';
COMMENT ON COLUMN payable.status IS '状态: UNPAID 未付款 / PARTIAL 部分付款 / PAID 已结清';

-- ---------------------------------------------
-- 付款记录表
-- ---------------------------------------------
CREATE TABLE payable_record (
    id         BIGSERIAL PRIMARY KEY,
    payable_id BIGINT        NOT NULL REFERENCES payable (id),
    amount     NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    pay_method VARCHAR(20)   NOT NULL DEFAULT '银行转账',
    remark     VARCHAR(200),
    created_by BIGINT        REFERENCES sys_user (id),
    created_at TIMESTAMP     NOT NULL DEFAULT now()
);
COMMENT ON TABLE payable_record IS '付款记录表(支持部分核销)';

-- ---------------------------------------------
-- 应收账款表
-- ---------------------------------------------
CREATE TABLE receivable (
    id              BIGSERIAL PRIMARY KEY,
    order_no        VARCHAR(30)   NOT NULL,
    customer_id     BIGINT        NOT NULL REFERENCES customer (id),
    total_amount    NUMERIC(18,2) NOT NULL,
    received_amount NUMERIC(18,2) NOT NULL DEFAULT 0,
    status          VARCHAR(20)   NOT NULL DEFAULT 'UNRECEIVED',
    created_at      TIMESTAMP     NOT NULL DEFAULT now()
);
CREATE INDEX idx_receivable_customer ON receivable (customer_id);
COMMENT ON TABLE receivable IS '应收账款表(销售出库时生成)';
COMMENT ON COLUMN receivable.status IS '状态: UNRECEIVED 未收款 / PARTIAL 部分收款 / RECEIVED 已结清';

-- ---------------------------------------------
-- 收款记录表
-- ---------------------------------------------
CREATE TABLE receivable_record (
    id             BIGSERIAL PRIMARY KEY,
    receivable_id  BIGINT        NOT NULL REFERENCES receivable (id),
    amount         NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    receive_method VARCHAR(20)   NOT NULL DEFAULT '银行转账',
    remark         VARCHAR(200),
    created_by     BIGINT        REFERENCES sys_user (id),
    created_at     TIMESTAMP     NOT NULL DEFAULT now()
);
COMMENT ON TABLE receivable_record IS '收款记录表(支持部分核销)';

-- ============================================================
-- 以下为种子数据(由生成器按真实业务规则模拟生成,口径自洽:
-- 库存流水汇总 = 当前库存,应收应付与已出入库单据一一对应)
-- ============================================================
-- ===== 系统用户(密码均为 123456) =====
INSERT INTO sys_user (id, username, password, real_name, role, phone, status, created_at) VALUES (1, 'admin', '$2b$10$QEKRMhX3qujI1UHszPdi1uDvefoXwYhmUacCrq/n7NJS7FagWi/4y', '系统管理员', 'ADMIN', '13800000001', 1, now() - interval '60 day');
INSERT INTO sys_user (id, username, password, real_name, role, phone, status, created_at) VALUES (2, 'buyer01', '$2b$10$QEKRMhX3qujI1UHszPdi1uDvefoXwYhmUacCrq/n7NJS7FagWi/4y', '陈采购', 'BUYER', '13800000002', 1, now() - interval '60 day');
INSERT INTO sys_user (id, username, password, real_name, role, phone, status, created_at) VALUES (3, 'seller01', '$2b$10$QEKRMhX3qujI1UHszPdi1uDvefoXwYhmUacCrq/n7NJS7FagWi/4y', '林销售', 'SELLER', '13800000003', 1, now() - interval '60 day');
INSERT INTO sys_user (id, username, password, real_name, role, phone, status, created_at) VALUES (4, 'stocker01', '$2b$10$QEKRMhX3qujI1UHszPdi1uDvefoXwYhmUacCrq/n7NJS7FagWi/4y', '王仓管', 'STOCKER', '13800000004', 1, now() - interval '60 day');

-- ===== 商品分类 =====
INSERT INTO product_category (id, name, parent_id, sort) VALUES (1, '食品饮料', 0, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (2, '日用百货', 0, 2);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (3, '数码家电', 0, 3);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (4, '酒水饮料', 1, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (5, '休闲零食', 1, 2);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (6, '粮油调味', 1, 3);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (7, '清洁用品', 2, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (8, '纸品湿巾', 2, 2);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (9, '个护美妆', 2, 3);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (10, '手机数码', 3, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (11, '小家电', 3, 2);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (12, '碳酸饮料', 4, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (13, '茶饮咖啡', 4, 2);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (14, '坚果炒货', 5, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (15, '饼干糕点', 5, 2);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (16, '食用油', 6, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (17, '调味品', 6, 2);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (18, '洗衣清洁', 7, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (19, '厨卫清洁', 7, 2);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (20, '生活用纸', 8, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (21, '洗护用品', 9, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (22, '数码配件', 10, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (23, '厨房小电', 11, 1);
INSERT INTO product_category (id, name, parent_id, sort) VALUES (24, '生活小电', 11, 2);

-- ===== 商品 =====
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (1, 'P0001', '可口可乐 330ml*24 罐', 12, '箱', '330ml*24', 43.50, 55.00, 110.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (2, 'P0002', '百事可乐 330ml*24 罐', 12, '箱', '330ml*24', 41.00, 52.00, 151.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (3, 'P0003', '雪碧 330ml*24 罐', 12, '箱', '330ml*24', 42.00, 53.00, 188.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (4, 'P0004', '农夫山泉 550ml*24 瓶', 12, '箱', '550ml*24', 28.00, 36.00, 301.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (5, 'P0005', '东方树叶乌龙茶 500ml*15', 13, '箱', '500ml*15', 52.00, 66.00, 107.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (6, 'P0006', '三得利无糖乌龙茶 500ml*15', 13, '箱', '500ml*15', 55.00, 69.00, 112.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (7, 'P0007', '雀巢速溶咖啡 1+2 原味 90条', 13, '盒', '90条/盒', 55.00, 72.00, 10.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (8, 'P0008', '隅田川咖啡液 10 条装', 13, '盒', '10条/盒', 32.00, 45.00, 118.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (9, 'P0009', '三只松鼠每日坚果 750g', 14, '盒', '25g*30袋', 62.00, 89.00, 44.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (10, 'P0010', '洽洽香瓜子 500g', 14, '袋', '500g', 9.50, 13.50, 294.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (11, 'P0011', '良品铺子碳烤腰果 190g', 14, '袋', '190g', 21.00, 29.90, 71.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (12, 'P0012', '奥利奥原味夹心饼干 466g', 15, '袋', '466g', 15.50, 21.90, 141.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (13, 'P0013', '达利园蛋黄派 1kg', 15, '袋', '1kg', 16.00, 22.50, 110.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (14, 'P0014', '好丽友巧克力派 12 枚', 15, '盒', '12枚/盒', 12.50, 17.90, 139.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (15, 'P0015', '金龙鱼黄金比例调和油 5L', 16, '桶', '5L', 52.00, 65.90, 101.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (16, 'P0016', '鲁花 5S 压榨花生油 5L', 16, '桶', '5L', 118.00, 145.00, 80.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (17, 'P0017', '海天味极鲜生抽 1.9L', 17, '瓶', '1.9L', 16.80, 22.90, 216.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (18, 'P0018', '太太乐三鲜鸡精 400g', 17, '袋', '400g', 13.50, 18.50, 35.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (19, 'P0019', '恒顺镇江香醋 550ml', 17, '瓶', '550ml', 7.80, 11.50, 225.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (20, 'P0020', '立白天然皂液 3kg', 18, '瓶', '3kg', 27.00, 36.90, 70.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (21, 'P0021', '蓝月亮深层洁净洗衣液 3kg', 18, '瓶', '3kg', 31.00, 42.90, 196.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (22, 'P0022', '威猛先生厨房重油污净 500g*2', 19, '组', '500g*2', 16.50, 23.90, 42.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (23, 'P0023', '洁厕灵洁厕液 500g*4', 19, '组', '500g*4', 14.00, 19.90, 108.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (24, 'P0024', '维达超韧抽纸 3 层*24 包', 20, '箱', '120抽*24', 42.00, 54.90, 25.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (25, 'P0025', '清风原木卷纸 27 卷', 20, '箱', '140g*27', 38.50, 49.90, 10.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (26, 'P0026', '心相印湿巾 80 抽*3 包', 20, '组', '80抽*3', 15.00, 21.90, 83.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (27, 'P0027', '海飞丝去屑洗发水 750g', 21, '瓶', '750g', 34.00, 46.90, 75.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (28, 'P0028', '舒肤佳纯白清香香皂 115g*6', 21, '组', '115g*6', 16.00, 22.90, 75.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (29, 'P0029', '高露洁全效牙膏 180g*3', 21, '组', '180g*3', 22.00, 30.90, 81.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (30, 'P0030', '罗马仕充电宝 10000mAh', 22, '个', '10000mAh', 55.00, 79.00, 25.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (31, 'P0031', '绿联 Type-C 数据线 2m', 22, '条', '2m', 12.00, 19.90, 444.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (32, 'P0032', '小米插线板 6 位 1.8m', 22, '个', '6位1.8m', 32.00, 45.00, 37.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (33, 'P0033', '倍思 33W 氮化镓充电器', 22, '个', '33W', 42.00, 62.00, 43.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (34, 'P0034', '小米手环 9 标准版', 22, '个', '标准版', 155.00, 219.00, 132.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (35, 'P0035', '漫步者蓝牙耳机 W200T', 22, '副', 'W200T', 88.00, 129.00, 49.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (36, 'P0036', '九阳豆浆机 DJ13B', 23, '台', '1.3L', 195.00, 269.00, 27.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (37, 'P0037', '美的电饭煲 4L', 23, '台', '4L', 215.00, 299.00, 129.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (38, 'P0038', '苏泊尔电水壶 1.7L', 23, '台', '1.7L', 78.00, 109.00, 127.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (39, 'P0039', '小熊养生壶 1.5L', 23, '台', '1.5L', 92.00, 129.00, 26.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (40, 'P0040', '米家 LED 台灯 Pro', 24, '台', 'Pro', 128.00, 169.00, 24.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (41, 'P0041', '飞利浦电动牙刷 HX2431', 24, '支', 'HX2431', 145.00, 199.00, 39.00, 1, now() - interval '50 day');
INSERT INTO product (id, code, name, category_id, unit, spec, purchase_price, sale_price, warn_qty, status, created_at) VALUES (42, 'P0042', '美的七叶落地扇 FSA30', 24, '台', 'FSA30', 118.00, 159.00, 39.00, 1, now() - interval '50 day');

-- ===== 供应商 =====
INSERT INTO supplier (id, code, name, contact, phone, address, status, created_at) VALUES (1, 'GYS001', '广州华南食品贸易有限公司', '刘志强', '13711112222', '广州市白云区机场路 128 号', 1, now() - interval '55 day');
INSERT INTO supplier (id, code, name, contact, phone, address, status, created_at) VALUES (2, 'GYS002', '深圳康达日化供应链有限公司', '张美玲', '13822223333', '深圳市宝安区西乡大道 56 号', 1, now() - interval '55 day');
INSERT INTO supplier (id, code, name, contact, phone, address, status, created_at) VALUES (3, 'GYS003', '东莞市恒信粮油批发部', '陈国华', '13933334444', '东莞市南城区莞太路 89 号', 1, now() - interval '55 day');
INSERT INTO supplier (id, code, name, contact, phone, address, status, created_at) VALUES (4, 'GYS004', '杭州云商数码科技有限公司', '吴晓峰', '13744445555', '杭州市滨江区江南大道 200 号', 1, now() - interval '55 day');
INSERT INTO supplier (id, code, name, contact, phone, address, status, created_at) VALUES (5, 'GYS005', '佛山市顺德小家电制造有限公司', '梁永康', '13655556666', '佛山市顺德区容桂街道工业大道 33 号', 1, now() - interval '55 day');
INSERT INTO supplier (id, code, name, contact, phone, address, status, created_at) VALUES (6, 'GYS006', '上海纸业联合供应有限公司', '周静', '13566667777', '上海市青浦区华新镇纪鹤公路 500 号', 1, now() - interval '55 day');
INSERT INTO supplier (id, code, name, contact, phone, address, status, created_at) VALUES (7, 'GYS007', '厦门闽南茶饮供应链有限公司', '林建发', '13477778888', '厦门市集美区杏林湾路 18 号', 1, now() - interval '55 day');
INSERT INTO supplier (id, code, name, contact, phone, address, status, created_at) VALUES (8, 'GYS008', '成都西部快消品集散中心', '赵刚', '13388889999', '成都市双流区物流大道 66 号', 1, now() - interval '55 day');

-- ===== 客户 =====
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (1, 'KH001', '好又多连锁超市(番禺店)', '何丽华', '13611110001', '广州市番禺区市桥街道', 1, now() - interval '55 day');
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (2, 'KH002', '天天鲜便利店', '钟伟明', '13611110002', '广州市天河区体育西路', 1, now() - interval '55 day');
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (3, 'KH003', '优选生活电商有限公司', '苏婉婷', '13611110003', '深圳市南山区科技园', 1, now() - interval '55 day');
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (4, 'KH004', '百惠批发商行', '郑永强', '13611110004', '佛山市禅城区批发市场 A 区', 1, now() - interval '55 day');
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (5, 'KH005', '悦客连锁便利(东莞)', '罗嘉欣', '13611110005', '东莞市东城区东纵大道', 1, now() - interval '55 day');
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (6, 'KH006', '星辰母婴生活馆', '朱静怡', '13611110006', '中山市石岐区中山路', 1, now() - interval '55 day');
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (7, 'KH007', '汇丰食品商贸部', '许志豪', '13611110007', '惠州市惠城区江北街道', 1, now() - interval '55 day');
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (8, 'KH008', '乐购社区团购平台', '高敏', '13611110008', '广州市海珠区新港东路', 1, now() - interval '55 day');
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (9, 'KH009', '鑫源酒店用品公司', '孙建军', '13611110009', '珠海市香洲区吉大路', 1, now() - interval '55 day');
INSERT INTO customer (id, code, name, contact, phone, address, status, created_at) VALUES (10, 'KH010', '拼拼严选电商', '曾丽君', '13611110010', '深圳市龙岗区坂田街道', 1, now() - interval '55 day');

-- ===== 仓库 =====
INSERT INTO warehouse (id, code, name, location, status, created_at) VALUES (1, 'WH01', '广州总仓', '广州市黄埔区云埔工业区 3 号仓', 1, now() - interval '58 day');
INSERT INTO warehouse (id, code, name, location, status, created_at) VALUES (2, 'WH02', '深圳分仓', '深圳市龙华区观澜物流园 B2 仓', 1, now() - interval '58 day');

-- ===== 采购订单 =====
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (1, 'PO20260729-0001', 1, 1, 'STOCKED', 856.00, 33471.72, NULL, 2, '2026-07-29 10:56:30', '2026-07-29 12:48:30', '2026-07-29 17:07:30');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (2, 'PO20260729-0002', 8, 1, 'STOCKED', 993.00, 30024.15, NULL, 2, '2026-07-29 10:08:13', '2026-07-29 11:58:13', '2026-07-29 15:06:13');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (3, 'PO20260729-0003', 5, 2, 'STOCKED', 1043.00, 27058.96, NULL, 2, '2026-07-29 11:02:22', '2026-07-29 12:13:22', '2026-07-29 16:43:22');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (4, 'PO20260730-0001', 8, 2, 'STOCKED', 428.00, 19499.47, NULL, 2, '2026-07-30 10:50:33', '2026-07-30 12:30:33', '2026-07-30 15:38:33');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (5, 'PO20260730-0002', 7, 2, 'STOCKED', 903.00, 19754.52, NULL, 2, '2026-07-30 09:21:34', '2026-07-30 10:03:34', '2026-07-30 13:37:34');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (6, 'PO20260730-0003', 7, 1, 'STOCKED', 1014.00, 23525.27, NULL, 2, '2026-07-30 10:33:22', '2026-07-30 11:05:22', '2026-07-30 12:08:22');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (7, 'PO20260731-0001', 7, 1, 'STOCKED', 513.00, 24824.87, NULL, 2, '2026-07-31 09:07:54', '2026-07-31 10:01:54', '2026-07-31 11:26:54');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (8, 'PO20260731-0002', 1, 1, 'STOCKED', 604.00, 21434.86, NULL, 2, '2026-07-31 10:34:05', '2026-07-31 12:25:05', '2026-07-31 14:36:05');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (9, 'PO20260731-0003', 1, 1, 'STOCKED', 766.00, 13260.28, NULL, 2, '2026-07-31 10:29:47', '2026-07-31 11:56:47', '2026-07-31 16:51:47');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (10, 'PO20260801-0001', 6, 1, 'STOCKED', 475.00, 12984.27, NULL, 2, '2026-08-01 08:28:38', '2026-08-01 09:31:38', '2026-08-01 13:50:38');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (11, 'PO20260801-0002', 3, 2, 'STOCKED', 818.00, 16774.55, NULL, 2, '2026-08-01 11:49:00', '2026-08-01 13:37:00', '2026-08-01 17:15:00');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (12, 'PO20260801-0003', 5, 1, 'STOCKED', 506.00, 33553.41, NULL, 2, '2026-08-01 11:03:50', '2026-08-01 12:35:50', '2026-08-01 13:44:50');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (13, 'PO20260802-0001', 3, 1, 'STOCKED', 775.00, 20207.45, NULL, 2, '2026-08-02 11:49:27', '2026-08-02 12:50:27', '2026-08-02 14:28:27');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (14, 'PO20260803-0001', 8, 2, 'STOCKED', 944.00, 26912.09, NULL, 2, '2026-08-03 08:08:00', '2026-08-03 09:44:00', '2026-08-03 14:17:00');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (15, 'PO20260804-0001', 4, 2, 'STOCKED', 508.00, 14455.26, NULL, 2, '2026-08-04 10:13:11', '2026-08-04 10:55:11', '2026-08-04 15:23:11');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (16, 'PO20260805-0001', 8, 2, 'STOCKED', 340.00, 22907.50, NULL, 2, '2026-08-05 10:57:13', '2026-08-05 12:12:13', '2026-08-05 14:16:13');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (17, 'PO20260807-0001', 5, 2, 'STOCKED', 584.00, 16996.96, NULL, 2, '2026-08-07 10:06:15', '2026-08-07 11:29:15', '2026-08-07 13:48:15');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (18, 'PO20260809-0001', 5, 2, 'STOCKED', 202.00, 10868.45, NULL, 2, '2026-08-09 08:45:57', '2026-08-09 09:31:57', '2026-08-09 12:22:57');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (19, 'PO20260811-0001', 7, 1, 'STOCKED', 621.00, 32686.96, NULL, 2, '2026-08-11 08:03:21', '2026-08-11 09:49:21', '2026-08-11 10:59:21');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (20, 'PO20260813-0001', 1, 1, 'STOCKED', 547.00, 16288.23, NULL, 2, '2026-08-13 09:46:07', '2026-08-13 10:32:07', '2026-08-13 12:23:07');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (21, 'PO20260814-0001', 5, 2, 'STOCKED', 591.00, 12137.92, NULL, 2, '2026-08-14 08:42:38', '2026-08-14 10:42:38', '2026-08-14 12:17:38');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (22, 'PO20260815-0001', 8, 2, 'STOCKED', 621.00, 16064.89, NULL, 2, '2026-08-15 09:21:16', '2026-08-15 10:53:16', '2026-08-15 13:40:16');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (23, 'PO20260816-0001', 3, 1, 'STOCKED', 787.00, 20861.06, NULL, 2, '2026-08-16 09:04:28', '2026-08-16 09:52:28', '2026-08-16 10:54:28');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (24, 'PO20260821-0001', 1, 1, 'STOCKED', 464.00, 17711.67, NULL, 2, '2026-08-21 09:54:43', '2026-08-21 10:59:43', '2026-08-21 12:23:43');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (25, 'PO20260824-0001', 3, 1, 'STOCKED', 527.00, 39532.01, NULL, 2, '2026-08-24 10:38:24', '2026-08-24 12:18:24', '2026-08-24 15:29:24');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (26, 'PO20260825-0001', 7, 1, 'STOCKED', 128.00, 16444.44, NULL, 2, '2026-08-25 11:00:47', '2026-08-25 12:45:47', '2026-08-25 13:58:47');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (27, 'PO20260826-0001', 3, 1, 'STOCKED', 722.00, 35419.89, NULL, 2, '2026-08-26 09:34:14', '2026-08-26 10:49:14', '2026-08-26 12:49:14');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (28, 'PO20260827-0001', 7, 2, 'STOCKED', 461.00, 16995.13, NULL, 2, '2026-08-27 09:56:37', '2026-08-27 10:46:37', '2026-08-27 12:53:37');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (29, 'PO20260828-0001', 6, 2, 'STOCKED', 962.00, 33401.32, NULL, 2, '2026-08-28 11:46:18', '2026-08-28 12:44:18', '2026-08-28 17:00:18');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (30, 'PO20260830-0001', 6, 2, 'STOCKED', 1014.00, 18360.85, NULL, 2, '2026-08-30 11:31:42', '2026-08-30 12:14:42', '2026-08-30 15:02:42');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (31, 'PO20260831-0001', 8, 2, 'STOCKED', 582.00, 25713.14, NULL, 2, '2026-08-31 11:57:26', '2026-08-31 13:26:26', '2026-08-31 16:46:26');
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (32, 'PO20260830-0002', 6, 1, 'APPROVED', 508.00, 33401.06, NULL, 2, '2026-08-30 10:17:07', '2026-08-30 11:41:07', NULL);
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (33, 'PO20260831-0002', 6, 2, 'APPROVED', 336.00, 15919.01, NULL, 2, '2026-08-31 08:54:24', '2026-08-31 10:28:24', NULL);
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (34, 'PO20260831-0003', 6, 2, 'DRAFT', 239.00, 24937.16, NULL, 2, '2026-08-31 08:38:31', NULL, NULL);
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (35, 'PO20260830-0003', 3, 1, 'DRAFT', 546.00, 16053.15, NULL, 2, '2026-08-30 10:37:55', NULL, NULL);
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (36, 'PO20260829-0001', 6, 2, 'DRAFT', 357.00, 6865.79, NULL, 2, '2026-08-29 09:04:21', NULL, NULL);
INSERT INTO purchase_order (id, order_no, supplier_id, warehouse_id, status, total_qty, total_amount, remark, created_by, created_at, approved_at, stocked_at) VALUES (37, 'PO20260827-0002', 8, 2, 'CANCELED', 869.00, 31645.07, '供应商缺货,单据作废', 2, '2026-08-27 10:15:01', NULL, NULL);

-- ===== 采购订单明细 =====
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (1, 1, 11, 140.00, 20.18, 2825.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (2, 1, 17, 239.00, 16.83, 4022.37);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (3, 1, 1, 253.00, 42.78, 10823.34);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (4, 1, 21, 171.00, 31.44, 5376.24);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (5, 1, 36, 53.00, 196.69, 10424.57);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (6, 2, 19, 272.00, 7.64, 2078.08);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (7, 2, 16, 63.00, 120.83, 7612.29);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (8, 2, 4, 235.00, 28.95, 6803.25);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (9, 2, 23, 66.00, 14.22, 938.52);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (10, 2, 2, 149.00, 41.57, 6193.93);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (11, 2, 21, 208.00, 30.76, 6398.08);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (12, 3, 28, 124.00, 15.78, 1956.72);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (13, 3, 2, 113.00, 41.14, 4648.82);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (14, 3, 4, 333.00, 27.74, 9237.42);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (15, 3, 23, 154.00, 13.98, 2152.92);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (16, 3, 15, 112.00, 50.24, 5626.88);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (17, 3, 17, 207.00, 16.60, 3436.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (18, 4, 4, 233.00, 27.45, 6395.85);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (19, 4, 16, 68.00, 113.40, 7711.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (20, 4, 1, 127.00, 42.46, 5392.42);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (21, 5, 33, 158.00, 43.95, 6944.10);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (22, 5, 31, 529.00, 11.93, 6310.97);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (23, 5, 26, 175.00, 15.07, 2637.25);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (24, 5, 39, 41.00, 94.20, 3862.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (25, 6, 10, 220.00, 9.65, 2123.00);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (26, 6, 26, 103.00, 15.36, 1582.08);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (27, 6, 11, 160.00, 21.62, 3459.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (28, 6, 24, 228.00, 43.84, 9995.52);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (29, 6, 19, 254.00, 7.50, 1905.00);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (30, 6, 35, 49.00, 91.03, 4460.47);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (31, 7, 35, 85.00, 87.28, 7418.80);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (32, 7, 6, 125.00, 57.34, 7167.50);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (33, 7, 12, 212.00, 14.99, 3177.88);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (34, 7, 38, 91.00, 77.59, 7060.69);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (35, 8, 28, 149.00, 16.00, 2384.00);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (36, 8, 27, 131.00, 32.50, 4257.50);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (37, 8, 41, 30.00, 142.72, 4281.60);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (38, 8, 17, 144.00, 16.55, 2383.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (39, 8, 42, 46.00, 118.40, 5446.40);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (40, 8, 20, 104.00, 25.79, 2682.16);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (41, 9, 31, 327.00, 11.67, 3816.09);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (42, 9, 13, 143.00, 15.55, 2223.65);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (43, 9, 12, 262.00, 15.95, 4178.90);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (44, 9, 39, 34.00, 89.46, 3041.64);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (45, 10, 2, 232.00, 39.81, 9235.92);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (46, 10, 14, 152.00, 12.01, 1825.52);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (47, 10, 29, 91.00, 21.13, 1922.83);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (48, 11, 21, 156.00, 31.01, 4837.56);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (49, 11, 4, 146.00, 29.08, 4245.68);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (50, 11, 12, 120.00, 15.32, 1838.40);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (51, 11, 26, 81.00, 14.98, 1213.38);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (52, 11, 13, 168.00, 15.69, 2635.92);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (53, 11, 23, 147.00, 13.63, 2003.61);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (54, 12, 6, 137.00, 56.99, 7807.63);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (55, 12, 16, 56.00, 121.67, 6813.52);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (56, 12, 8, 103.00, 32.38, 3335.14);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (57, 12, 36, 51.00, 192.79, 9832.29);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (58, 12, 22, 87.00, 16.69, 1452.03);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (59, 12, 9, 72.00, 59.90, 4312.80);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (60, 13, 1, 233.00, 44.90, 10461.70);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (61, 13, 10, 289.00, 9.08, 2624.12);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (62, 13, 22, 75.00, 16.35, 1226.25);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (63, 13, 13, 98.00, 16.41, 1608.18);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (64, 13, 30, 80.00, 53.59, 4287.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (65, 14, 17, 280.00, 16.69, 4673.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (66, 14, 14, 194.00, 12.01, 2329.94);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (67, 14, 36, 27.00, 191.44, 5168.88);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (68, 14, 4, 270.00, 29.13, 7865.10);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (69, 14, 42, 41.00, 117.49, 4817.09);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (70, 14, 28, 132.00, 15.59, 2057.88);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (71, 15, 5, 94.00, 52.80, 4963.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (72, 15, 4, 211.00, 28.90, 6097.90);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (73, 15, 13, 203.00, 16.72, 3394.16);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (74, 16, 16, 113.00, 116.75, 13192.75);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (75, 16, 32, 186.00, 32.53, 6050.58);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (76, 16, 39, 41.00, 89.37, 3664.17);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (77, 17, 3, 206.00, 41.76, 8602.56);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (78, 17, 20, 125.00, 27.05, 3381.25);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (79, 17, 22, 81.00, 15.87, 1285.47);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (80, 17, 19, 150.00, 8.03, 1204.50);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (81, 17, 42, 22.00, 114.69, 2523.18);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (82, 18, 39, 35.00, 89.32, 3126.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (83, 18, 6, 76.00, 52.60, 3997.60);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (84, 18, 33, 91.00, 41.15, 3744.65);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (85, 19, 6, 50.00, 54.41, 2720.50);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (86, 19, 38, 72.00, 78.09, 5622.48);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (87, 19, 17, 265.00, 17.30, 4584.50);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (88, 19, 34, 53.00, 160.90, 8527.70);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (89, 19, 42, 50.00, 120.15, 6007.50);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (90, 19, 2, 131.00, 39.88, 5224.28);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (91, 20, 41, 47.00, 138.49, 6509.03);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (92, 20, 6, 110.00, 56.39, 6202.90);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (93, 20, 10, 390.00, 9.17, 3576.30);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (94, 21, 21, 119.00, 30.76, 3660.44);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (95, 21, 19, 364.00, 8.06, 2933.84);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (96, 21, 15, 108.00, 51.33, 5543.64);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (97, 22, 15, 192.00, 50.57, 9709.44);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (98, 22, 10, 389.00, 9.65, 3753.85);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (99, 22, 9, 40.00, 65.04, 2601.60);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (100, 23, 31, 313.00, 12.48, 3906.24);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (101, 23, 21, 139.00, 31.65, 4399.35);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (102, 23, 12, 111.00, 16.01, 1777.11);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (103, 23, 3, 178.00, 43.76, 7789.28);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (104, 23, 9, 46.00, 64.98, 2989.08);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (105, 24, 11, 95.00, 20.52, 1949.40);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (106, 24, 20, 157.00, 26.28, 4125.96);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (107, 24, 27, 95.00, 34.05, 3234.75);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (108, 24, 42, 35.00, 120.84, 4229.40);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (109, 24, 5, 82.00, 50.88, 4172.16);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (110, 25, 27, 108.00, 35.04, 3784.32);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (111, 25, 5, 161.00, 53.09, 8547.49);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (112, 25, 12, 102.00, 14.83, 1512.66);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (113, 25, 37, 41.00, 225.19, 9232.79);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (114, 25, 34, 58.00, 156.74, 9090.92);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (115, 25, 40, 57.00, 129.19, 7363.83);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (116, 26, 30, 58.00, 56.24, 3261.92);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (117, 26, 37, 38.00, 221.14, 8403.32);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (118, 26, 41, 32.00, 149.35, 4779.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (119, 27, 9, 46.00, 60.98, 2805.08);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (120, 27, 21, 154.00, 30.64, 4718.56);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (121, 27, 16, 68.00, 120.17, 8171.56);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (122, 27, 18, 171.00, 13.78, 2356.38);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (123, 27, 3, 175.00, 43.97, 7694.75);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (124, 27, 35, 108.00, 89.57, 9673.56);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (125, 28, 2, 165.00, 40.49, 6680.85);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (126, 28, 3, 202.00, 43.82, 8851.64);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (127, 28, 26, 94.00, 15.56, 1462.64);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (128, 29, 3, 84.00, 42.26, 3549.84);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (129, 29, 5, 160.00, 51.78, 8284.80);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (130, 29, 40, 56.00, 129.00, 7224.00);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (131, 29, 21, 114.00, 31.82, 3627.48);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (132, 29, 31, 500.00, 12.56, 6280.00);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (133, 29, 35, 48.00, 92.40, 4435.20);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (134, 30, 14, 193.00, 12.64, 2439.52);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (135, 30, 41, 41.00, 141.10, 5785.10);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (136, 30, 10, 196.00, 9.17, 1797.32);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (137, 30, 31, 349.00, 11.71, 4086.79);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (138, 30, 29, 112.00, 22.81, 2554.72);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (139, 30, 23, 123.00, 13.80, 1697.40);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (140, 31, 14, 200.00, 12.66, 2532.00);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (141, 31, 28, 75.00, 16.74, 1255.50);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (142, 31, 37, 35.00, 217.47, 7611.45);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (143, 31, 29, 121.00, 22.40, 2710.40);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (144, 31, 15, 108.00, 49.50, 5346.00);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (145, 31, 41, 43.00, 145.53, 6257.79);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (146, 32, 3, 174.00, 41.94, 7297.56);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (147, 32, 37, 60.00, 214.46, 12867.60);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (148, 32, 30, 90.00, 56.77, 5109.30);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (149, 32, 8, 90.00, 32.59, 2933.10);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (150, 32, 6, 94.00, 55.25, 5193.50);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (151, 33, 10, 233.00, 9.59, 2234.47);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (152, 33, 7, 47.00, 57.14, 2685.58);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (153, 33, 36, 56.00, 196.41, 10998.96);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (154, 34, 27, 112.00, 33.11, 3708.32);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (155, 34, 37, 60.00, 206.28, 12376.80);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (156, 34, 40, 67.00, 132.12, 8852.04);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (157, 35, 42, 28.00, 122.80, 3438.40);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (158, 35, 23, 83.00, 14.14, 1173.62);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (159, 35, 22, 166.00, 16.12, 2675.92);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (160, 35, 28, 156.00, 16.63, 2594.28);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (161, 35, 6, 113.00, 54.61, 6170.93);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (162, 36, 23, 102.00, 13.97, 1424.94);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (163, 36, 11, 119.00, 20.91, 2488.29);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (164, 36, 29, 136.00, 21.71, 2952.56);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (165, 37, 3, 162.00, 40.94, 6632.28);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (166, 37, 25, 172.00, 37.99, 6534.28);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (167, 37, 38, 46.00, 76.98, 3541.08);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (168, 37, 31, 289.00, 11.47, 3314.83);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (169, 37, 6, 124.00, 54.18, 6718.32);
INSERT INTO purchase_order_item (id, order_id, product_id, qty, price, amount) VALUES (170, 37, 9, 76.00, 64.53, 4904.28);

-- ===== 销售订单 =====
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (1, 'SO20260802-0001', 7, 2, 'SHIPPED', 34.00, 788.55, 553.74, 234.81, NULL, 3, '2026-08-02 13:16:13', '2026-08-02 13:57:13', '2026-08-02 17:53:13');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (2, 'SO20260803-0001', 9, 2, 'SHIPPED', 189.00, 6332.05, 4381.98, 1950.07, NULL, 3, '2026-08-03 09:45:43', '2026-08-03 10:29:43', '2026-08-03 14:17:43');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (3, 'SO20260804-0001', 7, 1, 'SHIPPED', 63.00, 2804.75, 2044.28, 760.47, NULL, 3, '2026-08-04 14:43:56', '2026-08-04 16:08:56', '2026-08-04 19:26:56');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (4, 'SO20260804-0002', 4, 2, 'SHIPPED', 102.00, 3189.33, 2268.40, 920.93, NULL, 3, '2026-08-04 16:49:29', '2026-08-04 18:02:29', '2026-08-04 21:45:29');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (5, 'SO20260805-0001', 9, 2, 'SHIPPED', 125.00, 5566.18, 4069.41, 1496.77, NULL, 3, '2026-08-05 13:47:47', '2026-08-05 15:14:47', '2026-08-05 18:33:47');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (6, 'SO20260806-0001', 8, 1, 'SHIPPED', 67.00, 4550.14, 3127.37, 1422.77, NULL, 3, '2026-08-06 13:08:13', '2026-08-06 13:32:13', '2026-08-06 15:44:13');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (7, 'SO20260807-0001', 1, 2, 'SHIPPED', 120.00, 3856.42, 2857.98, 998.44, NULL, 3, '2026-08-07 10:04:02', '2026-08-07 10:24:02', '2026-08-07 11:42:02');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (8, 'SO20260808-0001', 4, 2, 'SHIPPED', 12.00, 2375.68, 1696.88, 678.80, NULL, 3, '2026-08-08 17:53:08', '2026-08-08 19:15:08', '2026-08-08 21:55:08');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (9, 'SO20260808-0002', 9, 1, 'SHIPPED', 168.00, 8284.11, 5856.60, 2427.51, NULL, 3, '2026-08-08 09:52:41', '2026-08-08 10:39:41', '2026-08-08 14:39:41');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (10, 'SO20260809-0001', 10, 2, 'SHIPPED', 99.00, 4138.29, 3097.62, 1040.67, NULL, 3, '2026-08-09 14:31:04', '2026-08-09 15:28:04', '2026-08-09 16:46:04');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (11, 'SO20260809-0002', 4, 2, 'SHIPPED', 116.00, 3578.94, 2679.18, 899.76, NULL, 3, '2026-08-09 12:39:11', '2026-08-09 13:28:11', '2026-08-09 16:13:11');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (12, 'SO20260810-0001', 8, 1, 'SHIPPED', 69.00, 2866.68, 2223.81, 642.87, NULL, 3, '2026-08-10 17:01:51', '2026-08-10 17:35:51', '2026-08-10 19:40:51');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (13, 'SO20260811-0001', 9, 1, 'SHIPPED', 88.00, 3847.85, 2687.27, 1160.58, NULL, 3, '2026-08-11 14:45:52', '2026-08-11 15:18:52', '2026-08-11 17:38:52');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (14, 'SO20260811-0002', 7, 2, 'SHIPPED', 57.00, 2348.73, 1696.29, 652.44, NULL, 3, '2026-08-11 15:09:12', '2026-08-11 16:26:12', '2026-08-11 17:56:12');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (15, 'SO20260812-0001', 6, 1, 'SHIPPED', 138.00, 5668.74, 4196.72, 1472.02, NULL, 3, '2026-08-12 16:25:29', '2026-08-12 17:42:29', '2026-08-12 19:33:29');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (16, 'SO20260812-0002', 2, 1, 'SHIPPED', 60.00, 2340.91, 1632.21, 708.70, NULL, 3, '2026-08-12 14:30:10', '2026-08-12 15:04:10', '2026-08-12 17:37:10');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (17, 'SO20260813-0001', 8, 2, 'SHIPPED', 68.00, 5818.07, 4553.97, 1264.10, NULL, 3, '2026-08-13 15:49:39', '2026-08-13 16:40:39', '2026-08-13 19:44:39');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (18, 'SO20260813-0002', 7, 1, 'SHIPPED', 142.00, 4591.55, 3279.32, 1312.23, NULL, 3, '2026-08-13 14:23:06', '2026-08-13 15:52:06', '2026-08-13 17:04:06');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (19, 'SO20260814-0001', 4, 1, 'SHIPPED', 73.00, 3979.26, 2920.54, 1058.72, NULL, 3, '2026-08-14 15:27:39', '2026-08-14 16:06:39', '2026-08-14 17:13:39');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (20, 'SO20260814-0002', 4, 2, 'SHIPPED', 115.00, 3756.76, 2767.78, 988.98, NULL, 3, '2026-08-14 14:08:20', '2026-08-14 15:07:20', '2026-08-14 19:00:20');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (21, 'SO20260815-0001', 2, 2, 'SHIPPED', 118.00, 2780.26, 2063.90, 716.36, NULL, 3, '2026-08-15 17:51:16', '2026-08-15 18:56:16', '2026-08-15 20:06:16');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (22, 'SO20260816-0001', 8, 1, 'SHIPPED', 62.00, 3308.42, 2322.89, 985.53, NULL, 3, '2026-08-16 13:12:50', '2026-08-16 14:31:50', '2026-08-16 17:41:50');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (23, 'SO20260816-0002', 1, 2, 'SHIPPED', 58.00, 5623.70, 4003.51, 1620.19, NULL, 3, '2026-08-16 11:12:40', '2026-08-16 12:06:40', '2026-08-16 13:15:40');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (24, 'SO20260817-0001', 6, 1, 'SHIPPED', 124.00, 5742.44, 4367.55, 1374.89, NULL, 3, '2026-08-17 17:30:44', '2026-08-17 18:04:44', '2026-08-17 21:54:44');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (25, 'SO20260817-0002', 2, 2, 'SHIPPED', 80.00, 3643.35, 2747.94, 895.41, NULL, 3, '2026-08-17 11:10:05', '2026-08-17 11:33:05', '2026-08-17 14:05:05');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (26, 'SO20260818-0001', 6, 1, 'SHIPPED', 125.00, 7081.11, 5156.65, 1924.46, NULL, 3, '2026-08-18 11:22:59', '2026-08-18 11:50:59', '2026-08-18 13:42:59');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (27, 'SO20260819-0001', 4, 2, 'SHIPPED', 109.00, 3706.61, 2656.25, 1050.36, NULL, 3, '2026-08-19 17:12:42', '2026-08-19 18:21:42', '2026-08-19 21:30:42');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (28, 'SO20260820-0001', 6, 2, 'SHIPPED', 80.00, 4998.90, 3788.93, 1209.97, NULL, 3, '2026-08-20 14:03:07', '2026-08-20 15:18:07', '2026-08-20 17:55:07');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (29, 'SO20260821-0001', 9, 1, 'SHIPPED', 146.00, 3943.01, 2823.29, 1119.72, NULL, 3, '2026-08-21 11:47:07', '2026-08-21 12:17:07', '2026-08-21 13:49:07');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (30, 'SO20260822-0001', 4, 1, 'SHIPPED', 43.00, 4792.16, 3383.75, 1408.41, NULL, 3, '2026-08-22 11:21:31', '2026-08-22 12:21:31', '2026-08-22 16:03:31');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (31, 'SO20260823-0001', 8, 2, 'SHIPPED', 24.00, 1586.40, 1124.96, 461.44, NULL, 3, '2026-08-23 11:45:07', '2026-08-23 12:23:07', '2026-08-23 13:32:07');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (32, 'SO20260823-0002', 10, 1, 'SHIPPED', 75.00, 5178.37, 3915.44, 1262.93, NULL, 3, '2026-08-23 12:21:13', '2026-08-23 13:39:13', '2026-08-23 15:59:13');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (33, 'SO20260824-0001', 7, 1, 'SHIPPED', 158.00, 4593.26, 3376.77, 1216.49, NULL, 3, '2026-08-24 13:09:33', '2026-08-24 13:38:33', '2026-08-24 16:33:33');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (34, 'SO20260825-0001', 2, 2, 'SHIPPED', 82.00, 2653.24, 2054.70, 598.54, NULL, 3, '2026-08-25 10:07:28', '2026-08-25 11:00:28', '2026-08-25 14:32:28');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (35, 'SO20260826-0001', 6, 2, 'SHIPPED', 37.00, 2114.45, 1491.87, 622.58, NULL, 3, '2026-08-26 16:02:12', '2026-08-26 17:28:12', '2026-08-26 19:41:12');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (36, 'SO20260826-0002', 6, 1, 'SHIPPED', 79.00, 7395.50, 5254.16, 2141.34, NULL, 3, '2026-08-26 11:43:53', '2026-08-26 12:12:53', '2026-08-26 15:18:53');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (37, 'SO20260827-0001', 7, 1, 'SHIPPED', 84.00, 4669.41, 3410.76, 1258.65, NULL, 3, '2026-08-27 13:21:52', '2026-08-27 14:18:52', '2026-08-27 17:25:52');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (38, 'SO20260827-0002', 10, 1, 'SHIPPED', 162.00, 6783.47, 5035.83, 1747.64, NULL, 3, '2026-08-27 13:51:16', '2026-08-27 14:56:16', '2026-08-27 16:25:16');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (39, 'SO20260828-0001', 8, 1, 'SHIPPED', 150.00, 5647.18, 4303.94, 1343.24, NULL, 3, '2026-08-28 10:51:48', '2026-08-28 11:21:48', '2026-08-28 13:55:48');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (40, 'SO20260828-0002', 2, 2, 'SHIPPED', 105.00, 5797.44, 4348.50, 1448.94, NULL, 3, '2026-08-28 15:43:46', '2026-08-28 17:00:46', '2026-08-28 19:21:46');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (41, 'SO20260829-0001', 7, 1, 'SHIPPED', 77.00, 4098.40, 2926.97, 1171.43, NULL, 3, '2026-08-29 10:53:37', '2026-08-29 11:34:37', '2026-08-29 13:11:37');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (42, 'SO20260830-0001', 10, 1, 'SHIPPED', 69.00, 3042.79, 2327.04, 715.75, NULL, 3, '2026-08-30 12:21:33', '2026-08-30 13:00:33', '2026-08-30 16:22:33');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (43, 'SO20260831-0001', 6, 2, 'SHIPPED', 87.00, 5961.55, 4570.36, 1391.19, NULL, 3, '2026-08-31 09:14:32', '2026-08-31 10:38:32', '2026-08-31 12:28:32');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (44, 'SO20260831-0002', 4, 1, 'SHIPPED', 73.00, 2341.88, 1738.93, 602.95, NULL, 3, '2026-08-31 09:41:42', '2026-08-31 10:05:42', '2026-08-31 13:35:42');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (45, 'SO20260901-0001', 1, 2, 'SHIPPED', 35.00, 4674.25, 3394.77, 1279.48, NULL, 3, '2026-09-01 12:50:13', '2026-09-01 13:39:13', '2026-09-01 15:54:13');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (46, 'SO20260901-0002', 9, 1, 'SHIPPED', 112.00, 7811.60, 6214.41, 1597.19, NULL, 3, '2026-09-01 15:45:48', '2026-09-01 16:06:48', '2026-09-01 17:08:48');
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (47, 'SO20260831-0003', 9, 1, 'APPROVED', 56.00, 4415.20, 0.00, 0.00, NULL, 3, '2026-08-31 11:48:57', '2026-08-31 13:08:57', NULL);
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (48, 'SO20260830-0002', 4, 1, 'APPROVED', 47.00, 2178.35, 0.00, 0.00, NULL, 3, '2026-08-30 09:47:09', '2026-08-30 10:25:09', NULL);
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (49, 'SO20260831-0004', 8, 2, 'APPROVED', 111.00, 6245.73, 0.00, 0.00, NULL, 3, '2026-08-31 10:53:24', '2026-08-31 12:02:24', NULL);
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (50, 'SO20260831-0005', 4, 2, 'DRAFT', 111.00, 4369.30, 0.00, 0.00, NULL, 3, '2026-08-31 11:35:36', NULL, NULL);
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (51, 'SO20260830-0003', 4, 2, 'DRAFT', 133.00, 4833.93, 0.00, 0.00, NULL, 3, '2026-08-30 14:31:33', NULL, NULL);
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (52, 'SO20260829-0002', 6, 2, 'DRAFT', 43.00, 3522.40, 0.00, 0.00, NULL, 3, '2026-08-29 15:06:04', NULL, NULL);
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (53, 'SO20260830-0004', 9, 2, 'DRAFT', 90.00, 3519.22, 0.00, 0.00, NULL, 3, '2026-08-30 14:25:21', NULL, NULL);
INSERT INTO sale_order (id, order_no, customer_id, warehouse_id, status, total_qty, total_amount, total_cost, gross_profit, remark, created_by, created_at, approved_at, shipped_at) VALUES (54, 'SO20260826-0003', 8, 2, 'CANCELED', 85.00, 2487.89, 0.00, 0.00, '客户取消订单', 3, '2026-08-26 15:53:08', NULL, NULL);

-- ===== 销售订单明细 =====
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (1, 1, 28, 13.00, 22.89, 297.57, 15.7800, 205.14);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (2, 1, 17, 21.00, 23.38, 490.98, 16.6000, 348.60);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (3, 2, 36, 6.00, 274.51, 1647.06, 191.4400, 1148.64);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (4, 2, 42, 7.00, 154.87, 1084.09, 117.4900, 822.43);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (5, 2, 14, 52.00, 18.33, 953.16, 12.0100, 624.52);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (6, 2, 31, 59.00, 20.21, 1192.39, 11.9300, 703.87);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (7, 2, 17, 65.00, 22.39, 1455.35, 16.6541, 1082.52);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (8, 3, 21, 24.00, 42.30, 1015.20, 31.0668, 745.60);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (9, 3, 38, 11.00, 106.61, 1172.71, 77.5900, 853.49);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (10, 3, 13, 28.00, 22.03, 616.84, 15.8997, 445.19);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (11, 4, 21, 24.00, 42.51, 1020.24, 31.0100, 744.24);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (12, 4, 33, 11.00, 61.57, 677.27, 43.9500, 483.45);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (13, 4, 12, 27.00, 22.26, 601.02, 15.3200, 413.64);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (14, 4, 28, 40.00, 22.27, 890.80, 15.6768, 627.07);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (15, 5, 15, 36.00, 63.99, 2303.64, 50.2400, 1808.64);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (16, 5, 14, 23.00, 17.92, 412.16, 12.0100, 276.23);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (17, 5, 33, 34.00, 62.63, 2129.42, 43.9500, 1494.30);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (18, 5, 12, 32.00, 22.53, 720.96, 15.3200, 490.24);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (19, 6, 11, 15.00, 30.42, 456.30, 20.9480, 314.22);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (20, 6, 38, 10.00, 108.76, 1087.60, 77.5900, 775.90);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (21, 6, 14, 22.00, 17.92, 394.24, 12.0100, 264.22);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (22, 6, 35, 20.00, 130.60, 2612.00, 88.6513, 1773.03);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (23, 7, 19, 46.00, 11.41, 524.86, 8.0300, 369.38);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (24, 7, 20, 26.00, 37.50, 975.00, 27.0500, 703.30);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (25, 7, 2, 26.00, 52.34, 1360.84, 41.1400, 1069.64);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (26, 7, 32, 22.00, 45.26, 995.72, 32.5300, 715.66);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (27, 8, 42, 8.00, 163.51, 1308.08, 116.3900, 931.12);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (28, 8, 36, 4.00, 266.90, 1067.60, 191.4400, 765.76);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (29, 9, 1, 36.00, 56.32, 2027.52, 43.7964, 1576.67);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (30, 9, 35, 20.00, 125.87, 2517.40, 88.6513, 1773.03);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (31, 9, 41, 10.00, 195.56, 1955.60, 142.7200, 1427.20);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (32, 9, 19, 27.00, 11.42, 308.34, 7.5724, 204.45);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (33, 9, 31, 75.00, 19.67, 1475.25, 11.6700, 875.25);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (34, 10, 19, 36.00, 11.17, 402.12, 8.0300, 289.08);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (35, 10, 39, 10.00, 132.41, 1324.10, 91.0476, 910.48);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (36, 10, 1, 28.00, 54.69, 1531.32, 42.4600, 1188.88);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (37, 10, 4, 25.00, 35.23, 880.75, 28.3671, 709.18);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (38, 11, 26, 37.00, 21.47, 794.39, 15.0415, 556.54);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (39, 11, 13, 47.00, 22.65, 1064.55, 16.2536, 763.92);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (40, 11, 1, 32.00, 53.75, 1720.00, 42.4600, 1358.72);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (41, 12, 17, 24.00, 23.22, 557.28, 16.7247, 401.39);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (42, 12, 2, 45.00, 51.32, 2309.40, 40.4983, 1822.42);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (43, 13, 11, 24.00, 30.46, 731.04, 20.9480, 502.75);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (44, 13, 41, 7.00, 202.78, 1419.46, 142.7200, 999.04);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (45, 13, 10, 35.00, 13.56, 474.60, 9.3264, 326.42);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (46, 13, 13, 15.00, 22.25, 333.75, 15.8997, 238.50);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (47, 13, 35, 7.00, 127.00, 889.00, 88.6513, 620.56);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (48, 14, 20, 18.00, 36.82, 662.76, 27.0500, 486.90);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (49, 14, 21, 39.00, 43.23, 1685.97, 31.0100, 1209.39);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (50, 15, 24, 35.00, 56.46, 1976.10, 43.8400, 1534.40);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (51, 15, 10, 57.00, 13.11, 747.27, 9.3264, 531.60);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (52, 15, 38, 15.00, 108.69, 1630.35, 77.8435, 1167.65);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (53, 15, 21, 31.00, 42.42, 1315.02, 31.0668, 963.07);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (54, 16, 27, 22.00, 47.40, 1042.80, 32.5000, 715.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (55, 16, 14, 31.00, 17.58, 544.98, 12.0100, 372.31);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (56, 16, 38, 7.00, 107.59, 753.13, 77.8435, 544.90);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (57, 17, 16, 25.00, 146.89, 3672.25, 115.4914, 2887.29);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (58, 17, 21, 12.00, 42.16, 505.92, 31.0100, 372.12);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (59, 17, 3, 31.00, 52.90, 1639.90, 41.7600, 1294.56);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (60, 18, 21, 12.00, 42.66, 511.92, 31.0668, 372.80);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (61, 18, 2, 31.00, 53.19, 1648.89, 40.3249, 1250.07);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (62, 18, 4, 29.00, 35.76, 1037.04, 28.9500, 839.55);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (63, 18, 31, 70.00, 19.91, 1393.70, 11.6700, 816.90);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (64, 19, 24, 15.00, 53.80, 807.00, 43.8400, 657.60);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (65, 19, 41, 11.00, 194.43, 2138.73, 139.4065, 1533.47);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (66, 19, 12, 47.00, 21.99, 1033.53, 15.5206, 729.47);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (67, 20, 23, 20.00, 19.69, 393.80, 13.8091, 276.18);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (68, 20, 21, 41.00, 42.46, 1740.86, 30.8613, 1265.31);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (69, 20, 19, 31.00, 11.23, 348.13, 8.0553, 249.71);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (70, 20, 1, 23.00, 55.39, 1273.97, 42.4600, 976.58);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (71, 21, 13, 35.00, 22.52, 788.20, 16.2536, 568.88);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (72, 21, 15, 14.00, 64.08, 897.12, 50.7216, 710.10);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (73, 21, 12, 21.00, 21.74, 456.54, 15.3200, 321.72);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (74, 21, 10, 48.00, 13.30, 638.40, 9.6500, 463.20);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (75, 22, 38, 18.00, 108.61, 1954.98, 77.8435, 1401.18);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (76, 22, 11, 44.00, 30.76, 1353.44, 20.9480, 921.71);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (77, 23, 36, 5.00, 262.59, 1312.95, 191.4400, 957.20);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (78, 23, 33, 14.00, 62.45, 874.30, 42.7010, 597.81);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (79, 23, 39, 15.00, 128.03, 1920.45, 91.0476, 1365.71);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (80, 23, 21, 20.00, 43.27, 865.40, 30.8613, 617.23);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (81, 23, 42, 4.00, 162.65, 650.60, 116.3900, 465.56);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (82, 24, 6, 21.00, 68.90, 1446.90, 56.6316, 1189.26);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (83, 24, 24, 25.00, 53.32, 1333.00, 43.8400, 1096.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (84, 24, 21, 34.00, 42.75, 1453.50, 31.2465, 1062.38);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (85, 24, 26, 35.00, 22.40, 784.00, 15.3600, 537.60);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (86, 24, 30, 9.00, 80.56, 725.04, 53.5900, 482.31);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (87, 25, 32, 17.00, 44.57, 757.69, 32.5300, 553.01);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (88, 25, 3, 23.00, 52.02, 1196.46, 41.7600, 960.48);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (89, 25, 21, 40.00, 42.23, 1689.20, 30.8613, 1234.45);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (90, 26, 22, 18.00, 23.29, 419.22, 16.5326, 297.59);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (91, 26, 35, 22.00, 126.97, 2793.34, 88.6513, 1950.33);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (92, 26, 8, 25.00, 46.15, 1153.75, 32.3800, 809.50);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (93, 26, 9, 11.00, 88.04, 968.44, 61.8803, 680.68);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (94, 26, 4, 49.00, 35.64, 1746.36, 28.9500, 1418.55);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (95, 27, 23, 22.00, 19.48, 428.56, 13.8091, 303.80);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (96, 27, 26, 28.00, 21.63, 605.64, 15.0415, 421.16);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (97, 27, 13, 46.00, 22.36, 1028.56, 16.2536, 747.67);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (98, 27, 39, 13.00, 126.45, 1643.85, 91.0476, 1183.62);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (99, 28, 15, 46.00, 65.18, 2998.28, 50.7216, 2333.19);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (100, 28, 20, 28.00, 36.58, 1024.24, 27.0500, 757.40);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (101, 28, 42, 6.00, 162.73, 976.38, 116.3900, 698.34);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (102, 29, 10, 85.00, 13.12, 1115.20, 9.2508, 786.32);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (103, 29, 36, 6.00, 270.61, 1623.66, 194.7775, 1168.67);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (104, 29, 12, 45.00, 21.39, 962.55, 15.6216, 702.97);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (105, 29, 22, 10.00, 24.16, 241.60, 16.5326, 165.33);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (106, 30, 20, 13.00, 37.76, 490.88, 26.0848, 339.10);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (107, 30, 34, 12.00, 222.45, 2669.40, 160.9000, 1930.80);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (108, 30, 9, 18.00, 90.66, 1631.88, 61.8803, 1113.85);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (109, 31, 39, 10.00, 127.91, 1279.10, 91.0476, 910.48);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (110, 31, 12, 14.00, 21.95, 307.30, 15.3200, 214.48);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (111, 32, 34, 12.00, 213.79, 2565.48, 160.9000, 1930.80);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (112, 32, 5, 28.00, 64.28, 1799.84, 50.8800, 1424.64);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (113, 32, 28, 35.00, 23.23, 813.05, 16.0000, 560.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (114, 33, 17, 35.00, 23.25, 813.75, 16.9690, 593.92);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (115, 33, 31, 37.00, 19.76, 731.12, 12.1822, 450.74);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (116, 33, 12, 59.00, 22.05, 1300.95, 15.4859, 913.67);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (117, 33, 5, 27.00, 64.72, 1747.44, 52.5349, 1418.44);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (118, 34, 2, 30.00, 50.78, 1523.40, 41.1400, 1234.20);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (119, 34, 23, 16.00, 19.45, 311.20, 13.8091, 220.95);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (120, 34, 17, 36.00, 22.74, 818.64, 16.6541, 599.55);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (121, 35, 22, 28.00, 23.66, 662.48, 15.8700, 444.36);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (122, 35, 42, 9.00, 161.33, 1451.97, 116.3900, 1047.51);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (123, 36, 30, 28.00, 77.42, 2167.76, 54.7815, 1533.88);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (124, 36, 40, 5.00, 165.20, 826.00, 129.1900, 645.95);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (125, 36, 35, 19.00, 129.44, 2459.36, 89.2248, 1695.27);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (126, 36, 20, 23.00, 37.10, 853.30, 26.0848, 599.95);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (127, 36, 36, 4.00, 272.27, 1089.08, 194.7775, 779.11);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (128, 37, 27, 13.00, 48.09, 625.17, 33.8512, 440.07);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (129, 37, 5, 20.00, 67.80, 1356.00, 52.5349, 1050.70);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (130, 37, 38, 19.00, 109.84, 2086.96, 77.8435, 1479.03);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (131, 37, 18, 32.00, 18.79, 601.28, 13.7800, 440.96);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (132, 38, 6, 21.00, 70.57, 1481.97, 56.6316, 1189.26);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (133, 38, 37, 11.00, 295.28, 3248.08, 223.2419, 2455.66);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (134, 38, 10, 82.00, 13.58, 1113.56, 9.2508, 758.57);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (135, 38, 14, 34.00, 18.30, 622.20, 12.0100, 408.34);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (136, 38, 28, 14.00, 22.69, 317.66, 16.0000, 224.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (137, 39, 6, 10.00, 71.05, 710.50, 56.6316, 566.32);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (138, 39, 28, 26.00, 22.80, 592.80, 16.0000, 416.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (139, 39, 26, 23.00, 22.02, 506.46, 15.3600, 353.28);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (140, 39, 24, 53.00, 56.10, 2973.30, 43.8400, 2323.52);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (141, 39, 17, 38.00, 22.74, 864.12, 16.9690, 644.82);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (142, 40, 40, 13.00, 169.64, 2205.32, 129.0000, 1677.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (143, 40, 4, 54.00, 35.31, 1906.74, 28.3671, 1531.82);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (144, 40, 33, 20.00, 63.38, 1267.60, 42.7010, 854.02);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (145, 40, 22, 18.00, 23.21, 417.78, 15.8700, 285.66);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (146, 41, 14, 22.00, 18.15, 399.30, 12.0100, 264.22);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (147, 41, 2, 15.00, 53.30, 799.50, 40.3249, 604.87);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (148, 41, 11, 30.00, 29.87, 896.10, 20.8177, 624.53);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (149, 41, 41, 10.00, 200.35, 2003.50, 143.3348, 1433.35);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (150, 42, 28, 25.00, 23.31, 582.75, 16.0000, 400.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (151, 42, 1, 44.00, 55.91, 2460.04, 43.7964, 1927.04);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (152, 43, 1, 15.00, 55.39, 830.85, 42.4600, 636.90);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (153, 43, 4, 62.00, 35.80, 2219.60, 28.3671, 1758.76);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (154, 43, 37, 10.00, 291.11, 2911.10, 217.4700, 2174.70);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (155, 44, 42, 5.00, 154.36, 771.80, 119.7199, 598.60);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (156, 44, 17, 54.00, 23.04, 1244.16, 16.9690, 916.33);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (157, 44, 28, 14.00, 23.28, 325.92, 16.0000, 224.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (158, 45, 15, 20.00, 66.77, 1335.40, 50.4104, 1008.21);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (159, 45, 37, 8.00, 303.72, 2429.76, 217.4700, 1739.76);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (160, 45, 35, 7.00, 129.87, 909.09, 92.4000, 646.80);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (161, 46, 2, 38.00, 53.09, 2017.42, 40.3249, 1532.35);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (162, 46, 28, 12.00, 23.51, 282.12, 16.0000, 192.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (163, 46, 16, 23.00, 148.70, 3420.10, 120.8416, 2779.36);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (164, 46, 3, 39.00, 53.64, 2091.96, 43.8641, 1710.70);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (165, 47, 1, 48.00, 55.80, 2678.40, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (166, 47, 34, 8.00, 217.10, 1736.80, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (167, 48, 26, 12.00, 22.25, 267.00, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (168, 48, 24, 35.00, 54.61, 1911.35, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (169, 49, 16, 15.00, 149.26, 2238.90, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (170, 49, 13, 24.00, 22.75, 546.00, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (171, 49, 21, 35.00, 43.92, 1537.20, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (172, 49, 3, 37.00, 51.99, 1923.63, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (173, 50, 37, 5.00, 299.70, 1498.50, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (174, 50, 33, 34.00, 60.40, 2053.60, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (175, 50, 19, 72.00, 11.35, 817.20, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (176, 51, 2, 40.00, 53.50, 2140.00, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (177, 51, 1, 10.00, 54.07, 540.70, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (178, 51, 20, 18.00, 36.52, 657.36, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (179, 51, 12, 9.00, 22.35, 201.15, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (180, 51, 17, 56.00, 23.12, 1294.72, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (181, 52, 39, 15.00, 126.28, 1894.20, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (182, 52, 42, 7.00, 163.36, 1143.52, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (183, 52, 17, 21.00, 23.08, 484.68, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (184, 53, 31, 40.00, 20.47, 818.80, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (185, 53, 20, 18.00, 37.01, 666.18, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (186, 53, 33, 32.00, 63.57, 2034.24, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (187, 54, 15, 18.00, 64.33, 1157.94, 0.0000, 0.00);
INSERT INTO sale_order_item (id, order_id, product_id, qty, price, amount, cost_price, cost_amount) VALUES (188, 54, 31, 67.00, 19.85, 1329.95, 0.0000, 0.00);

-- ===== 实时库存 =====
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (1, 1, 11, 282.00, 20.8177, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (2, 1, 17, 497.00, 16.9690, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (3, 1, 1, 409.00, 43.7964, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (4, 1, 21, 571.00, 31.0829, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (5, 1, 36, 94.00, 194.7775, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (6, 1, 19, 499.00, 7.5724, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (7, 1, 16, 164.00, 120.8416, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (8, 1, 4, 153.00, 28.9500, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (9, 1, 23, 66.00, 14.2200, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (10, 1, 2, 381.00, 40.3249, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (11, 2, 28, 278.00, 15.9636, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (12, 2, 2, 222.00, 40.6569, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (13, 2, 4, 1052.00, 28.3671, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (14, 2, 23, 366.00, 13.8060, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (15, 2, 15, 404.00, 50.4104, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (16, 2, 17, 365.00, 16.6541, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (17, 2, 16, 156.00, 115.4914, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (18, 2, 1, 29.00, 42.4600, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (19, 2, 33, 170.00, 42.7010, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (20, 2, 31, 1319.00, 12.1106, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (21, 2, 26, 285.00, 15.2125, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (22, 2, 39, 69.00, 91.0476, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (23, 1, 10, 640.00, 9.2508, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (24, 1, 26, 45.00, 15.3600, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (25, 1, 24, 100.00, 43.8400, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (26, 1, 35, 154.00, 89.2248, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (27, 1, 6, 370.00, 56.6316, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (28, 1, 12, 536.00, 15.4859, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (29, 1, 38, 83.00, 77.8435, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (30, 1, 28, 23.00, 16.0000, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (31, 1, 27, 299.00, 33.8512, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (32, 1, 41, 71.00, 143.3348, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (33, 1, 42, 126.00, 119.7199, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (34, 1, 20, 225.00, 26.0848, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (35, 1, 31, 458.00, 12.1822, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (36, 1, 13, 198.00, 15.8997, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (37, 1, 39, 34.00, 89.4600, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (38, 1, 14, 43.00, 12.0100, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (39, 1, 29, 91.00, 21.1300, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (40, 2, 21, 213.00, 31.3744, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (41, 2, 12, 26.00, 15.3200, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (42, 2, 13, 243.00, 16.2536, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (43, 1, 8, 77.00, 32.3800, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (44, 1, 22, 134.00, 16.5326, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (45, 1, 9, 137.00, 61.5735, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (46, 1, 30, 101.00, 54.7815, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (47, 2, 3, 438.00, 42.8060, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (48, 2, 5, 254.00, 52.1575, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (49, 2, 6, 76.00, 52.6000, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (50, 2, 9, 40.00, 65.0400, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (51, 2, 10, 537.00, 9.4748, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (52, 2, 14, 512.00, 12.5014, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (53, 2, 19, 401.00, 8.0553, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (54, 2, 20, 53.00, 27.0500, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (55, 2, 22, 35.00, 15.8700, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (56, 2, 29, 233.00, 22.5971, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (57, 2, 32, 147.00, 32.5300, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (58, 2, 35, 41.00, 92.4000, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (59, 2, 36, 12.00, 191.4400, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (60, 2, 37, 17.00, 217.4700, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (61, 2, 40, 43.00, 129.0000, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (62, 2, 41, 84.00, 143.3677, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (63, 2, 42, 29.00, 116.3900, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (64, 1, 3, 314.00, 43.8641, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (65, 1, 5, 173.00, 52.5349, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (66, 1, 18, 139.00, 13.7800, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (67, 1, 34, 87.00, 158.1267, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (68, 1, 37, 68.00, 223.2419, now());
INSERT INTO stock (id, warehouse_id, product_id, qty, avg_cost, updated_at) VALUES (69, 1, 40, 52.00, 129.1900, now());

-- ===== 库存流水 =====
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (1, 1, 11, 'PURCHASE_IN', 'PO20260729-0001', 140.00, 140.00, 20.1800, 2825.20, '采购入库', '2026-07-29 17:07:30');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (2, 1, 17, 'PURCHASE_IN', 'PO20260729-0001', 239.00, 239.00, 16.8300, 4022.37, '采购入库', '2026-07-29 17:07:30');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (3, 1, 1, 'PURCHASE_IN', 'PO20260729-0001', 253.00, 253.00, 42.7800, 10823.34, '采购入库', '2026-07-29 17:07:30');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (4, 1, 21, 'PURCHASE_IN', 'PO20260729-0001', 171.00, 171.00, 31.4400, 5376.24, '采购入库', '2026-07-29 17:07:30');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (5, 1, 36, 'PURCHASE_IN', 'PO20260729-0001', 53.00, 53.00, 196.6900, 10424.57, '采购入库', '2026-07-29 17:07:30');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (6, 1, 19, 'PURCHASE_IN', 'PO20260729-0002', 272.00, 272.00, 7.6400, 2078.08, '采购入库', '2026-07-29 15:06:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (7, 1, 16, 'PURCHASE_IN', 'PO20260729-0002', 63.00, 63.00, 120.8300, 7612.29, '采购入库', '2026-07-29 15:06:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (8, 1, 4, 'PURCHASE_IN', 'PO20260729-0002', 235.00, 235.00, 28.9500, 6803.25, '采购入库', '2026-07-29 15:06:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (9, 1, 23, 'PURCHASE_IN', 'PO20260729-0002', 66.00, 66.00, 14.2200, 938.52, '采购入库', '2026-07-29 15:06:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (10, 1, 2, 'PURCHASE_IN', 'PO20260729-0002', 149.00, 149.00, 41.5700, 6193.93, '采购入库', '2026-07-29 15:06:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (11, 1, 21, 'PURCHASE_IN', 'PO20260729-0002', 208.00, 379.00, 30.7600, 6398.08, '采购入库', '2026-07-29 15:06:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (12, 2, 28, 'PURCHASE_IN', 'PO20260729-0003', 124.00, 124.00, 15.7800, 1956.72, '采购入库', '2026-07-29 16:43:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (13, 2, 2, 'PURCHASE_IN', 'PO20260729-0003', 113.00, 113.00, 41.1400, 4648.82, '采购入库', '2026-07-29 16:43:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (14, 2, 4, 'PURCHASE_IN', 'PO20260729-0003', 333.00, 333.00, 27.7400, 9237.42, '采购入库', '2026-07-29 16:43:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (15, 2, 23, 'PURCHASE_IN', 'PO20260729-0003', 154.00, 154.00, 13.9800, 2152.92, '采购入库', '2026-07-29 16:43:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (16, 2, 15, 'PURCHASE_IN', 'PO20260729-0003', 112.00, 112.00, 50.2400, 5626.88, '采购入库', '2026-07-29 16:43:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (17, 2, 17, 'PURCHASE_IN', 'PO20260729-0003', 207.00, 207.00, 16.6000, 3436.20, '采购入库', '2026-07-29 16:43:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (18, 2, 4, 'PURCHASE_IN', 'PO20260730-0001', 233.00, 566.00, 27.4500, 6395.85, '采购入库', '2026-07-30 15:38:33');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (19, 2, 16, 'PURCHASE_IN', 'PO20260730-0001', 68.00, 68.00, 113.4000, 7711.20, '采购入库', '2026-07-30 15:38:33');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (20, 2, 1, 'PURCHASE_IN', 'PO20260730-0001', 127.00, 127.00, 42.4600, 5392.42, '采购入库', '2026-07-30 15:38:33');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (21, 2, 33, 'PURCHASE_IN', 'PO20260730-0002', 158.00, 158.00, 43.9500, 6944.10, '采购入库', '2026-07-30 13:37:34');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (22, 2, 31, 'PURCHASE_IN', 'PO20260730-0002', 529.00, 529.00, 11.9300, 6310.97, '采购入库', '2026-07-30 13:37:34');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (23, 2, 26, 'PURCHASE_IN', 'PO20260730-0002', 175.00, 175.00, 15.0700, 2637.25, '采购入库', '2026-07-30 13:37:34');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (24, 2, 39, 'PURCHASE_IN', 'PO20260730-0002', 41.00, 41.00, 94.2000, 3862.20, '采购入库', '2026-07-30 13:37:34');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (25, 1, 10, 'PURCHASE_IN', 'PO20260730-0003', 220.00, 220.00, 9.6500, 2123.00, '采购入库', '2026-07-30 12:08:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (26, 1, 26, 'PURCHASE_IN', 'PO20260730-0003', 103.00, 103.00, 15.3600, 1582.08, '采购入库', '2026-07-30 12:08:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (27, 1, 11, 'PURCHASE_IN', 'PO20260730-0003', 160.00, 300.00, 21.6200, 3459.20, '采购入库', '2026-07-30 12:08:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (28, 1, 24, 'PURCHASE_IN', 'PO20260730-0003', 228.00, 228.00, 43.8400, 9995.52, '采购入库', '2026-07-30 12:08:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (29, 1, 19, 'PURCHASE_IN', 'PO20260730-0003', 254.00, 526.00, 7.5000, 1905.00, '采购入库', '2026-07-30 12:08:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (30, 1, 35, 'PURCHASE_IN', 'PO20260730-0003', 49.00, 49.00, 91.0300, 4460.47, '采购入库', '2026-07-30 12:08:22');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (31, 1, 35, 'PURCHASE_IN', 'PO20260731-0001', 85.00, 134.00, 87.2800, 7418.80, '采购入库', '2026-07-31 11:26:54');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (32, 1, 6, 'PURCHASE_IN', 'PO20260731-0001', 125.00, 125.00, 57.3400, 7167.50, '采购入库', '2026-07-31 11:26:54');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (33, 1, 12, 'PURCHASE_IN', 'PO20260731-0001', 212.00, 212.00, 14.9900, 3177.88, '采购入库', '2026-07-31 11:26:54');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (34, 1, 38, 'PURCHASE_IN', 'PO20260731-0001', 91.00, 91.00, 77.5900, 7060.69, '采购入库', '2026-07-31 11:26:54');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (35, 1, 28, 'PURCHASE_IN', 'PO20260731-0002', 149.00, 149.00, 16.0000, 2384.00, '采购入库', '2026-07-31 14:36:05');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (36, 1, 27, 'PURCHASE_IN', 'PO20260731-0002', 131.00, 131.00, 32.5000, 4257.50, '采购入库', '2026-07-31 14:36:05');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (37, 1, 41, 'PURCHASE_IN', 'PO20260731-0002', 30.00, 30.00, 142.7200, 4281.60, '采购入库', '2026-07-31 14:36:05');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (38, 1, 17, 'PURCHASE_IN', 'PO20260731-0002', 144.00, 383.00, 16.5500, 2383.20, '采购入库', '2026-07-31 14:36:05');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (39, 1, 42, 'PURCHASE_IN', 'PO20260731-0002', 46.00, 46.00, 118.4000, 5446.40, '采购入库', '2026-07-31 14:36:05');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (40, 1, 20, 'PURCHASE_IN', 'PO20260731-0002', 104.00, 104.00, 25.7900, 2682.16, '采购入库', '2026-07-31 14:36:05');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (41, 1, 31, 'PURCHASE_IN', 'PO20260731-0003', 327.00, 327.00, 11.6700, 3816.09, '采购入库', '2026-07-31 16:51:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (42, 1, 13, 'PURCHASE_IN', 'PO20260731-0003', 143.00, 143.00, 15.5500, 2223.65, '采购入库', '2026-07-31 16:51:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (43, 1, 12, 'PURCHASE_IN', 'PO20260731-0003', 262.00, 474.00, 15.9500, 4178.90, '采购入库', '2026-07-31 16:51:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (44, 1, 39, 'PURCHASE_IN', 'PO20260731-0003', 34.00, 34.00, 89.4600, 3041.64, '采购入库', '2026-07-31 16:51:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (45, 1, 2, 'PURCHASE_IN', 'PO20260801-0001', 232.00, 381.00, 39.8100, 9235.92, '采购入库', '2026-08-01 13:50:38');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (46, 1, 14, 'PURCHASE_IN', 'PO20260801-0001', 152.00, 152.00, 12.0100, 1825.52, '采购入库', '2026-08-01 13:50:38');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (47, 1, 29, 'PURCHASE_IN', 'PO20260801-0001', 91.00, 91.00, 21.1300, 1922.83, '采购入库', '2026-08-01 13:50:38');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (48, 2, 21, 'PURCHASE_IN', 'PO20260801-0002', 156.00, 156.00, 31.0100, 4837.56, '采购入库', '2026-08-01 17:15:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (49, 2, 4, 'PURCHASE_IN', 'PO20260801-0002', 146.00, 712.00, 29.0800, 4245.68, '采购入库', '2026-08-01 17:15:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (50, 2, 12, 'PURCHASE_IN', 'PO20260801-0002', 120.00, 120.00, 15.3200, 1838.40, '采购入库', '2026-08-01 17:15:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (51, 2, 26, 'PURCHASE_IN', 'PO20260801-0002', 81.00, 256.00, 14.9800, 1213.38, '采购入库', '2026-08-01 17:15:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (52, 2, 13, 'PURCHASE_IN', 'PO20260801-0002', 168.00, 168.00, 15.6900, 2635.92, '采购入库', '2026-08-01 17:15:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (53, 2, 23, 'PURCHASE_IN', 'PO20260801-0002', 147.00, 301.00, 13.6300, 2003.61, '采购入库', '2026-08-01 17:15:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (54, 1, 6, 'PURCHASE_IN', 'PO20260801-0003', 137.00, 262.00, 56.9900, 7807.63, '采购入库', '2026-08-01 13:44:50');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (55, 1, 16, 'PURCHASE_IN', 'PO20260801-0003', 56.00, 119.00, 121.6700, 6813.52, '采购入库', '2026-08-01 13:44:50');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (56, 1, 8, 'PURCHASE_IN', 'PO20260801-0003', 103.00, 103.00, 32.3800, 3335.14, '采购入库', '2026-08-01 13:44:50');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (57, 1, 36, 'PURCHASE_IN', 'PO20260801-0003', 51.00, 104.00, 192.7900, 9832.29, '采购入库', '2026-08-01 13:44:50');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (58, 1, 22, 'PURCHASE_IN', 'PO20260801-0003', 87.00, 87.00, 16.6900, 1452.03, '采购入库', '2026-08-01 13:44:50');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (59, 1, 9, 'PURCHASE_IN', 'PO20260801-0003', 72.00, 72.00, 59.9000, 4312.80, '采购入库', '2026-08-01 13:44:50');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (60, 1, 1, 'PURCHASE_IN', 'PO20260802-0001', 233.00, 486.00, 44.9000, 10461.70, '采购入库', '2026-08-02 14:28:27');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (61, 1, 10, 'PURCHASE_IN', 'PO20260802-0001', 289.00, 509.00, 9.0800, 2624.12, '采购入库', '2026-08-02 14:28:27');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (62, 1, 22, 'PURCHASE_IN', 'PO20260802-0001', 75.00, 162.00, 16.3500, 1226.25, '采购入库', '2026-08-02 14:28:27');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (63, 1, 13, 'PURCHASE_IN', 'PO20260802-0001', 98.00, 241.00, 16.4100, 1608.18, '采购入库', '2026-08-02 14:28:27');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (64, 1, 30, 'PURCHASE_IN', 'PO20260802-0001', 80.00, 80.00, 53.5900, 4287.20, '采购入库', '2026-08-02 14:28:27');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (65, 2, 28, 'SALE_OUT', 'SO20260802-0001', -13.00, 111.00, 15.7800, 205.14, '销售出库', '2026-08-02 17:53:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (66, 2, 17, 'SALE_OUT', 'SO20260802-0001', -21.00, 186.00, 16.6000, 348.60, '销售出库', '2026-08-02 17:53:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (67, 2, 17, 'PURCHASE_IN', 'PO20260803-0001', 280.00, 466.00, 16.6900, 4673.20, '采购入库', '2026-08-03 14:17:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (68, 2, 14, 'PURCHASE_IN', 'PO20260803-0001', 194.00, 194.00, 12.0100, 2329.94, '采购入库', '2026-08-03 14:17:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (69, 2, 36, 'PURCHASE_IN', 'PO20260803-0001', 27.00, 27.00, 191.4400, 5168.88, '采购入库', '2026-08-03 14:17:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (70, 2, 4, 'PURCHASE_IN', 'PO20260803-0001', 270.00, 982.00, 29.1300, 7865.10, '采购入库', '2026-08-03 14:17:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (71, 2, 42, 'PURCHASE_IN', 'PO20260803-0001', 41.00, 41.00, 117.4900, 4817.09, '采购入库', '2026-08-03 14:17:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (72, 2, 28, 'PURCHASE_IN', 'PO20260803-0001', 132.00, 243.00, 15.5900, 2057.88, '采购入库', '2026-08-03 14:17:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (73, 2, 36, 'SALE_OUT', 'SO20260803-0001', -6.00, 21.00, 191.4400, 1148.64, '销售出库', '2026-08-03 14:17:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (74, 2, 42, 'SALE_OUT', 'SO20260803-0001', -7.00, 34.00, 117.4900, 822.43, '销售出库', '2026-08-03 14:17:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (75, 2, 14, 'SALE_OUT', 'SO20260803-0001', -52.00, 142.00, 12.0100, 624.52, '销售出库', '2026-08-03 14:17:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (76, 2, 31, 'SALE_OUT', 'SO20260803-0001', -59.00, 470.00, 11.9300, 703.87, '销售出库', '2026-08-03 14:17:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (77, 2, 17, 'SALE_OUT', 'SO20260803-0001', -65.00, 401.00, 16.6541, 1082.52, '销售出库', '2026-08-03 14:17:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (78, 2, 5, 'PURCHASE_IN', 'PO20260804-0001', 94.00, 94.00, 52.8000, 4963.20, '采购入库', '2026-08-04 15:23:11');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (79, 2, 4, 'PURCHASE_IN', 'PO20260804-0001', 211.00, 1193.00, 28.9000, 6097.90, '采购入库', '2026-08-04 15:23:11');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (80, 2, 13, 'PURCHASE_IN', 'PO20260804-0001', 203.00, 371.00, 16.7200, 3394.16, '采购入库', '2026-08-04 15:23:11');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (81, 1, 21, 'SALE_OUT', 'SO20260804-0001', -24.00, 355.00, 31.0668, 745.60, '销售出库', '2026-08-04 19:26:56');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (82, 1, 38, 'SALE_OUT', 'SO20260804-0001', -11.00, 80.00, 77.5900, 853.49, '销售出库', '2026-08-04 19:26:56');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (83, 1, 13, 'SALE_OUT', 'SO20260804-0001', -28.00, 213.00, 15.8997, 445.19, '销售出库', '2026-08-04 19:26:56');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (84, 2, 21, 'SALE_OUT', 'SO20260804-0002', -24.00, 132.00, 31.0100, 744.24, '销售出库', '2026-08-04 21:45:29');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (85, 2, 33, 'SALE_OUT', 'SO20260804-0002', -11.00, 147.00, 43.9500, 483.45, '销售出库', '2026-08-04 21:45:29');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (86, 2, 12, 'SALE_OUT', 'SO20260804-0002', -27.00, 93.00, 15.3200, 413.64, '销售出库', '2026-08-04 21:45:29');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (87, 2, 28, 'SALE_OUT', 'SO20260804-0002', -40.00, 203.00, 15.6768, 627.07, '销售出库', '2026-08-04 21:45:29');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (88, 2, 16, 'PURCHASE_IN', 'PO20260805-0001', 113.00, 181.00, 116.7500, 13192.75, '采购入库', '2026-08-05 14:16:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (89, 2, 32, 'PURCHASE_IN', 'PO20260805-0001', 186.00, 186.00, 32.5300, 6050.58, '采购入库', '2026-08-05 14:16:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (90, 2, 39, 'PURCHASE_IN', 'PO20260805-0001', 41.00, 82.00, 89.3700, 3664.17, '采购入库', '2026-08-05 14:16:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (91, 2, 15, 'SALE_OUT', 'SO20260805-0001', -36.00, 76.00, 50.2400, 1808.64, '销售出库', '2026-08-05 18:33:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (92, 2, 14, 'SALE_OUT', 'SO20260805-0001', -23.00, 119.00, 12.0100, 276.23, '销售出库', '2026-08-05 18:33:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (93, 2, 33, 'SALE_OUT', 'SO20260805-0001', -34.00, 113.00, 43.9500, 1494.30, '销售出库', '2026-08-05 18:33:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (94, 2, 12, 'SALE_OUT', 'SO20260805-0001', -32.00, 61.00, 15.3200, 490.24, '销售出库', '2026-08-05 18:33:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (95, 1, 11, 'SALE_OUT', 'SO20260806-0001', -15.00, 285.00, 20.9480, 314.22, '销售出库', '2026-08-06 15:44:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (96, 1, 38, 'SALE_OUT', 'SO20260806-0001', -10.00, 70.00, 77.5900, 775.90, '销售出库', '2026-08-06 15:44:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (97, 1, 14, 'SALE_OUT', 'SO20260806-0001', -22.00, 130.00, 12.0100, 264.22, '销售出库', '2026-08-06 15:44:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (98, 1, 35, 'SALE_OUT', 'SO20260806-0001', -20.00, 114.00, 88.6513, 1773.03, '销售出库', '2026-08-06 15:44:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (99, 2, 3, 'PURCHASE_IN', 'PO20260807-0001', 206.00, 206.00, 41.7600, 8602.56, '采购入库', '2026-08-07 13:48:15');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (100, 2, 20, 'PURCHASE_IN', 'PO20260807-0001', 125.00, 125.00, 27.0500, 3381.25, '采购入库', '2026-08-07 13:48:15');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (101, 2, 22, 'PURCHASE_IN', 'PO20260807-0001', 81.00, 81.00, 15.8700, 1285.47, '采购入库', '2026-08-07 13:48:15');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (102, 2, 19, 'PURCHASE_IN', 'PO20260807-0001', 150.00, 150.00, 8.0300, 1204.50, '采购入库', '2026-08-07 13:48:15');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (103, 2, 42, 'PURCHASE_IN', 'PO20260807-0001', 22.00, 56.00, 114.6900, 2523.18, '采购入库', '2026-08-07 13:48:15');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (104, 2, 19, 'SALE_OUT', 'SO20260807-0001', -46.00, 104.00, 8.0300, 369.38, '销售出库', '2026-08-07 11:42:02');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (105, 2, 20, 'SALE_OUT', 'SO20260807-0001', -26.00, 99.00, 27.0500, 703.30, '销售出库', '2026-08-07 11:42:02');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (106, 2, 2, 'SALE_OUT', 'SO20260807-0001', -26.00, 87.00, 41.1400, 1069.64, '销售出库', '2026-08-07 11:42:02');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (107, 2, 32, 'SALE_OUT', 'SO20260807-0001', -22.00, 164.00, 32.5300, 715.66, '销售出库', '2026-08-07 11:42:02');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (108, 2, 42, 'SALE_OUT', 'SO20260808-0001', -8.00, 48.00, 116.3900, 931.12, '销售出库', '2026-08-08 21:55:08');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (109, 2, 36, 'SALE_OUT', 'SO20260808-0001', -4.00, 17.00, 191.4400, 765.76, '销售出库', '2026-08-08 21:55:08');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (110, 1, 1, 'SALE_OUT', 'SO20260808-0002', -36.00, 450.00, 43.7964, 1576.67, '销售出库', '2026-08-08 14:39:41');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (111, 1, 35, 'SALE_OUT', 'SO20260808-0002', -20.00, 94.00, 88.6513, 1773.03, '销售出库', '2026-08-08 14:39:41');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (112, 1, 41, 'SALE_OUT', 'SO20260808-0002', -10.00, 20.00, 142.7200, 1427.20, '销售出库', '2026-08-08 14:39:41');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (113, 1, 19, 'SALE_OUT', 'SO20260808-0002', -27.00, 499.00, 7.5724, 204.45, '销售出库', '2026-08-08 14:39:41');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (114, 1, 31, 'SALE_OUT', 'SO20260808-0002', -75.00, 252.00, 11.6700, 875.25, '销售出库', '2026-08-08 14:39:41');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (115, 2, 39, 'PURCHASE_IN', 'PO20260809-0001', 35.00, 117.00, 89.3200, 3126.20, '采购入库', '2026-08-09 12:22:57');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (116, 2, 6, 'PURCHASE_IN', 'PO20260809-0001', 76.00, 76.00, 52.6000, 3997.60, '采购入库', '2026-08-09 12:22:57');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (117, 2, 33, 'PURCHASE_IN', 'PO20260809-0001', 91.00, 204.00, 41.1500, 3744.65, '采购入库', '2026-08-09 12:22:57');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (118, 2, 19, 'SALE_OUT', 'SO20260809-0001', -36.00, 68.00, 8.0300, 289.08, '销售出库', '2026-08-09 16:46:04');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (119, 2, 39, 'SALE_OUT', 'SO20260809-0001', -10.00, 107.00, 91.0476, 910.48, '销售出库', '2026-08-09 16:46:04');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (120, 2, 1, 'SALE_OUT', 'SO20260809-0001', -28.00, 99.00, 42.4600, 1188.88, '销售出库', '2026-08-09 16:46:04');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (121, 2, 4, 'SALE_OUT', 'SO20260809-0001', -25.00, 1168.00, 28.3671, 709.18, '销售出库', '2026-08-09 16:46:04');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (122, 2, 26, 'SALE_OUT', 'SO20260809-0002', -37.00, 219.00, 15.0415, 556.54, '销售出库', '2026-08-09 16:13:11');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (123, 2, 13, 'SALE_OUT', 'SO20260809-0002', -47.00, 324.00, 16.2536, 763.92, '销售出库', '2026-08-09 16:13:11');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (124, 2, 1, 'SALE_OUT', 'SO20260809-0002', -32.00, 67.00, 42.4600, 1358.72, '销售出库', '2026-08-09 16:13:11');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (125, 1, 17, 'SALE_OUT', 'SO20260810-0001', -24.00, 359.00, 16.7247, 401.39, '销售出库', '2026-08-10 19:40:51');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (126, 1, 2, 'SALE_OUT', 'SO20260810-0001', -45.00, 336.00, 40.4983, 1822.42, '销售出库', '2026-08-10 19:40:51');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (127, 1, 6, 'PURCHASE_IN', 'PO20260811-0001', 50.00, 312.00, 54.4100, 2720.50, '采购入库', '2026-08-11 10:59:21');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (128, 1, 38, 'PURCHASE_IN', 'PO20260811-0001', 72.00, 142.00, 78.0900, 5622.48, '采购入库', '2026-08-11 10:59:21');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (129, 1, 17, 'PURCHASE_IN', 'PO20260811-0001', 265.00, 624.00, 17.3000, 4584.50, '采购入库', '2026-08-11 10:59:21');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (130, 1, 34, 'PURCHASE_IN', 'PO20260811-0001', 53.00, 53.00, 160.9000, 8527.70, '采购入库', '2026-08-11 10:59:21');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (131, 1, 42, 'PURCHASE_IN', 'PO20260811-0001', 50.00, 96.00, 120.1500, 6007.50, '采购入库', '2026-08-11 10:59:21');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (132, 1, 2, 'PURCHASE_IN', 'PO20260811-0001', 131.00, 467.00, 39.8800, 5224.28, '采购入库', '2026-08-11 10:59:21');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (133, 1, 11, 'SALE_OUT', 'SO20260811-0001', -24.00, 261.00, 20.9480, 502.75, '销售出库', '2026-08-11 17:38:52');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (134, 1, 41, 'SALE_OUT', 'SO20260811-0001', -7.00, 13.00, 142.7200, 999.04, '销售出库', '2026-08-11 17:38:52');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (135, 1, 10, 'SALE_OUT', 'SO20260811-0001', -35.00, 474.00, 9.3264, 326.42, '销售出库', '2026-08-11 17:38:52');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (136, 1, 13, 'SALE_OUT', 'SO20260811-0001', -15.00, 198.00, 15.8997, 238.50, '销售出库', '2026-08-11 17:38:52');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (137, 1, 35, 'SALE_OUT', 'SO20260811-0001', -7.00, 87.00, 88.6513, 620.56, '销售出库', '2026-08-11 17:38:52');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (138, 2, 20, 'SALE_OUT', 'SO20260811-0002', -18.00, 81.00, 27.0500, 486.90, '销售出库', '2026-08-11 17:56:12');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (139, 2, 21, 'SALE_OUT', 'SO20260811-0002', -39.00, 93.00, 31.0100, 1209.39, '销售出库', '2026-08-11 17:56:12');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (140, 1, 24, 'SALE_OUT', 'SO20260812-0001', -35.00, 193.00, 43.8400, 1534.40, '销售出库', '2026-08-12 19:33:29');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (141, 1, 10, 'SALE_OUT', 'SO20260812-0001', -57.00, 417.00, 9.3264, 531.60, '销售出库', '2026-08-12 19:33:29');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (142, 1, 38, 'SALE_OUT', 'SO20260812-0001', -15.00, 127.00, 77.8435, 1167.65, '销售出库', '2026-08-12 19:33:29');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (143, 1, 21, 'SALE_OUT', 'SO20260812-0001', -31.00, 324.00, 31.0668, 963.07, '销售出库', '2026-08-12 19:33:29');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (144, 1, 27, 'SALE_OUT', 'SO20260812-0002', -22.00, 109.00, 32.5000, 715.00, '销售出库', '2026-08-12 17:37:10');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (145, 1, 14, 'SALE_OUT', 'SO20260812-0002', -31.00, 99.00, 12.0100, 372.31, '销售出库', '2026-08-12 17:37:10');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (146, 1, 38, 'SALE_OUT', 'SO20260812-0002', -7.00, 120.00, 77.8435, 544.90, '销售出库', '2026-08-12 17:37:10');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (147, 1, 41, 'PURCHASE_IN', 'PO20260813-0001', 47.00, 60.00, 138.4900, 6509.03, '采购入库', '2026-08-13 12:23:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (148, 1, 6, 'PURCHASE_IN', 'PO20260813-0001', 110.00, 422.00, 56.3900, 6202.90, '采购入库', '2026-08-13 12:23:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (149, 1, 10, 'PURCHASE_IN', 'PO20260813-0001', 390.00, 807.00, 9.1700, 3576.30, '采购入库', '2026-08-13 12:23:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (150, 2, 16, 'SALE_OUT', 'SO20260813-0001', -25.00, 156.00, 115.4914, 2887.29, '销售出库', '2026-08-13 19:44:39');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (151, 2, 21, 'SALE_OUT', 'SO20260813-0001', -12.00, 81.00, 31.0100, 372.12, '销售出库', '2026-08-13 19:44:39');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (152, 2, 3, 'SALE_OUT', 'SO20260813-0001', -31.00, 175.00, 41.7600, 1294.56, '销售出库', '2026-08-13 19:44:39');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (153, 1, 21, 'SALE_OUT', 'SO20260813-0002', -12.00, 312.00, 31.0668, 372.80, '销售出库', '2026-08-13 17:04:06');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (154, 1, 2, 'SALE_OUT', 'SO20260813-0002', -31.00, 436.00, 40.3249, 1250.07, '销售出库', '2026-08-13 17:04:06');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (155, 1, 4, 'SALE_OUT', 'SO20260813-0002', -29.00, 206.00, 28.9500, 839.55, '销售出库', '2026-08-13 17:04:06');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (156, 1, 31, 'SALE_OUT', 'SO20260813-0002', -70.00, 182.00, 11.6700, 816.90, '销售出库', '2026-08-13 17:04:06');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (157, 2, 21, 'PURCHASE_IN', 'PO20260814-0001', 119.00, 200.00, 30.7600, 3660.44, '采购入库', '2026-08-14 12:17:38');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (158, 2, 19, 'PURCHASE_IN', 'PO20260814-0001', 364.00, 432.00, 8.0600, 2933.84, '采购入库', '2026-08-14 12:17:38');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (159, 2, 15, 'PURCHASE_IN', 'PO20260814-0001', 108.00, 184.00, 51.3300, 5543.64, '采购入库', '2026-08-14 12:17:38');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (160, 1, 24, 'SALE_OUT', 'SO20260814-0001', -15.00, 178.00, 43.8400, 657.60, '销售出库', '2026-08-14 17:13:39');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (161, 1, 41, 'SALE_OUT', 'SO20260814-0001', -11.00, 49.00, 139.4065, 1533.47, '销售出库', '2026-08-14 17:13:39');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (162, 1, 12, 'SALE_OUT', 'SO20260814-0001', -47.00, 427.00, 15.5206, 729.47, '销售出库', '2026-08-14 17:13:39');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (163, 2, 23, 'SALE_OUT', 'SO20260814-0002', -20.00, 281.00, 13.8091, 276.18, '销售出库', '2026-08-14 19:00:20');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (164, 2, 21, 'SALE_OUT', 'SO20260814-0002', -41.00, 159.00, 30.8613, 1265.31, '销售出库', '2026-08-14 19:00:20');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (165, 2, 19, 'SALE_OUT', 'SO20260814-0002', -31.00, 401.00, 8.0553, 249.71, '销售出库', '2026-08-14 19:00:20');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (166, 2, 1, 'SALE_OUT', 'SO20260814-0002', -23.00, 44.00, 42.4600, 976.58, '销售出库', '2026-08-14 19:00:20');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (167, 2, 15, 'PURCHASE_IN', 'PO20260815-0001', 192.00, 376.00, 50.5700, 9709.44, '采购入库', '2026-08-15 13:40:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (168, 2, 10, 'PURCHASE_IN', 'PO20260815-0001', 389.00, 389.00, 9.6500, 3753.85, '采购入库', '2026-08-15 13:40:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (169, 2, 9, 'PURCHASE_IN', 'PO20260815-0001', 40.00, 40.00, 65.0400, 2601.60, '采购入库', '2026-08-15 13:40:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (170, 2, 13, 'SALE_OUT', 'SO20260815-0001', -35.00, 289.00, 16.2536, 568.88, '销售出库', '2026-08-15 20:06:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (171, 2, 15, 'SALE_OUT', 'SO20260815-0001', -14.00, 362.00, 50.7216, 710.10, '销售出库', '2026-08-15 20:06:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (172, 2, 12, 'SALE_OUT', 'SO20260815-0001', -21.00, 40.00, 15.3200, 321.72, '销售出库', '2026-08-15 20:06:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (173, 2, 10, 'SALE_OUT', 'SO20260815-0001', -48.00, 341.00, 9.6500, 463.20, '销售出库', '2026-08-15 20:06:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (174, 1, 31, 'PURCHASE_IN', 'PO20260816-0001', 313.00, 495.00, 12.4800, 3906.24, '采购入库', '2026-08-16 10:54:28');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (175, 1, 21, 'PURCHASE_IN', 'PO20260816-0001', 139.00, 451.00, 31.6500, 4399.35, '采购入库', '2026-08-16 10:54:28');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (176, 1, 12, 'PURCHASE_IN', 'PO20260816-0001', 111.00, 538.00, 16.0100, 1777.11, '采购入库', '2026-08-16 10:54:28');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (177, 1, 3, 'PURCHASE_IN', 'PO20260816-0001', 178.00, 178.00, 43.7600, 7789.28, '采购入库', '2026-08-16 10:54:28');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (178, 1, 9, 'PURCHASE_IN', 'PO20260816-0001', 46.00, 118.00, 64.9800, 2989.08, '采购入库', '2026-08-16 10:54:28');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (179, 1, 38, 'SALE_OUT', 'SO20260816-0001', -18.00, 102.00, 77.8435, 1401.18, '销售出库', '2026-08-16 17:41:50');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (180, 1, 11, 'SALE_OUT', 'SO20260816-0001', -44.00, 217.00, 20.9480, 921.71, '销售出库', '2026-08-16 17:41:50');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (181, 2, 36, 'SALE_OUT', 'SO20260816-0002', -5.00, 12.00, 191.4400, 957.20, '销售出库', '2026-08-16 13:15:40');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (182, 2, 33, 'SALE_OUT', 'SO20260816-0002', -14.00, 190.00, 42.7010, 597.81, '销售出库', '2026-08-16 13:15:40');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (183, 2, 39, 'SALE_OUT', 'SO20260816-0002', -15.00, 92.00, 91.0476, 1365.71, '销售出库', '2026-08-16 13:15:40');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (184, 2, 21, 'SALE_OUT', 'SO20260816-0002', -20.00, 139.00, 30.8613, 617.23, '销售出库', '2026-08-16 13:15:40');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (185, 2, 42, 'SALE_OUT', 'SO20260816-0002', -4.00, 44.00, 116.3900, 465.56, '销售出库', '2026-08-16 13:15:40');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (186, 1, 6, 'SALE_OUT', 'SO20260817-0001', -21.00, 401.00, 56.6316, 1189.26, '销售出库', '2026-08-17 21:54:44');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (187, 1, 24, 'SALE_OUT', 'SO20260817-0001', -25.00, 153.00, 43.8400, 1096.00, '销售出库', '2026-08-17 21:54:44');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (188, 1, 21, 'SALE_OUT', 'SO20260817-0001', -34.00, 417.00, 31.2465, 1062.38, '销售出库', '2026-08-17 21:54:44');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (189, 1, 26, 'SALE_OUT', 'SO20260817-0001', -35.00, 68.00, 15.3600, 537.60, '销售出库', '2026-08-17 21:54:44');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (190, 1, 30, 'SALE_OUT', 'SO20260817-0001', -9.00, 71.00, 53.5900, 482.31, '销售出库', '2026-08-17 21:54:44');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (191, 2, 32, 'SALE_OUT', 'SO20260817-0002', -17.00, 147.00, 32.5300, 553.01, '销售出库', '2026-08-17 14:05:05');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (192, 2, 3, 'SALE_OUT', 'SO20260817-0002', -23.00, 152.00, 41.7600, 960.48, '销售出库', '2026-08-17 14:05:05');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (193, 2, 21, 'SALE_OUT', 'SO20260817-0002', -40.00, 99.00, 30.8613, 1234.45, '销售出库', '2026-08-17 14:05:05');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (194, 1, 22, 'SALE_OUT', 'SO20260818-0001', -18.00, 144.00, 16.5326, 297.59, '销售出库', '2026-08-18 13:42:59');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (195, 1, 35, 'SALE_OUT', 'SO20260818-0001', -22.00, 65.00, 88.6513, 1950.33, '销售出库', '2026-08-18 13:42:59');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (196, 1, 8, 'SALE_OUT', 'SO20260818-0001', -25.00, 78.00, 32.3800, 809.50, '销售出库', '2026-08-18 13:42:59');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (197, 1, 9, 'SALE_OUT', 'SO20260818-0001', -11.00, 107.00, 61.8803, 680.68, '销售出库', '2026-08-18 13:42:59');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (198, 1, 4, 'SALE_OUT', 'SO20260818-0001', -49.00, 157.00, 28.9500, 1418.55, '销售出库', '2026-08-18 13:42:59');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (199, 2, 23, 'SALE_OUT', 'SO20260819-0001', -22.00, 259.00, 13.8091, 303.80, '销售出库', '2026-08-19 21:30:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (200, 2, 26, 'SALE_OUT', 'SO20260819-0001', -28.00, 191.00, 15.0415, 421.16, '销售出库', '2026-08-19 21:30:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (201, 2, 13, 'SALE_OUT', 'SO20260819-0001', -46.00, 243.00, 16.2536, 747.67, '销售出库', '2026-08-19 21:30:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (202, 2, 39, 'SALE_OUT', 'SO20260819-0001', -13.00, 79.00, 91.0476, 1183.62, '销售出库', '2026-08-19 21:30:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (203, 2, 15, 'SALE_OUT', 'SO20260820-0001', -46.00, 316.00, 50.7216, 2333.19, '销售出库', '2026-08-20 17:55:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (204, 2, 20, 'SALE_OUT', 'SO20260820-0001', -28.00, 53.00, 27.0500, 757.40, '销售出库', '2026-08-20 17:55:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (205, 2, 42, 'SALE_OUT', 'SO20260820-0001', -6.00, 38.00, 116.3900, 698.34, '销售出库', '2026-08-20 17:55:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (206, 1, 11, 'PURCHASE_IN', 'PO20260821-0001', 95.00, 312.00, 20.5200, 1949.40, '采购入库', '2026-08-21 12:23:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (207, 1, 20, 'PURCHASE_IN', 'PO20260821-0001', 157.00, 261.00, 26.2800, 4125.96, '采购入库', '2026-08-21 12:23:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (208, 1, 27, 'PURCHASE_IN', 'PO20260821-0001', 95.00, 204.00, 34.0500, 3234.75, '采购入库', '2026-08-21 12:23:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (209, 1, 42, 'PURCHASE_IN', 'PO20260821-0001', 35.00, 131.00, 120.8400, 4229.40, '采购入库', '2026-08-21 12:23:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (210, 1, 5, 'PURCHASE_IN', 'PO20260821-0001', 82.00, 82.00, 50.8800, 4172.16, '采购入库', '2026-08-21 12:23:43');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (211, 1, 10, 'SALE_OUT', 'SO20260821-0001', -85.00, 722.00, 9.2508, 786.32, '销售出库', '2026-08-21 13:49:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (212, 1, 36, 'SALE_OUT', 'SO20260821-0001', -6.00, 98.00, 194.7775, 1168.67, '销售出库', '2026-08-21 13:49:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (213, 1, 12, 'SALE_OUT', 'SO20260821-0001', -45.00, 493.00, 15.6216, 702.97, '销售出库', '2026-08-21 13:49:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (214, 1, 22, 'SALE_OUT', 'SO20260821-0001', -10.00, 134.00, 16.5326, 165.33, '销售出库', '2026-08-21 13:49:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (215, 1, 20, 'SALE_OUT', 'SO20260822-0001', -13.00, 248.00, 26.0848, 339.10, '销售出库', '2026-08-22 16:03:31');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (216, 1, 34, 'SALE_OUT', 'SO20260822-0001', -12.00, 41.00, 160.9000, 1930.80, '销售出库', '2026-08-22 16:03:31');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (217, 1, 9, 'SALE_OUT', 'SO20260822-0001', -18.00, 89.00, 61.8803, 1113.85, '销售出库', '2026-08-22 16:03:31');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (218, 2, 39, 'SALE_OUT', 'SO20260823-0001', -10.00, 69.00, 91.0476, 910.48, '销售出库', '2026-08-23 13:32:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (219, 2, 12, 'SALE_OUT', 'SO20260823-0001', -14.00, 26.00, 15.3200, 214.48, '销售出库', '2026-08-23 13:32:07');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (220, 1, 34, 'SALE_OUT', 'SO20260823-0002', -12.00, 29.00, 160.9000, 1930.80, '销售出库', '2026-08-23 15:59:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (221, 1, 5, 'SALE_OUT', 'SO20260823-0002', -28.00, 54.00, 50.8800, 1424.64, '销售出库', '2026-08-23 15:59:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (222, 1, 28, 'SALE_OUT', 'SO20260823-0002', -35.00, 114.00, 16.0000, 560.00, '销售出库', '2026-08-23 15:59:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (223, 1, 27, 'PURCHASE_IN', 'PO20260824-0001', 108.00, 312.00, 35.0400, 3784.32, '采购入库', '2026-08-24 15:29:24');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (224, 1, 5, 'PURCHASE_IN', 'PO20260824-0001', 161.00, 215.00, 53.0900, 8547.49, '采购入库', '2026-08-24 15:29:24');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (225, 1, 12, 'PURCHASE_IN', 'PO20260824-0001', 102.00, 595.00, 14.8300, 1512.66, '采购入库', '2026-08-24 15:29:24');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (226, 1, 37, 'PURCHASE_IN', 'PO20260824-0001', 41.00, 41.00, 225.1900, 9232.79, '采购入库', '2026-08-24 15:29:24');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (227, 1, 34, 'PURCHASE_IN', 'PO20260824-0001', 58.00, 87.00, 156.7400, 9090.92, '采购入库', '2026-08-24 15:29:24');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (228, 1, 40, 'PURCHASE_IN', 'PO20260824-0001', 57.00, 57.00, 129.1900, 7363.83, '采购入库', '2026-08-24 15:29:24');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (229, 1, 17, 'SALE_OUT', 'SO20260824-0001', -35.00, 589.00, 16.9690, 593.92, '销售出库', '2026-08-24 16:33:33');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (230, 1, 31, 'SALE_OUT', 'SO20260824-0001', -37.00, 458.00, 12.1822, 450.74, '销售出库', '2026-08-24 16:33:33');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (231, 1, 12, 'SALE_OUT', 'SO20260824-0001', -59.00, 536.00, 15.4859, 913.67, '销售出库', '2026-08-24 16:33:33');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (232, 1, 5, 'SALE_OUT', 'SO20260824-0001', -27.00, 188.00, 52.5349, 1418.44, '销售出库', '2026-08-24 16:33:33');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (233, 1, 30, 'PURCHASE_IN', 'PO20260825-0001', 58.00, 129.00, 56.2400, 3261.92, '采购入库', '2026-08-25 13:58:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (234, 1, 37, 'PURCHASE_IN', 'PO20260825-0001', 38.00, 79.00, 221.1400, 8403.32, '采购入库', '2026-08-25 13:58:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (235, 1, 41, 'PURCHASE_IN', 'PO20260825-0001', 32.00, 81.00, 149.3500, 4779.20, '采购入库', '2026-08-25 13:58:47');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (236, 2, 2, 'SALE_OUT', 'SO20260825-0001', -30.00, 57.00, 41.1400, 1234.20, '销售出库', '2026-08-25 14:32:28');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (237, 2, 23, 'SALE_OUT', 'SO20260825-0001', -16.00, 243.00, 13.8091, 220.95, '销售出库', '2026-08-25 14:32:28');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (238, 2, 17, 'SALE_OUT', 'SO20260825-0001', -36.00, 365.00, 16.6541, 599.55, '销售出库', '2026-08-25 14:32:28');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (239, 1, 9, 'PURCHASE_IN', 'PO20260826-0001', 46.00, 135.00, 60.9800, 2805.08, '采购入库', '2026-08-26 12:49:14');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (240, 1, 21, 'PURCHASE_IN', 'PO20260826-0001', 154.00, 571.00, 30.6400, 4718.56, '采购入库', '2026-08-26 12:49:14');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (241, 1, 16, 'PURCHASE_IN', 'PO20260826-0001', 68.00, 187.00, 120.1700, 8171.56, '采购入库', '2026-08-26 12:49:14');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (242, 1, 18, 'PURCHASE_IN', 'PO20260826-0001', 171.00, 171.00, 13.7800, 2356.38, '采购入库', '2026-08-26 12:49:14');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (243, 1, 3, 'PURCHASE_IN', 'PO20260826-0001', 175.00, 353.00, 43.9700, 7694.75, '采购入库', '2026-08-26 12:49:14');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (244, 1, 35, 'PURCHASE_IN', 'PO20260826-0001', 108.00, 173.00, 89.5700, 9673.56, '采购入库', '2026-08-26 12:49:14');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (245, 2, 22, 'SALE_OUT', 'SO20260826-0001', -28.00, 53.00, 15.8700, 444.36, '销售出库', '2026-08-26 19:41:12');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (246, 2, 42, 'SALE_OUT', 'SO20260826-0001', -9.00, 29.00, 116.3900, 1047.51, '销售出库', '2026-08-26 19:41:12');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (247, 1, 30, 'SALE_OUT', 'SO20260826-0002', -28.00, 101.00, 54.7815, 1533.88, '销售出库', '2026-08-26 15:18:53');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (248, 1, 40, 'SALE_OUT', 'SO20260826-0002', -5.00, 52.00, 129.1900, 645.95, '销售出库', '2026-08-26 15:18:53');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (249, 1, 35, 'SALE_OUT', 'SO20260826-0002', -19.00, 154.00, 89.2248, 1695.27, '销售出库', '2026-08-26 15:18:53');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (250, 1, 20, 'SALE_OUT', 'SO20260826-0002', -23.00, 225.00, 26.0848, 599.95, '销售出库', '2026-08-26 15:18:53');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (251, 1, 36, 'SALE_OUT', 'SO20260826-0002', -4.00, 94.00, 194.7775, 779.11, '销售出库', '2026-08-26 15:18:53');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (252, 2, 2, 'PURCHASE_IN', 'PO20260827-0001', 165.00, 222.00, 40.4900, 6680.85, '采购入库', '2026-08-27 12:53:37');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (253, 2, 3, 'PURCHASE_IN', 'PO20260827-0001', 202.00, 354.00, 43.8200, 8851.64, '采购入库', '2026-08-27 12:53:37');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (254, 2, 26, 'PURCHASE_IN', 'PO20260827-0001', 94.00, 285.00, 15.5600, 1462.64, '采购入库', '2026-08-27 12:53:37');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (255, 1, 27, 'SALE_OUT', 'SO20260827-0001', -13.00, 299.00, 33.8512, 440.07, '销售出库', '2026-08-27 17:25:52');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (256, 1, 5, 'SALE_OUT', 'SO20260827-0001', -20.00, 168.00, 52.5349, 1050.70, '销售出库', '2026-08-27 17:25:52');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (257, 1, 38, 'SALE_OUT', 'SO20260827-0001', -19.00, 83.00, 77.8435, 1479.03, '销售出库', '2026-08-27 17:25:52');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (258, 1, 18, 'SALE_OUT', 'SO20260827-0001', -32.00, 139.00, 13.7800, 440.96, '销售出库', '2026-08-27 17:25:52');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (259, 1, 6, 'SALE_OUT', 'SO20260827-0002', -21.00, 380.00, 56.6316, 1189.26, '销售出库', '2026-08-27 16:25:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (260, 1, 37, 'SALE_OUT', 'SO20260827-0002', -11.00, 68.00, 223.2419, 2455.66, '销售出库', '2026-08-27 16:25:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (261, 1, 10, 'SALE_OUT', 'SO20260827-0002', -82.00, 640.00, 9.2508, 758.57, '销售出库', '2026-08-27 16:25:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (262, 1, 14, 'SALE_OUT', 'SO20260827-0002', -34.00, 65.00, 12.0100, 408.34, '销售出库', '2026-08-27 16:25:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (263, 1, 28, 'SALE_OUT', 'SO20260827-0002', -14.00, 100.00, 16.0000, 224.00, '销售出库', '2026-08-27 16:25:16');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (264, 2, 3, 'PURCHASE_IN', 'PO20260828-0001', 84.00, 438.00, 42.2600, 3549.84, '采购入库', '2026-08-28 17:00:18');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (265, 2, 5, 'PURCHASE_IN', 'PO20260828-0001', 160.00, 254.00, 51.7800, 8284.80, '采购入库', '2026-08-28 17:00:18');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (266, 2, 40, 'PURCHASE_IN', 'PO20260828-0001', 56.00, 56.00, 129.0000, 7224.00, '采购入库', '2026-08-28 17:00:18');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (267, 2, 21, 'PURCHASE_IN', 'PO20260828-0001', 114.00, 213.00, 31.8200, 3627.48, '采购入库', '2026-08-28 17:00:18');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (268, 2, 31, 'PURCHASE_IN', 'PO20260828-0001', 500.00, 970.00, 12.5600, 6280.00, '采购入库', '2026-08-28 17:00:18');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (269, 2, 35, 'PURCHASE_IN', 'PO20260828-0001', 48.00, 48.00, 92.4000, 4435.20, '采购入库', '2026-08-28 17:00:18');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (270, 1, 6, 'SALE_OUT', 'SO20260828-0001', -10.00, 370.00, 56.6316, 566.32, '销售出库', '2026-08-28 13:55:48');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (271, 1, 28, 'SALE_OUT', 'SO20260828-0001', -26.00, 74.00, 16.0000, 416.00, '销售出库', '2026-08-28 13:55:48');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (272, 1, 26, 'SALE_OUT', 'SO20260828-0001', -23.00, 45.00, 15.3600, 353.28, '销售出库', '2026-08-28 13:55:48');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (273, 1, 24, 'SALE_OUT', 'SO20260828-0001', -53.00, 100.00, 43.8400, 2323.52, '销售出库', '2026-08-28 13:55:48');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (274, 1, 17, 'SALE_OUT', 'SO20260828-0001', -38.00, 551.00, 16.9690, 644.82, '销售出库', '2026-08-28 13:55:48');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (275, 2, 40, 'SALE_OUT', 'SO20260828-0002', -13.00, 43.00, 129.0000, 1677.00, '销售出库', '2026-08-28 19:21:46');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (276, 2, 4, 'SALE_OUT', 'SO20260828-0002', -54.00, 1114.00, 28.3671, 1531.82, '销售出库', '2026-08-28 19:21:46');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (277, 2, 33, 'SALE_OUT', 'SO20260828-0002', -20.00, 170.00, 42.7010, 854.02, '销售出库', '2026-08-28 19:21:46');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (278, 2, 22, 'SALE_OUT', 'SO20260828-0002', -18.00, 35.00, 15.8700, 285.66, '销售出库', '2026-08-28 19:21:46');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (279, 1, 14, 'SALE_OUT', 'SO20260829-0001', -22.00, 43.00, 12.0100, 264.22, '销售出库', '2026-08-29 13:11:37');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (280, 1, 2, 'SALE_OUT', 'SO20260829-0001', -15.00, 421.00, 40.3249, 604.87, '销售出库', '2026-08-29 13:11:37');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (281, 1, 11, 'SALE_OUT', 'SO20260829-0001', -30.00, 282.00, 20.8177, 624.53, '销售出库', '2026-08-29 13:11:37');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (282, 1, 41, 'SALE_OUT', 'SO20260829-0001', -10.00, 71.00, 143.3348, 1433.35, '销售出库', '2026-08-29 13:11:37');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (283, 2, 14, 'PURCHASE_IN', 'PO20260830-0001', 193.00, 312.00, 12.6400, 2439.52, '采购入库', '2026-08-30 15:02:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (284, 2, 41, 'PURCHASE_IN', 'PO20260830-0001', 41.00, 41.00, 141.1000, 5785.10, '采购入库', '2026-08-30 15:02:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (285, 2, 10, 'PURCHASE_IN', 'PO20260830-0001', 196.00, 537.00, 9.1700, 1797.32, '采购入库', '2026-08-30 15:02:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (286, 2, 31, 'PURCHASE_IN', 'PO20260830-0001', 349.00, 1319.00, 11.7100, 4086.79, '采购入库', '2026-08-30 15:02:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (287, 2, 29, 'PURCHASE_IN', 'PO20260830-0001', 112.00, 112.00, 22.8100, 2554.72, '采购入库', '2026-08-30 15:02:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (288, 2, 23, 'PURCHASE_IN', 'PO20260830-0001', 123.00, 366.00, 13.8000, 1697.40, '采购入库', '2026-08-30 15:02:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (289, 1, 28, 'SALE_OUT', 'SO20260830-0001', -25.00, 49.00, 16.0000, 400.00, '销售出库', '2026-08-30 16:22:33');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (290, 1, 1, 'SALE_OUT', 'SO20260830-0001', -44.00, 406.00, 43.7964, 1927.04, '销售出库', '2026-08-30 16:22:33');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (291, 2, 14, 'PURCHASE_IN', 'PO20260831-0001', 200.00, 512.00, 12.6600, 2532.00, '采购入库', '2026-08-31 16:46:26');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (292, 2, 28, 'PURCHASE_IN', 'PO20260831-0001', 75.00, 278.00, 16.7400, 1255.50, '采购入库', '2026-08-31 16:46:26');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (293, 2, 37, 'PURCHASE_IN', 'PO20260831-0001', 35.00, 35.00, 217.4700, 7611.45, '采购入库', '2026-08-31 16:46:26');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (294, 2, 29, 'PURCHASE_IN', 'PO20260831-0001', 121.00, 233.00, 22.4000, 2710.40, '采购入库', '2026-08-31 16:46:26');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (295, 2, 15, 'PURCHASE_IN', 'PO20260831-0001', 108.00, 424.00, 49.5000, 5346.00, '采购入库', '2026-08-31 16:46:26');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (296, 2, 41, 'PURCHASE_IN', 'PO20260831-0001', 43.00, 84.00, 145.5300, 6257.79, '采购入库', '2026-08-31 16:46:26');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (297, 2, 1, 'SALE_OUT', 'SO20260831-0001', -15.00, 29.00, 42.4600, 636.90, '销售出库', '2026-08-31 12:28:32');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (298, 2, 4, 'SALE_OUT', 'SO20260831-0001', -62.00, 1052.00, 28.3671, 1758.76, '销售出库', '2026-08-31 12:28:32');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (299, 2, 37, 'SALE_OUT', 'SO20260831-0001', -10.00, 25.00, 217.4700, 2174.70, '销售出库', '2026-08-31 12:28:32');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (300, 1, 42, 'SALE_OUT', 'SO20260831-0002', -5.00, 126.00, 119.7199, 598.60, '销售出库', '2026-08-31 13:35:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (301, 1, 17, 'SALE_OUT', 'SO20260831-0002', -54.00, 497.00, 16.9690, 916.33, '销售出库', '2026-08-31 13:35:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (302, 1, 28, 'SALE_OUT', 'SO20260831-0002', -14.00, 35.00, 16.0000, 224.00, '销售出库', '2026-08-31 13:35:42');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (303, 2, 15, 'SALE_OUT', 'SO20260901-0001', -20.00, 404.00, 50.4104, 1008.21, '销售出库', '2026-09-01 15:54:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (304, 2, 37, 'SALE_OUT', 'SO20260901-0001', -8.00, 17.00, 217.4700, 1739.76, '销售出库', '2026-09-01 15:54:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (305, 2, 35, 'SALE_OUT', 'SO20260901-0001', -7.00, 41.00, 92.4000, 646.80, '销售出库', '2026-09-01 15:54:13');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (306, 1, 2, 'SALE_OUT', 'SO20260901-0002', -38.00, 383.00, 40.3249, 1532.35, '销售出库', '2026-09-01 17:08:48');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (307, 1, 28, 'SALE_OUT', 'SO20260901-0002', -12.00, 23.00, 16.0000, 192.00, '销售出库', '2026-09-01 17:08:48');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (308, 1, 16, 'SALE_OUT', 'SO20260901-0002', -23.00, 164.00, 120.8416, 2779.36, '销售出库', '2026-09-01 17:08:48');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (309, 1, 3, 'SALE_OUT', 'SO20260901-0002', -39.00, 314.00, 43.8641, 1710.70, '销售出库', '2026-09-01 17:08:48');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (310, 1, 1, 'TAKING_GAIN', 'PD20260829-0001', 3.00, 409.00, 43.7964, 131.39, '盘盈调整', '2026-08-29 16:10:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (311, 1, 2, 'TAKING_LOSS', 'PD20260829-0001', -2.00, 381.00, 40.3249, 80.65, '盘亏调整', '2026-08-29 16:10:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (312, 1, 4, 'TAKING_LOSS', 'PD20260829-0001', -4.00, 153.00, 28.9500, 115.80, '盘亏调整', '2026-08-29 16:10:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (313, 1, 5, 'TAKING_GAIN', 'PD20260829-0001', 5.00, 173.00, 52.5349, 262.67, '盘盈调整', '2026-08-29 16:10:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (314, 1, 8, 'TAKING_LOSS', 'PD20260829-0001', -1.00, 77.00, 32.3800, 32.38, '盘亏调整', '2026-08-29 16:10:00');
INSERT INTO stock_flow (id, warehouse_id, product_id, biz_type, biz_no, qty_change, qty_after, price, amount, remark, created_at) VALUES (315, 1, 9, 'TAKING_GAIN', 'PD20260829-0001', 2.00, 137.00, 61.5735, 123.15, '盘盈调整', '2026-08-29 16:10:00');

-- ===== 盘点单 =====
INSERT INTO stock_taking (id, taking_no, warehouse_id, status, remark, created_by, created_at, finished_at) VALUES (1, 'PD20260829-0001', 1, 'FINISHED', '月末例行盘点', 4, '2026-08-29 14:30:00', '2026-08-29 16:10:00');
INSERT INTO stock_taking (id, taking_no, warehouse_id, status, remark, created_by, created_at, finished_at) VALUES (2, 'PD20260831-0001', 2, 'DRAFT', '深圳分仓抽盘', 4, '2026-08-31 10:00:00', NULL);

-- ===== 盘点明细 =====
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (1, 1, 1, 406.00, 409.00, 3.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (2, 1, 2, 383.00, 381.00, -2.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (3, 1, 3, 314.00, 314.00, 0.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (4, 1, 4, 157.00, 153.00, -4.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (5, 1, 5, 168.00, 173.00, 5.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (6, 1, 6, 370.00, 370.00, 0.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (7, 1, 8, 78.00, 77.00, -1.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (8, 1, 9, 135.00, 137.00, 2.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (9, 2, 1, 29.00, NULL, 0.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (10, 2, 2, 222.00, NULL, 0.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (11, 2, 3, 438.00, NULL, 0.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (12, 2, 4, 1052.00, NULL, 0.00);
INSERT INTO stock_taking_item (id, taking_id, product_id, book_qty, actual_qty, diff_qty) VALUES (13, 2, 5, 254.00, NULL, 0.00);

-- ===== 应付账款 =====
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (1, 'PO20260729-0001', 1, 33471.72, 33471.72, 'PAID', '2026-07-29 17:07:30');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (2, 'PO20260729-0002', 8, 30024.15, 0.00, 'UNPAID', '2026-07-29 15:06:13');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (3, 'PO20260729-0003', 5, 27058.96, 27058.96, 'PAID', '2026-07-29 16:43:22');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (4, 'PO20260730-0001', 8, 19499.47, 0.00, 'UNPAID', '2026-07-30 15:38:33');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (5, 'PO20260730-0002', 7, 19754.52, 19754.52, 'PAID', '2026-07-30 13:37:34');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (6, 'PO20260730-0003', 7, 23525.27, 0.00, 'UNPAID', '2026-07-30 12:08:22');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (7, 'PO20260731-0001', 7, 24824.87, 24824.87, 'PAID', '2026-07-31 11:26:54');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (8, 'PO20260731-0002', 1, 21434.86, 21434.86, 'PAID', '2026-07-31 14:36:05');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (9, 'PO20260731-0003', 1, 13260.28, 0.00, 'UNPAID', '2026-07-31 16:51:47');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (10, 'PO20260801-0001', 6, 12984.27, 8938.67, 'PARTIAL', '2026-08-01 13:50:38');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (11, 'PO20260801-0002', 3, 16774.55, 16774.55, 'PAID', '2026-08-01 17:15:00');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (12, 'PO20260801-0003', 5, 33553.41, 33553.41, 'PAID', '2026-08-01 13:44:50');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (13, 'PO20260802-0001', 3, 20207.45, 20207.45, 'PAID', '2026-08-02 14:28:27');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (14, 'PO20260803-0001', 8, 26912.09, 26912.09, 'PAID', '2026-08-03 14:17:00');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (15, 'PO20260804-0001', 4, 14455.26, 4628.04, 'PARTIAL', '2026-08-04 15:23:11');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (16, 'PO20260805-0001', 8, 22907.50, 13896.56, 'PARTIAL', '2026-08-05 14:16:13');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (17, 'PO20260807-0001', 5, 16996.96, 0.00, 'UNPAID', '2026-08-07 13:48:15');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (18, 'PO20260809-0001', 5, 10868.45, 10868.45, 'PAID', '2026-08-09 12:22:57');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (19, 'PO20260811-0001', 7, 32686.96, 32686.96, 'PAID', '2026-08-11 10:59:21');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (20, 'PO20260813-0001', 1, 16288.23, 16288.23, 'PAID', '2026-08-13 12:23:07');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (21, 'PO20260814-0001', 5, 12137.92, 8066.91, 'PARTIAL', '2026-08-14 12:17:38');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (22, 'PO20260815-0001', 8, 16064.89, 16064.89, 'PAID', '2026-08-15 13:40:16');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (23, 'PO20260816-0001', 3, 20861.06, 20861.06, 'PAID', '2026-08-16 10:54:28');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (24, 'PO20260821-0001', 1, 17711.67, 17711.67, 'PAID', '2026-08-21 12:23:43');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (25, 'PO20260824-0001', 3, 39532.01, 24462.05, 'PARTIAL', '2026-08-24 15:29:24');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (26, 'PO20260825-0001', 7, 16444.44, 16444.44, 'PAID', '2026-08-25 13:58:47');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (27, 'PO20260826-0001', 3, 35419.89, 35419.89, 'PAID', '2026-08-26 12:49:14');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (28, 'PO20260827-0001', 7, 16995.13, 0.00, 'UNPAID', '2026-08-27 12:53:37');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (29, 'PO20260828-0001', 6, 33401.32, 33401.32, 'PAID', '2026-08-28 17:00:18');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (30, 'PO20260830-0001', 6, 18360.85, 0.00, 'UNPAID', '2026-08-30 15:02:42');
INSERT INTO payable (id, order_no, supplier_id, total_amount, paid_amount, status, created_at) VALUES (31, 'PO20260831-0001', 8, 25713.14, 0.00, 'UNPAID', '2026-08-31 16:46:26');

-- ===== 付款记录 =====
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (1, 1, 33471.72, '承兑汇票', '货款结清', 1, '2026-08-01 17:07:30');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (2, 3, 27058.96, '银行转账', '货款结清', 1, '2026-08-03 16:43:22');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (3, 5, 19754.52, '现金', '货款结清', 1, '2026-08-03 13:37:34');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (4, 7, 24824.87, '承兑汇票', '货款结清', 1, '2026-08-05 11:26:54');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (5, 8, 21434.86, '承兑汇票', '货款结清', 1, '2026-08-01 14:36:05');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (6, 10, 8938.67, '现金', '首期付款', 1, '2026-08-06 13:50:38');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (7, 11, 16774.55, '现金', '货款结清', 1, '2026-08-06 17:15:00');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (8, 12, 33553.41, '银行转账', '货款结清', 1, '2026-08-05 13:44:50');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (9, 13, 20207.45, '现金', '货款结清', 1, '2026-08-04 14:28:27');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (10, 14, 26912.09, '现金', '货款结清', 1, '2026-08-08 14:17:00');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (11, 15, 4628.04, '现金', '首期付款', 1, '2026-08-08 15:23:11');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (12, 16, 13896.56, '银行转账', '首期付款', 1, '2026-08-07 14:16:13');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (13, 18, 10868.45, '银行转账', '货款结清', 1, '2026-08-13 12:22:57');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (14, 19, 32686.96, '银行转账', '货款结清', 1, '2026-08-16 10:59:21');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (15, 20, 16288.23, '承兑汇票', '货款结清', 1, '2026-08-15 12:23:07');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (16, 21, 8066.91, '承兑汇票', '首期付款', 1, '2026-08-18 12:17:38');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (17, 22, 16064.89, '承兑汇票', '货款结清', 1, '2026-08-19 13:40:16');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (18, 23, 20861.06, '银行转账', '货款结清', 1, '2026-08-21 10:54:28');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (19, 24, 17711.67, '现金', '货款结清', 1, '2026-08-26 12:23:43');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (20, 25, 24462.05, '银行转账', '首期付款', 1, '2026-08-28 15:29:24');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (21, 26, 16444.44, '现金', '货款结清', 1, '2026-08-28 13:58:47');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (22, 27, 35419.89, '银行转账', '货款结清', 1, '2026-08-28 12:49:14');
INSERT INTO payable_record (id, payable_id, amount, pay_method, remark, created_by, created_at) VALUES (23, 29, 33401.32, '银行转账', '货款结清', 1, '2026-09-01 11:37:51');

-- ===== 应收账款 =====
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (1, 'SO20260802-0001', 7, 788.55, 0.00, 'UNRECEIVED', '2026-08-02 17:53:13');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (2, 'SO20260803-0001', 9, 6332.05, 6332.05, 'RECEIVED', '2026-08-03 14:17:43');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (3, 'SO20260804-0001', 7, 2804.75, 961.08, 'PARTIAL', '2026-08-04 19:26:56');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (4, 'SO20260804-0002', 4, 3189.33, 1035.83, 'PARTIAL', '2026-08-04 21:45:29');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (5, 'SO20260805-0001', 9, 5566.18, 5566.18, 'RECEIVED', '2026-08-05 18:33:47');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (6, 'SO20260806-0001', 8, 4550.14, 4550.14, 'RECEIVED', '2026-08-06 15:44:13');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (7, 'SO20260807-0001', 1, 3856.42, 3856.42, 'RECEIVED', '2026-08-07 11:42:02');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (8, 'SO20260808-0001', 4, 2375.68, 0.00, 'UNRECEIVED', '2026-08-08 21:55:08');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (9, 'SO20260808-0002', 9, 8284.11, 8284.11, 'RECEIVED', '2026-08-08 14:39:41');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (10, 'SO20260809-0001', 10, 4138.29, 4138.29, 'RECEIVED', '2026-08-09 16:46:04');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (11, 'SO20260809-0002', 4, 3578.94, 3578.94, 'RECEIVED', '2026-08-09 16:13:11');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (12, 'SO20260810-0001', 8, 2866.68, 1144.99, 'PARTIAL', '2026-08-10 19:40:51');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (13, 'SO20260811-0001', 9, 3847.85, 1555.09, 'PARTIAL', '2026-08-11 17:38:52');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (14, 'SO20260811-0002', 7, 2348.73, 0.00, 'UNRECEIVED', '2026-08-11 17:56:12');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (15, 'SO20260812-0001', 6, 5668.74, 5668.74, 'RECEIVED', '2026-08-12 19:33:29');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (16, 'SO20260812-0002', 2, 2340.91, 0.00, 'UNRECEIVED', '2026-08-12 17:37:10');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (17, 'SO20260813-0001', 8, 5818.07, 0.00, 'UNRECEIVED', '2026-08-13 19:44:39');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (18, 'SO20260813-0002', 7, 4591.55, 4591.55, 'RECEIVED', '2026-08-13 17:04:06');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (19, 'SO20260814-0001', 4, 3979.26, 2763.16, 'PARTIAL', '2026-08-14 17:13:39');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (20, 'SO20260814-0002', 4, 3756.76, 3756.76, 'RECEIVED', '2026-08-14 19:00:20');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (21, 'SO20260815-0001', 2, 2780.26, 2780.26, 'RECEIVED', '2026-08-15 20:06:16');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (22, 'SO20260816-0001', 8, 3308.42, 0.00, 'UNRECEIVED', '2026-08-16 17:41:50');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (23, 'SO20260816-0002', 1, 5623.70, 0.00, 'UNRECEIVED', '2026-08-16 13:15:40');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (24, 'SO20260817-0001', 6, 5742.44, 0.00, 'UNRECEIVED', '2026-08-17 21:54:44');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (25, 'SO20260817-0002', 2, 3643.35, 3643.35, 'RECEIVED', '2026-08-17 14:05:05');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (26, 'SO20260818-0001', 6, 7081.11, 0.00, 'UNRECEIVED', '2026-08-18 13:42:59');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (27, 'SO20260819-0001', 4, 3706.61, 0.00, 'UNRECEIVED', '2026-08-19 21:30:42');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (28, 'SO20260820-0001', 6, 4998.90, 4998.90, 'RECEIVED', '2026-08-20 17:55:07');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (29, 'SO20260821-0001', 9, 3943.01, 3943.01, 'RECEIVED', '2026-08-21 13:49:07');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (30, 'SO20260822-0001', 4, 4792.16, 1931.83, 'PARTIAL', '2026-08-22 16:03:31');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (31, 'SO20260823-0001', 8, 1586.40, 1586.40, 'RECEIVED', '2026-08-23 13:32:07');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (32, 'SO20260823-0002', 10, 5178.37, 2827.95, 'PARTIAL', '2026-08-23 15:59:13');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (33, 'SO20260824-0001', 7, 4593.26, 0.00, 'UNRECEIVED', '2026-08-24 16:33:33');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (34, 'SO20260825-0001', 2, 2653.24, 2653.24, 'RECEIVED', '2026-08-25 14:32:28');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (35, 'SO20260826-0001', 6, 2114.45, 2114.45, 'RECEIVED', '2026-08-26 19:41:12');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (36, 'SO20260826-0002', 6, 7395.50, 7395.50, 'RECEIVED', '2026-08-26 15:18:53');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (37, 'SO20260827-0001', 7, 4669.41, 4669.41, 'RECEIVED', '2026-08-27 17:25:52');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (38, 'SO20260827-0002', 10, 6783.47, 6783.47, 'RECEIVED', '2026-08-27 16:25:16');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (39, 'SO20260828-0001', 8, 5647.18, 3729.31, 'PARTIAL', '2026-08-28 13:55:48');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (40, 'SO20260828-0002', 2, 5797.44, 0.00, 'UNRECEIVED', '2026-08-28 19:21:46');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (41, 'SO20260829-0001', 7, 4098.40, 0.00, 'UNRECEIVED', '2026-08-29 13:11:37');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (42, 'SO20260830-0001', 10, 3042.79, 1164.09, 'PARTIAL', '2026-08-30 16:22:33');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (43, 'SO20260831-0001', 6, 5961.55, 5961.55, 'RECEIVED', '2026-08-31 12:28:32');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (44, 'SO20260831-0002', 4, 2341.88, 2341.88, 'RECEIVED', '2026-08-31 13:35:42');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (45, 'SO20260901-0001', 1, 4674.25, 0.00, 'UNRECEIVED', '2026-09-01 15:54:13');
INSERT INTO receivable (id, order_no, customer_id, total_amount, received_amount, status, created_at) VALUES (46, 'SO20260901-0002', 9, 7811.60, 0.00, 'UNRECEIVED', '2026-09-01 17:08:48');

-- ===== 收款记录 =====
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (1, 2, 6332.05, '银行转账', '货款结清', 1, '2026-08-08 14:17:43');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (2, 3, 961.08, '现金', '首期回款', 1, '2026-08-08 19:26:56');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (3, 4, 1035.83, '支付宝', '首期回款', 1, '2026-08-10 21:45:29');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (4, 5, 5566.18, '支付宝', '货款结清', 1, '2026-08-06 18:33:47');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (5, 6, 4550.14, '银行转账', '货款结清', 1, '2026-08-11 15:44:13');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (6, 7, 3856.42, '银行转账', '货款结清', 1, '2026-08-11 11:42:02');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (7, 9, 8284.11, '银行转账', '货款结清', 1, '2026-08-10 14:39:41');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (8, 10, 4138.29, '银行转账', '货款结清', 1, '2026-08-15 16:46:04');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (9, 11, 3578.94, '银行转账', '货款结清', 1, '2026-08-14 16:13:11');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (10, 12, 1144.99, '支付宝', '首期回款', 1, '2026-08-13 19:40:51');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (11, 13, 1555.09, '微信收款', '首期回款', 1, '2026-08-16 17:38:52');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (12, 15, 5668.74, '微信收款', '货款结清', 1, '2026-08-14 19:33:29');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (13, 18, 4591.55, '支付宝', '货款结清', 1, '2026-08-14 17:04:06');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (14, 19, 2763.16, '银行转账', '首期回款', 1, '2026-08-15 17:13:39');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (15, 20, 3756.76, '微信收款', '货款结清', 1, '2026-08-18 19:00:20');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (16, 21, 2780.26, '现金', '货款结清', 1, '2026-08-17 20:06:16');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (17, 25, 3643.35, '银行转账', '货款结清', 1, '2026-08-21 14:05:05');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (18, 28, 4998.90, '微信收款', '货款结清', 1, '2026-08-26 17:55:07');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (19, 29, 3943.01, '支付宝', '货款结清', 1, '2026-08-26 13:49:07');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (20, 30, 1931.83, '银行转账', '首期回款', 1, '2026-08-23 16:03:31');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (21, 31, 1586.40, '微信收款', '货款结清', 1, '2026-08-26 13:32:07');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (22, 32, 2827.95, '支付宝', '首期回款', 1, '2026-08-28 15:59:13');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (23, 34, 2653.24, '银行转账', '货款结清', 1, '2026-08-27 14:32:28');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (24, 35, 2114.45, '现金', '货款结清', 1, '2026-08-27 19:41:12');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (25, 36, 7395.50, '现金', '货款结清', 1, '2026-09-01 11:37:51');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (26, 37, 4669.41, '现金', '货款结清', 1, '2026-09-01 11:37:51');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (27, 38, 6783.47, '微信收款', '货款结清', 1, '2026-09-01 11:37:51');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (28, 39, 3729.31, '现金', '首期回款', 1, '2026-09-01 11:37:51');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (29, 42, 1164.09, '银行转账', '首期回款', 1, '2026-09-01 11:37:51');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (30, 43, 5961.55, '支付宝', '货款结清', 1, '2026-09-01 11:37:51');
INSERT INTO receivable_record (id, receivable_id, amount, receive_method, remark, created_by, created_at) VALUES (31, 44, 2341.88, '微信收款', '货款结清', 1, '2026-09-01 11:37:51');

-- ===== 重置序列 =====
SELECT setval(pg_get_serial_sequence('sys_user', 'id'), COALESCE((SELECT MAX(id) FROM sys_user), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('product_category', 'id'), COALESCE((SELECT MAX(id) FROM product_category), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('product', 'id'), COALESCE((SELECT MAX(id) FROM product), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('supplier', 'id'), COALESCE((SELECT MAX(id) FROM supplier), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('customer', 'id'), COALESCE((SELECT MAX(id) FROM customer), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('warehouse', 'id'), COALESCE((SELECT MAX(id) FROM warehouse), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('purchase_order', 'id'), COALESCE((SELECT MAX(id) FROM purchase_order), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('purchase_order_item', 'id'), COALESCE((SELECT MAX(id) FROM purchase_order_item), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('sale_order', 'id'), COALESCE((SELECT MAX(id) FROM sale_order), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('sale_order_item', 'id'), COALESCE((SELECT MAX(id) FROM sale_order_item), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('stock', 'id'), COALESCE((SELECT MAX(id) FROM stock), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('stock_flow', 'id'), COALESCE((SELECT MAX(id) FROM stock_flow), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('stock_taking', 'id'), COALESCE((SELECT MAX(id) FROM stock_taking), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('stock_taking_item', 'id'), COALESCE((SELECT MAX(id) FROM stock_taking_item), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('payable', 'id'), COALESCE((SELECT MAX(id) FROM payable), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('payable_record', 'id'), COALESCE((SELECT MAX(id) FROM payable_record), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('receivable', 'id'), COALESCE((SELECT MAX(id) FROM receivable), 0) + 1, false);
SELECT setval(pg_get_serial_sequence('receivable_record', 'id'), COALESCE((SELECT MAX(id) FROM receivable_record), 0) + 1, false);

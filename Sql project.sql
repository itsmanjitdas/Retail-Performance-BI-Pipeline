CREATE DATABASE IF NOT EXISTS retail_analysis;
USE retail_analysis;
-- 1. brands
ALTER TABLE brands
  CHANGE `Brand Id`   brand_id   INT NOT NULL,
  CHANGE `Brand Name` brand_name VARCHAR(100);
ALTER TABLE brands ADD PRIMARY KEY (brand_id);

-- 2. categories
ALTER TABLE categories
  CHANGE `Category Id`   category_id   INT NOT NULL,
  CHANGE `Category Name` category_name VARCHAR(100);
ALTER TABLE categories ADD PRIMARY KEY (category_id);
-- 3. stores
ALTER TABLE stores
  CHANGE `Store Id`   store_id   INT NOT NULL,
  CHANGE `Store Name` store_name VARCHAR(100),
  CHANGE `Phone`      phone      VARCHAR(20),
  CHANGE `Email`      email      VARCHAR(100),
  CHANGE `Street`     street     VARCHAR(200),
  CHANGE `City`       city       VARCHAR(100),
  CHANGE `State`      state      CHAR(2),
  CHANGE `Zip Code`   zip_code   VARCHAR(10);
ALTER TABLE stores ADD PRIMARY KEY (store_id);
-- 4. customers
ALTER TABLE customer_cleaned
  CHANGE `Customer Id` customer_id INT NOT NULL,
  CHANGE `First Name`  first_name  VARCHAR(100),
  CHANGE `Last Name`   last_name   VARCHAR(100),
  CHANGE `Phone`       phone       VARCHAR(20),
  CHANGE `Email`       email       VARCHAR(150),
  CHANGE `Street`      street      VARCHAR(200),
  CHANGE `City`        city        VARCHAR(100),
  CHANGE `State`       state       CHAR(2),
  CHANGE `Zip Code`    zip_code    VARCHAR(10);
ALTER TABLE customer_cleaned ADD PRIMARY KEY (customer_id);

SET SQL_SAFE_UPDATES = 0;
-- 5. staffs
UPDATE staffs SET `Manager Id` = NULL WHERE `Manager Id` = '';
ALTER TABLE staffs
  CHANGE `Staff Id`   staff_id   INT NOT NULL,
  CHANGE `First Name` first_name VARCHAR(100),
  CHANGE `Last Name`  last_name  VARCHAR(100),
  CHANGE `Email`      email      VARCHAR(150),
  CHANGE `Phone`      phone      VARCHAR(20),
  CHANGE `Active`     active     TINYINT,
  CHANGE `Store Id`   store_id   INT,
  CHANGE `Manager Id` manager_id INT NULL;
  ALTER TABLE staffs ADD PRIMARY KEY (staff_id);


-- 6. products
ALTER TABLE products_cleaned
  CHANGE `Product Id`   product_id   INT NOT NULL,
  CHANGE `Product Name` product_name VARCHAR(200),
  CHANGE `Brand Id`     brand_id     INT,
  CHANGE `Category Id`  category_id  INT,
  CHANGE `Model Year`   model_year   INT,
  CHANGE `List Price`   list_price   DECIMAL(10,2);
ALTER TABLE products_cleaned ADD PRIMARY KEY (product_id);
-- 7. orders

ALTER TABLE orders_clean
  CHANGE `Order Id`      order_id      INT NOT NULL,
  CHANGE `Customer Id`   customer_id   INT,
  CHANGE `Order Status`  order_status  TINYINT,
  CHANGE `Order Date`    order_date    DATE,
  CHANGE `Required Date` required_date DATE,
  CHANGE `Shipped Date`  shipped_date  DATE,
  CHANGE `Store Id`      store_id      INT,
  CHANGE `Staff Id`      staff_id      INT;
ALTER TABLE orders_clean ADD PRIMARY KEY (order_id);


-- 8. order_items
ALTER TABLE order_items_cleaned
  CHANGE `Order Id`   order_id   INT NOT NULL,
  CHANGE `Item Id`    item_id    INT NOT NULL,
  CHANGE `Product Id` product_id INT,
  CHANGE `Quantity`   quantity   INT,
  CHANGE `List Price` list_price DECIMAL(10,2),
  CHANGE `Discount`   discount   DECIMAL(4,2);
ALTER TABLE order_items_cleaned ADD PRIMARY KEY (order_id, item_id);

-- 9. stocks
ALTER TABLE stocks_clened
  CHANGE `Store Id`   store_id   INT NOT NULL,
  CHANGE `Product Id` product_id INT NOT NULL,
  CHANGE `Quantity`   quantity   INT;
ALTER TABLE stocks_clened ADD PRIMARY KEY (store_id, product_id);

ALTER TABLE categories
  CHANGE `category Id` category_id INT NOT NULL,
    CHANGE `category Name` category_name VARCHAR(200);
ALTER TABLE categories ADD PRIMARY KEY (category_id);

-- Add All 8 Foreign Keys
-- 1. customers → orders
ALTER TABLE orders_clean
  ADD CONSTRAINT fk_orders_customer
  FOREIGN KEY (customer_id) REFERENCES customer_cleaned(customer_id);
  
  
  SELECT oi.order_id
FROM order_items_cleaned oi
LEFT JOIN orders_clean o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

DELETE oi
FROM order_items_cleaned oi
LEFT JOIN orders_clean o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


  -- 2. orders → order_items
ALTER TABLE order_items_cleaned
  ADD CONSTRAINT fk_items_order
  FOREIGN KEY (order_id) REFERENCES orders_clean(order_id);

-- 3. products → order_items
ALTER TABLE order_items_cleaned
  ADD CONSTRAINT fk_items_product
  FOREIGN KEY (product_id) REFERENCES products_cleaned(product_id);

-- 4. stores → orders
ALTER TABLE orders_clean
  ADD CONSTRAINT fk_orders_store
  FOREIGN KEY (store_id) REFERENCES stores(store_id);

-- 5. staffs → orders
ALTER TABLE orders_clean
  ADD CONSTRAINT fk_orders_staff
  FOREIGN KEY (staff_id) REFERENCES staffs(staff_id);

-- 6. brands → products
ALTER TABLE products_cleaned
  ADD CONSTRAINT fk_products_brand
  FOREIGN KEY (brand_id) REFERENCES brands(brand_id);

-- 7. categories → products
ALTER TABLE products_cleaned
  ADD CONSTRAINT fk_products_category
  FOREIGN KEY (category_id) REFERENCES categories(category_id);

-- 8. stores → stocks  +  products → stocks
ALTER TABLE stocks_clened
  ADD CONSTRAINT fk_stocks_store
  FOREIGN KEY (store_id) REFERENCES stores(store_id);

ALTER TABLE stocks_clened
  ADD CONSTRAINT fk_stocks_product
  FOREIGN KEY (product_id) REFERENCES products_cleaned(product_id);
  
  SELECT COUNT(*) AS orphan_orders
FROM orders_clean o
LEFT JOIN customer_cleaned c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
-- Check order_items with no matching order
SELECT COUNT(*) AS orphan_items
FROM order_items_cleaned oi
LEFT JOIN orders_clean o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check order_items with no matching product
SELECT COUNT(*) AS orphan_products
FROM order_items_cleaned oi
LEFT JOIN products_cleaned p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Check stocks with no matching store
SELECT COUNT(*) AS orphan_stocks_store
FROM stocks_clened s
LEFT JOIN stores st ON s.store_id = st.store_id
WHERE st.store_id IS NULL;

-- 1. Total revenue by store
SELECT st.store_name,
  ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS total_revenue
FROM orders_clean o
JOIN order_items_cleaned oi ON o.order_id = oi.order_id
JOIN stores st ON o.store_id = st.store_id
GROUP BY st.store_name ORDER BY total_revenue DESC;

-- 2. Total revenue by store
SELECT 
  st.store_name,
  COUNT(DISTINCT o.order_id) AS total_orders,
  SUM(oi.quantity) AS units_sold,
  ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS total_revenue
FROM orders_cleaned o
JOIN order_items_cleaned oi ON o.order_id = oi.order_id
JOIN stores st ON o.store_id = st.store_id
GROUP BY st.store_name
ORDER BY total_revenue DESC;

-- Top 10 selling products
SELECT p.product_name,
       SUM(oi.quantity) AS units_sold,
       SUM(oi.net_revenue) AS revenue
FROM order_items_cleaned oi
JOIN products_cleaned p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY units_sold DESC LIMIT 10;


-- 3.Sales by Store
SELECT 
    st.store_name,
    ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)),
            2) AS revenue
FROM
    orders_cleaned o
        JOIN
    order_items_cleaned oi ON o.order_id = oi.order_id
        JOIN
    stores st ON o.store_id = st.store_id
GROUP BY st.store_name
ORDER BY revenue DESC;

-- Customer Analysis
-- 1. Repeat Customers
SELECT 
    customer_id, COUNT(order_id) AS total_orders
FROM
    orders_clean
GROUP BY customer_id
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;

-- 2.  Highest spenders customer
SELECT 
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.list_price) AS total_spend
FROM orders_clean o
JOIN order_items_cleaned oi ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY total_spend DESC
LIMIT 10;

-- Inventory Analysis
SELECT 
    s.store_name,
    p.product_name,
    st.quantity AS stock_remaining
FROM stocks_clened st
JOIN stores s ON st.store_id = s.store_id
JOIN products_cleaned p ON st.product_id = p.product_id
ORDER BY s.store_name, st.quantity DESC;

-- 1. Sales Views
CREATE VIEW v_sales_summary AS
SELECT 
    o.order_id,
    o.order_date,
    o.customer_id,
    s.store_id,
    s.store_name,
    oi.product_id,
    oi.quantity,
    oi.list_price,
    (oi.quantity * oi.list_price) AS line_item_total
FROM orders_clean o
JOIN order_items_cleaned oi ON o.order_id = oi.order_id
JOIN stores s ON o.store_id = s.store_id;


-- 1.Top Products View
CREATE VIEW v_top_performing_products AS
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.list_price) AS total_revenue
    FROM
        order_items_cleaned oi
            JOIN
        products_cleaned p ON oi.product_id = p.product_id
    GROUP BY p.product_id , p.product_name;

-- 2. Customer Performance View

CREATE VIEW v_customer_lifetime_value AS
SELECT 
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS lifetime_orders,
    SUM(oi.quantity * oi.list_price) AS lifetime_spend
FROM orders_clean o
JOIN order_items_cleaned oi ON o.order_id = oi.order_id
GROUP BY o.customer_id;

-- 3. Inventory View
  -- Current Stock Status
  CREATE VIEW v_current_inventory_status AS
SELECT 
    st.store_id,
    s.store_name,
    p.product_id,
    p.product_name,
    st.quantity AS current_stock
FROM stocks_clened st
JOIN stores s ON st.store_id = s.store_id
JOIN products_cleaned p ON st.product_id = p.product_id;


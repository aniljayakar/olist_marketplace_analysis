/*
Purpose:
  Consolidated schema setup, source data audits, and core fact-table builds for the
  Olist marketplace analysis.

Grain:
  Mixed.
  - Source DDL at table grain
  - Audit checks at table and business key grain
  - fact_order_items_clean at order item grain
  - fact_orders_clean at order grain

Primary inputs:
  orders
  customers
  order_items
  order_payments
  order_reviews
  products
  sellers
  category_translation

Business definitions:
  - item_gmv = price + freight_value at order item grain
  - order_gmv = SUM(price + freight_value) at order grain
  - delivery_days = delivered customer date - purchase date
  - late_delivery_flag = 1 when actual delivery exceeds estimated delivery date

Key assumptions / caveats:
  - Source tables are recreated without constraints or indexes in this script.
  - order_payments is audited separately because payments can create multiple rows per order.
  - Missing category translations are labeled as 'Unknown' for reporting continuity.
  - LEFT JOINs are used in fact builds to preserve source order and order item coverage.
*/

-- ============================================================================
-- Source Table DDL
-- ============================================================================

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state TEXT
);

DROP TABLE IF EXISTS order_items;

CREATE TABLE order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

DROP TABLE IF EXISTS order_payments;

CREATE TABLE order_payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC
);

DROP TABLE IF EXISTS order_reviews;

CREATE TABLE order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

DROP TABLE IF EXISTS products;

CREATE TABLE products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght NUMERIC,
    product_description_lenght NUMERIC,
    product_photos_qty NUMERIC,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

DROP TABLE IF EXISTS sellers;

CREATE TABLE sellers (
    seller_id TEXT,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state TEXT
);

DROP TABLE IF EXISTS category_translation;

CREATE TABLE category_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);

-- ============================================================================
-- Source Validation
-- ============================================================================

-- Row counts provide a quick completeness check after load.
SELECT
    'orders' AS table_name,
    COUNT(*) AS row_count
FROM orders

UNION ALL

SELECT
    'customers' AS table_name,
    COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT
    'order_items' AS table_name,
    COUNT(*) AS row_count
FROM order_items

UNION ALL

SELECT
    'order_payments' AS table_name,
    COUNT(*) AS row_count
FROM order_payments

UNION ALL

SELECT
    'order_reviews' AS table_name,
    COUNT(*) AS row_count
FROM order_reviews

UNION ALL

SELECT
    'products' AS table_name,
    COUNT(*) AS row_count
FROM products

UNION ALL

SELECT
    'sellers' AS table_name,
    COUNT(*) AS row_count
FROM sellers

UNION ALL

SELECT
    'category_translation' AS table_name,
    COUNT(*) AS row_count
FROM category_translation;

-- Business key checks highlight sources that may duplicate expected unique entities.
SELECT
    order_id,
    COUNT(*) AS row_count
FROM orders
GROUP BY
    order_id
HAVING COUNT(*) > 1;

SELECT
    customer_id,
    COUNT(*) AS row_count
FROM customers
GROUP BY
    customer_id
HAVING COUNT(*) > 1;

SELECT
    product_id,
    COUNT(*) AS row_count
FROM products
GROUP BY
    product_id
HAVING COUNT(*) > 1;

SELECT
    seller_id,
    COUNT(*) AS row_count
FROM sellers
GROUP BY
    seller_id
HAVING COUNT(*) > 1;

SELECT
    product_category_name,
    COUNT(*) AS row_count
FROM category_translation
GROUP BY
    product_category_name
HAVING COUNT(*) > 1;

SELECT
    order_id,
    COUNT(*) AS row_count
FROM order_reviews
GROUP BY
    order_id
HAVING COUNT(*) > 1;

-- Null audits focus on fields that materially affect joins, segmentation, and delivery analysis.

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_ts,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated_delivery
FROM orders;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_item_id IS NULL) AS null_order_item_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE freight_value IS NULL) AS null_freight_value
FROM order_items;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE payment_type IS NULL) AS null_payment_type,
    COUNT(*) FILTER (WHERE payment_value IS NULL) AS null_payment_value
FROM order_payments;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE review_id IS NULL) AS null_review_id,
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE review_score IS NULL) AS null_review_score
FROM order_reviews;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_product_category_name
FROM products;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE customer_state IS NULL) AS null_customer_state
FROM customers;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE seller_state IS NULL) AS null_seller_state
FROM sellers;

-- Join coverage checks quantify enrichment loss before fact construction.
SELECT
    COUNT(*) AS unmatched_order_items
FROM order_items AS oi
LEFT JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT
    COUNT(*) AS unmatched_order_items_products
FROM order_items AS oi
LEFT JOIN products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT
    COUNT(*) AS unmatched_order_items_sellers
FROM order_items AS oi
LEFT JOIN sellers AS s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT
    COUNT(*) AS unmatched_orders_customers
FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
    COUNT(*) AS unmatched_products_categories
FROM products AS p
LEFT JOIN category_translation AS ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL;

-- Payments sit at a lower grain than orders, so duplicate order_id values are expected.
SELECT
    order_id,
    COUNT(*) AS payment_rows
FROM order_payments
GROUP BY
    order_id
HAVING COUNT(*) > 1
ORDER BY
    payment_rows DESC;

-- ============================================================================
-- Fact Table Build: Order Item Grain
-- ============================================================================

DROP TABLE IF EXISTS fact_order_items_clean;

CREATE TABLE fact_order_items_clean AS
SELECT
    -- identifiers
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,

    -- dimensions
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    p.product_category_name,
    COALESCE(ct.product_category_name_english, 'Unknown') AS product_category_english,
    c.customer_city,
    c.customer_state,
    s.seller_city,
    s.seller_state,

    -- metrics
    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS item_gmv,

    -- derived features
    DATE(o.order_purchase_timestamp) AS purchase_date,
    DATE_TRUNC('month', o.order_purchase_timestamp) AS purchase_month,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
            AND o.order_purchase_timestamp IS NOT NULL
            THEN DATE(o.order_delivered_customer_date) - DATE(o.order_purchase_timestamp)
        ELSE NULL
    END AS delivery_days,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
            AND o.order_estimated_delivery_date IS NOT NULL
            AND o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1
        ELSE 0
    END AS late_delivery_flag
FROM order_items AS oi
LEFT JOIN orders AS o
    ON oi.order_id = o.order_id
LEFT JOIN products AS p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation AS ct
    ON p.product_category_name = ct.product_category_name
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN sellers AS s
    ON oi.seller_id = s.seller_id;

-- Validation checks confirm that item-grain preservation holds after enrichment.
SELECT
    COUNT(*) AS fact_rows
FROM fact_order_items_clean;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id
FROM fact_order_items_clean;

SELECT
    product_category_english,
    COUNT(*) AS row_count
FROM fact_order_items_clean
GROUP BY
    product_category_english
ORDER BY
    COUNT(*) DESC
LIMIT 10;

SELECT
    COUNT(*) AS fact_rows
FROM fact_order_items_clean;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS null_seller_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id
FROM fact_order_items_clean;

-- ============================================================================
-- Fact Table Build: Order Grain
-- ============================================================================

DROP TABLE IF EXISTS fact_orders_clean;

CREATE TABLE fact_orders_clean AS
SELECT
    -- identifiers
    o.order_id,
    o.customer_id,

    -- dimensions
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_city,
    c.customer_state,

    -- metrics
    COUNT(oi.order_item_id) AS total_items,
    COUNT(DISTINCT oi.product_id) AS distinct_products,
    COUNT(DISTINCT oi.seller_id) AS distinct_sellers,
    SUM(oi.price) AS items_gmv,
    SUM(oi.freight_value) AS total_freight_value,
    SUM(oi.price + oi.freight_value) AS order_gmv,

    -- derived features
    DATE(o.order_purchase_timestamp) AS purchase_date,
    DATE_TRUNC('month', o.order_purchase_timestamp) AS purchase_month,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
            AND o.order_purchase_timestamp IS NOT NULL
            THEN DATE(o.order_delivered_customer_date) - DATE(o.order_purchase_timestamp)
        ELSE NULL
    END AS delivery_days,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
            AND o.order_estimated_delivery_date IS NOT NULL
            AND o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1
        ELSE 0
    END AS late_delivery_flag
FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_city,
    c.customer_state;

-- Validation checks confirm order-grain aggregation completeness.
SELECT
    COUNT(*) AS order_rows
FROM fact_orders_clean;

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE order_gmv IS NULL) AS null_order_gmv
FROM fact_orders_clean;

SELECT
    late_delivery_flag,
    COUNT(*) AS row_count
FROM fact_orders_clean
GROUP BY
    late_delivery_flag
ORDER BY
    late_delivery_flag;

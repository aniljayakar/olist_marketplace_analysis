/*
Purpose:
  Validate source completeness, business key behavior, null exposure, and join
  coverage before downstream fact-table construction.

Grain:
  Mixed.
  - Table-level row counts
  - Business key duplicate checks
  - Table-level null audits
  - Relationship-level join coverage

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
  - Duplicate business key checks identify entities that are expected to be unique.
  - Join coverage checks quantify how many records would fail dimensional enrichment.

Key assumptions / caveats:
  - Duplicate `order_id` values in `order_payments` are expected because payments can
    exist at a lower grain than orders.
  - Null audits focus on fields that materially affect joins, segmentation, and
    delivery analysis.
*/

-- ============================================================================
-- Row Count Validation
-- ============================================================================

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

-- ============================================================================
-- Business Key Validation
-- ============================================================================

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

-- ============================================================================
-- Null Audits
-- ============================================================================

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

-- ============================================================================
-- Join Coverage Validation
-- ============================================================================

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

-- Payments are intentionally reviewed separately because the table can contain
-- multiple rows per order.
SELECT
    order_id,
    COUNT(*) AS payment_rows
FROM order_payments
GROUP BY
    order_id
HAVING COUNT(*) > 1
ORDER BY
    payment_rows DESC;

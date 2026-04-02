/*
Purpose:
  Build the order-grain fact table used for order-level marketplace and delivery
  performance analysis.

Grain:
  One row per order.

Primary inputs:
  orders
  customers
  order_items

Business definitions:
  - total_items = count of order item rows attached to the order
  - distinct_products = distinct product count within the order
  - distinct_sellers = distinct seller count within the order
  - items_gmv = SUM(price)
  - total_freight_value = SUM(freight_value)
  - order_gmv = SUM(price + freight_value)
  - purchase_date = calendar date of order purchase timestamp
  - purchase_month = month bucket derived from order purchase timestamp
  - delivery_days = delivered customer date - purchase date
  - late_delivery_flag = 1 when actual delivery exceeds estimated delivery date

Key assumptions / caveats:
  - LEFT JOINs preserve all orders even when customer or order item enrichment is incomplete.
  - Order-level metrics are aggregated from `order_items`, so duplicate order rows are
    controlled through the `GROUP BY` at order grain.
*/

-- ============================================================================
-- Fact Table Build
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

-- ============================================================================
-- Validation Checks
-- ============================================================================

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

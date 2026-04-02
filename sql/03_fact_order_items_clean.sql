/*
Purpose:
  Build the core item-grain fact table used for marketplace performance analysis and
  attach core order, customer, seller, and product attributes.

Grain:
  One row per order item.

Primary inputs:
  order_items
  orders
  products
  category_translation
  customers
  sellers

Business definitions:
  - item_gmv = price + freight_value
  - purchase_date = calendar date of order purchase timestamp
  - purchase_month = month bucket derived from order purchase timestamp
  - delivery_days = delivered customer date - purchase date
  - late_delivery_flag = 1 when actual delivery exceeds estimated delivery date

Key assumptions / caveats:
  - LEFT JOINs preserve the order item grain even when enrichment attributes are missing.
  - Missing product category translations are labeled as 'Unknown' to maintain
    reporting continuity.
*/

-- ============================================================================
-- Fact Table Build
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

-- ============================================================================
-- Validation Checks
-- ============================================================================

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

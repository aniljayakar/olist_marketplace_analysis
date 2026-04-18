-- 08_q02_delivery_performance_by_category.sql
/*
Purpose:
 Analyse delivery performance by product category to identify categories
 that appear more often in late-delivered orders.

Grain:
 One row per product_category_english.

Primary inputs:
 fact_order_items_clean

Business definitions:
 delivered_order_items = total delivered item rows in the category
 late_delivered_items = delivered item rows where the parent order was delivered late
 late_delivery_rate = late_delivered_items / delivered_order_items
 avg_delivery_days = average number of delivery days for delivered item rows in the category

Key assumptions / caveats:
 Product category is analysed at item grain because one order can contain
 multiple categories.
 late_delivery_flag and delivery_days are inherited from the parent order,
 so this analysis does not represent separate item-level delivery events.
 The metric shows which categories appear more often inside late-delivered
 orders, not which individual items were delivered late independently.
 Small-volume categories can produce unstable late-delivery rates, so volume
 should be reviewed before prioritising findings.
*/

WITH category_metrics AS (
    SELECT
        product_category_english,
        COUNT(*) AS delivered_order_items,
        SUM(late_delivery_flag) AS late_delivered_items,
        ROUND(SUM(late_delivery_flag)::numeric / COUNT(*), 4) AS late_delivery_rate,
        ROUND(AVG(delivery_days), 2) AS avg_delivery_days
    FROM fact_order_items_clean
    WHERE order_status = 'delivered'
    GROUP BY
        product_category_english
)
SELECT
    product_category_english,
    delivered_order_items,
    late_delivered_items,
    late_delivery_rate,
    avg_delivery_days
FROM category_metrics
WHERE delivered_order_items >= 100
ORDER BY
    late_delivery_rate DESC,
    delivered_order_items DESC;

-- Q-02 follow-up cut:
-- categories creating the highest absolute late-delivery burden

WITH category_metrics AS (
    SELECT
        product_category_english,
        COUNT(*) AS delivered_order_items,
        SUM(late_delivery_flag) AS late_delivered_items,
        ROUND(SUM(late_delivery_flag)::numeric / COUNT(*), 4) AS late_delivery_rate,
        ROUND(AVG(delivery_days), 2) AS avg_delivery_days
    FROM fact_order_items_clean
    WHERE order_status = 'delivered'
    GROUP BY
        product_category_english
)
SELECT
    product_category_english,
    delivered_order_items,
    late_delivered_items,
    late_delivery_rate,
    avg_delivery_days
FROM category_metrics
WHERE delivered_order_items >= 100
ORDER BY
    late_delivered_items DESC,
    delivered_order_items DESC;


-- Q-02 Support: Delivery performance by business segment
/*
Purpose:
 Roll product-category delivery performance up to business segment level
 using category_mapping. This shows whether delivery issues cluster across
 broader product groups rather than only isolated raw categories.

Grain:
 One row per business_segment.

Primary inputs:
 fact_order_items_clean
 category_mapping

Important caveat:
 Delivery fields are inherited from the parent order. This means the metric
 represents the share of delivered item rows in each segment whose parent
 orders were delivered late, not true item-level logistics performance.

Filters:
 Delivered orders only, because late-delivery rate and delivery duration are
 only meaningful for fulfilled orders.
*/

WITH segment_delivery AS (
    SELECT
        cm.business_segment,
        COUNT(*) AS delivered_order_items,
        COUNT(DISTINCT foi.order_id) AS delivered_orders_containing_segment,
        SUM(foi.late_delivery_flag) AS late_delivered_items,
        ROUND(
            100.0 * SUM(foi.late_delivery_flag)::numeric / COUNT(*),
            2
        ) AS late_delivery_rate_pct,
        ROUND(AVG(foi.delivery_days)::numeric, 2) AS avg_delivery_days,
        ROUND(SUM(foi.item_gmv)::numeric, 2) AS segment_gmv
    FROM fact_order_items_clean AS foi
    LEFT JOIN category_mapping AS cm
        ON foi.product_category_english = cm.product_category_english
    WHERE foi.order_status = 'delivered'
      AND foi.delivery_days IS NOT NULL
    GROUP BY
        cm.business_segment
)
SELECT
    business_segment,
    delivered_order_items,
    delivered_orders_containing_segment,
    late_delivered_items,
    late_delivery_rate_pct,
    avg_delivery_days,
    segment_gmv
FROM segment_delivery
ORDER BY
    late_delivery_rate_pct DESC,
    delivered_order_items DESC;
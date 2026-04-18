/*
Q-11 Category review score drivers

Business question:
Which categories consistently score below 4.0 and above 4.5,
and does delivery performance help explain the gap?

Important grain note:
Do not average reviews directly from raw item rows.
First collapse to one row per order_id + product_category_english,
then join review_summary at order grain.
*/

WITH order_category_base AS (
    SELECT
        foi.order_id,
        foi.product_category_english,
        MAX(foi.order_status) AS order_status,
        MAX(foi.delivery_days) AS delivery_days,
        MAX(foi.late_delivery_flag) AS late_delivery_flag,
        COUNT(*) AS category_order_items,
        SUM(foi.item_gmv) AS category_order_gmv
    FROM fact_order_items_clean AS foi
    GROUP BY
        foi.order_id,
        foi.product_category_english
),
order_category_review AS (
    SELECT
        ocb.order_id,
        ocb.product_category_english,
        ocb.delivery_days,
        ocb.late_delivery_flag,
        ocb.category_order_items,
        ocb.category_order_gmv,
        rs.avg_review_score
    FROM order_category_base AS ocb
    LEFT JOIN review_summary AS rs
        ON ocb.order_id = rs.order_id
    WHERE ocb.order_status = 'delivered'
),
category_metrics AS (
    SELECT
        product_category_english,
        COUNT(*) AS delivered_orders_containing_category,
        COUNT(*) FILTER (WHERE avg_review_score IS NOT NULL) AS reviewed_orders,
        ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
        ROUND(
            100.0 * AVG(CASE WHEN late_delivery_flag = 1 THEN 1.0 ELSE 0.0 END)::numeric,
            2
        ) AS late_delivery_rate_pct,
        ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
        ROUND(SUM(category_order_gmv)::numeric, 2) AS category_gmv
    FROM order_category_review
    GROUP BY
        product_category_english
),
category_flagged AS (
    SELECT
        *,
        CASE
            WHEN avg_review_score < 4.0 THEN 'Low rated'
            WHEN avg_review_score >= 4.5 THEN 'High rated'
            ELSE 'Mid band'
        END AS category_review_band
    FROM category_metrics
    WHERE reviewed_orders >= 100
)
SELECT
    product_category_english,
    delivered_orders_containing_category,
    reviewed_orders,
    avg_review_score,
    late_delivery_rate_pct,
    avg_delivery_days,
    category_gmv,
    category_review_band
FROM category_flagged
ORDER BY
    avg_review_score ASC,
    reviewed_orders DESC;


--does delivery performance explain the gap?
WITH order_category_base AS (
    SELECT
        foi.order_id,
        foi.product_category_english,
        MAX(foi.order_status) AS order_status,
        MAX(foi.delivery_days) AS delivery_days,
        MAX(foi.late_delivery_flag) AS late_delivery_flag
    FROM fact_order_items_clean AS foi
    GROUP BY
        foi.order_id,
        foi.product_category_english
),
order_category_review AS (
    SELECT
        ocb.order_id,
        ocb.product_category_english,
        ocb.delivery_days,
        ocb.late_delivery_flag,
        rs.avg_review_score
    FROM order_category_base AS ocb
    LEFT JOIN review_summary AS rs
        ON ocb.order_id = rs.order_id
    WHERE ocb.order_status = 'delivered'
),
category_metrics AS (
    SELECT
        product_category_english,
        COUNT(*) AS delivered_orders_containing_category,
        COUNT(*) FILTER (WHERE avg_review_score IS NOT NULL) AS reviewed_orders,
        AVG(avg_review_score) AS avg_review_score,
        AVG(CASE WHEN late_delivery_flag = 1 THEN 1.0 ELSE 0.0 END) AS late_delivery_rate,
        AVG(delivery_days) AS avg_delivery_days
    FROM order_category_review
    GROUP BY
        product_category_english
),
category_flagged AS (
    SELECT
        *,
        CASE
            WHEN avg_review_score < 4.0 THEN 'Low rated'
            WHEN avg_review_score >= 4.5 THEN 'High rated'
            ELSE 'Mid band'
        END AS category_review_band
    FROM category_metrics
    WHERE reviewed_orders >= 100
)
SELECT
    category_review_band,
    COUNT(*) AS category_count,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
    ROUND(100.0 * AVG(late_delivery_rate)::numeric, 2) AS avg_late_delivery_rate_pct,
    ROUND(AVG(avg_delivery_days)::numeric, 2) AS avg_delivery_days
FROM category_flagged
WHERE category_review_band IN ('Low rated', 'High rated')
GROUP BY
    category_review_band
ORDER BY
    avg_review_score;

/* Category-level satisfaction showed a modest but consistent relationship with delivery performance. 
Lower-rated categories tended to have both higher late-delivery rates and longer average delivery times
 than mid-band and high-rated categories. The clearest separation appeared in delivery duration: low-rated
  categories averaged 13.87 delivery days versus 12.13 for the mid band. This suggests logistics performance 
  is associated with weaker category satisfaction, but the size of the gap indicates delivery is likely only 
  one part of the explanation. */


  -- Q-11 Support: Review and delivery performance by business segment
/*
Purpose:
 Roll category-level review and delivery analysis up to business segment level
 using category_mapping. This shows whether weak review performance clusters
 across broader product groups rather than isolated raw categories.

Grain:
 One row per business_segment.

Important grain note:
 Reviews and delivery fields are order-level signals.
 To avoid item-level fan-out, item rows are first collapsed to one row per
 order_id + business_segment before joining to review_summary.

Primary inputs:
 fact_order_items_clean
 category_mapping
 review_summary

Key assumptions / caveats:
 Segment-level review score is a proxy based on reviews from orders containing
 that business segment.
 If an order contains multiple segments, the order review is attributed to each
 segment present in the order.
 Delivered orders only are used for delivery metrics.
*/

WITH order_segment_base AS (
    SELECT
        foi.order_id,
        cm.business_segment,
        MAX(foi.order_status) AS order_status,
        MAX(foi.delivery_days) AS delivery_days,
        MAX(foi.late_delivery_flag) AS late_delivery_flag,
        COUNT(*) AS segment_order_items,
        SUM(foi.item_gmv) AS segment_order_gmv
    FROM fact_order_items_clean AS foi
    LEFT JOIN category_mapping AS cm
        ON foi.product_category_english = cm.product_category_english
    GROUP BY
        foi.order_id,
        cm.business_segment
),
order_segment_review AS (
    SELECT
        osb.order_id,
        osb.business_segment,
        osb.delivery_days,
        osb.late_delivery_flag,
        osb.segment_order_items,
        osb.segment_order_gmv,
        rs.avg_review_score
    FROM order_segment_base AS osb
    LEFT JOIN review_summary AS rs
        ON osb.order_id = rs.order_id
    WHERE osb.order_status = 'delivered'
),
segment_metrics AS (
    SELECT
        business_segment,
        COUNT(*) AS delivered_orders_containing_segment,
        COUNT(*) FILTER (WHERE avg_review_score IS NOT NULL) AS reviewed_orders,
        ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
        ROUND(
            100.0 * AVG(CASE WHEN late_delivery_flag = 1 THEN 1.0 ELSE 0.0 END)::numeric,
            2
        ) AS late_delivery_rate_pct,
        ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
        ROUND(SUM(segment_order_gmv)::numeric, 2) AS segment_gmv
    FROM order_segment_review
    GROUP BY
        business_segment
)
SELECT
    business_segment,
    delivered_orders_containing_segment,
    reviewed_orders,
    avg_review_score,
    late_delivery_rate_pct,
    avg_delivery_days,
    segment_gmv
FROM segment_metrics
ORDER BY
    avg_review_score ASC;
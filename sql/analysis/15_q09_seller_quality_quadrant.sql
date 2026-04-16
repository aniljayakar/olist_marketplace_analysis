/*
Q-09 Seller quality quadrant

Business question:
Which sellers are high-volume but underperforming on customer experience?

Important grain note:
Do not average reviews directly from fact_order_items_clean at item grain.
First collapse to one row per seller_id + order_id, then join review_summary.
*/

WITH seller_order_base AS (
    SELECT
        foi.seller_id,
        foi.order_id,
        MAX(foi.order_status) AS order_status,
        MAX(foi.seller_state) AS seller_state,
        COUNT(*) AS seller_order_items,
        SUM(foi.item_gmv) AS seller_order_gmv
    FROM fact_order_items_clean AS foi
    GROUP BY
        foi.seller_id,
        foi.order_id
),
seller_order_review AS (
    SELECT
        sob.seller_id,
        sob.order_id,
        sob.seller_state,
        sob.seller_order_items,
        sob.seller_order_gmv,
        rs.avg_review_score
    FROM seller_order_base AS sob
    LEFT JOIN review_summary AS rs
        ON sob.order_id = rs.order_id
    WHERE sob.order_status = 'delivered'
),
seller_metrics AS (
    SELECT
        seller_id,
        MAX(seller_state) AS seller_state,
        COUNT(*) AS delivered_orders,
        COUNT(*) FILTER (WHERE avg_review_score IS NOT NULL) AS reviewed_orders,
        SUM(seller_order_items) AS delivered_items,
        SUM(seller_order_gmv) AS seller_gmv,
        AVG(avg_review_score) AS avg_review_score
    FROM seller_order_review
    GROUP BY
        seller_id
),
benchmarks AS (
    SELECT
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY delivered_orders) AS volume_threshold,
        AVG(avg_review_score) AS review_threshold
    FROM seller_metrics
    WHERE reviewed_orders >= 20
),
seller_quadrants AS (
    SELECT
        sm.seller_id,
        sm.seller_state,
        sm.delivered_orders,
        sm.reviewed_orders,
        sm.delivered_items,
        sm.seller_gmv,
        sm.avg_review_score,
        CASE
            WHEN sm.delivered_orders >= b.volume_threshold
                 AND sm.avg_review_score >= b.review_threshold
                THEN 'High volume / High rating'
            WHEN sm.delivered_orders >= b.volume_threshold
                 AND sm.avg_review_score < b.review_threshold
                THEN 'High volume / Low rating'
            WHEN sm.delivered_orders < b.volume_threshold
                 AND sm.avg_review_score >= b.review_threshold
                THEN 'Low volume / High rating'
            ELSE 'Low volume / Low rating'
        END AS seller_quadrant
    FROM seller_metrics AS sm
    CROSS JOIN benchmarks AS b
    WHERE sm.reviewed_orders >= 20
)
SELECT
    seller_quadrant,
    COUNT(*) AS seller_count,
    ROUND(SUM(seller_gmv)::numeric, 2) AS total_gmv,
    ROUND(100.0 * SUM(seller_gmv) / SUM(SUM(seller_gmv)) OVER (), 2) AS gmv_share_pct,
    ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
    ROUND(AVG(delivered_orders)::numeric, 2) AS avg_delivered_orders
FROM seller_quadrants
GROUP BY
    seller_quadrant
ORDER BY
    total_gmv DESC;


/* After filtering to sellers with at least 20 reviewed delivered orders, 800 sellers remained for stable 
quadrant analysis. Of these, 201 qualified as high-volume sellers based on the 75th percentile volume threshold, 
and 98 of those 201 fell into the High volume / Low rating quadrant. That is 48.8% of the high-volume seller group.
More importantly, those 98 sellers account for 30.36% of GMV in the quadrant dataset, which makes them commercially 
important underperformers rather than just noisy edge cases. This is exactly the kind of intervention group your charter
was aiming to surface. */
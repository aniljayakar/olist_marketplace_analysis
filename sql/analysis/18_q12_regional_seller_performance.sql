-- Q-12 Regional seller performance
-- Purpose:
-- Measure seller quality and logistics performance at region level
-- using brazil_state_reference, so the analysis aligns with the
-- charter's regional-enrichment intent.
--
-- Grain:
-- One row per region
--
-- Logic notes:
-- 1. Collapse raw item rows to seller_id + order_id first
--    to avoid item-level fan-out when joining reviews.
-- 2. Join to review_summary at order grain.
-- 3. Join seller_state to brazil_state_reference to roll up to region.
-- 4. Filter to delivered orders only because delivery and review
--    performance should be evaluated on fulfilled orders.
-- 5. Apply regional stability filters so tiny regions do not dominate
--    the interpretation.

WITH seller_order_base AS (
    SELECT
        foi.seller_id,
        foi.order_id,
        MAX(foi.seller_state) AS seller_state,
        MAX(foi.order_status) AS order_status,
        MAX(foi.delivery_days) AS delivery_days,
        MAX(foi.late_delivery_flag) AS late_delivery_flag,
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
        sob.delivery_days,
        sob.late_delivery_flag,
        sob.seller_order_gmv,
        rs.avg_review_score
    FROM seller_order_base AS sob
    LEFT JOIN review_summary AS rs
        ON sob.order_id = rs.order_id
    WHERE sob.order_status = 'delivered'
),
region_metrics AS (
    SELECT
        bsr.region,
        COUNT(*) AS delivered_orders,
        COUNT(*) FILTER (WHERE sor.avg_review_score IS NOT NULL) AS reviewed_orders,
        COUNT(DISTINCT sor.seller_id) AS active_sellers,
        ROUND(AVG(sor.avg_review_score)::numeric, 2) AS avg_review_score,
        ROUND(
            100.0 * AVG(CASE WHEN sor.late_delivery_flag = 1 THEN 1.0 ELSE 0.0 END)::numeric,
            2
        ) AS late_delivery_rate_pct,
        ROUND(AVG(sor.delivery_days)::numeric, 2) AS avg_delivery_days,
        ROUND(SUM(sor.seller_order_gmv)::numeric, 2) AS seller_gmv
    FROM seller_order_review AS sor
    LEFT JOIN brazil_state_reference AS bsr
        ON sor.seller_state = bsr.state_code
    GROUP BY
        bsr.region
),
filtered_regions AS (
    SELECT
        region,
        active_sellers,
        delivered_orders,
        reviewed_orders,
        avg_review_score,
        late_delivery_rate_pct,
        avg_delivery_days,
        seller_gmv
    FROM region_metrics
    WHERE delivered_orders >= 100
      AND active_sellers >= 10
)
SELECT
    region,
    active_sellers,
    delivered_orders,
    reviewed_orders,
    avg_review_score,
    late_delivery_rate_pct,
    avg_delivery_days,
    seller_gmv
FROM filtered_regions
ORDER BY
    avg_review_score ASC,
    delivered_orders DESC;

-- Q-12 Support: Seller-state drilldown
-- Purpose:
-- Drill from regional seller performance down to seller_state
-- so weaker or stronger regions can be explained by the states
-- driving the pattern.
--
-- Grain:
-- One row per seller_state
--
-- Logic notes:
-- 1. Collapse raw item rows to seller_id + order_id first
--    to avoid item-level fan-out when joining reviews.
-- 2. Join to review_summary at order grain.
-- 3. Keep delivered orders only because delivery and review
--    performance should be evaluated on fulfilled orders.
-- 4. Apply stability filters so tiny seller states do not
--    dominate the interpretation.

WITH seller_order_base AS (
    SELECT
        foi.seller_id,
        foi.order_id,
        MAX(foi.seller_state) AS seller_state,
        MAX(foi.order_status) AS order_status,
        MAX(foi.delivery_days) AS delivery_days,
        MAX(foi.late_delivery_flag) AS late_delivery_flag,
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
        sob.delivery_days,
        sob.late_delivery_flag,
        sob.seller_order_gmv,
        rs.avg_review_score
    FROM seller_order_base AS sob
    LEFT JOIN review_summary AS rs
        ON sob.order_id = rs.order_id
    WHERE sob.order_status = 'delivered'
),
state_metrics AS (
    SELECT
        seller_state,
        COUNT(*) AS delivered_orders,
        COUNT(*) FILTER (WHERE avg_review_score IS NOT NULL) AS reviewed_orders,
        COUNT(DISTINCT seller_id) AS active_sellers,
        ROUND(AVG(avg_review_score)::numeric, 2) AS avg_review_score,
        ROUND(
            100.0 * AVG(CASE WHEN late_delivery_flag = 1 THEN 1.0 ELSE 0.0 END)::numeric,
            2
        ) AS late_delivery_rate_pct,
        ROUND(AVG(delivery_days)::numeric, 2) AS avg_delivery_days,
        ROUND(SUM(seller_order_gmv)::numeric, 2) AS seller_gmv
    FROM seller_order_review
    GROUP BY
        seller_state
),
filtered_states AS (
    SELECT
        seller_state,
        active_sellers,
        delivered_orders,
        reviewed_orders,
        avg_review_score,
        late_delivery_rate_pct,
        avg_delivery_days,
        seller_gmv
    FROM state_metrics
    WHERE delivered_orders >= 100
      AND active_sellers >= 10
)
SELECT
    seller_state,
    active_sellers,
    delivered_orders,
    reviewed_orders,
    avg_review_score,
    late_delivery_rate_pct,
    avg_delivery_days,
    seller_gmv
FROM filtered_states
ORDER BY
    avg_review_score ASC,
    delivered_orders DESC;
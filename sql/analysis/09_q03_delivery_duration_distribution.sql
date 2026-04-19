-- 09_q03_delivery_duration_distribution.sql
/*
Purpose:
 Summarise the national distribution of delivery_days across delivered orders
 and prepare the groundwork for outlier analysis.

Grain:
 One national summary row.

Primary inputs:
 fact_orders_clean

Business definitions:
 delivered_orders = total number of delivered orders with non-null delivery_days
 avg_delivery_days = average delivery duration in days
 median_delivery_days = 50th percentile of delivery_days
 p25_delivery_days = 25th percentile of delivery_days
 p75_delivery_days = 75th percentile of delivery_days
 p90_delivery_days = 90th percentile of delivery_days
 p95_delivery_days = 95th percentile of delivery_days

Key assumptions / caveats:
 Analysis is restricted to delivered orders only.
 delivery_days is measured at order grain.
 National distribution is summarised before any regional or category breakout.
*/

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    MIN(delivery_days) AS min_delivery_days,
    MAX(delivery_days) AS max_delivery_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY delivery_days) AS p25_delivery_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY delivery_days) AS median_delivery_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY delivery_days) AS p75_delivery_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY delivery_days) AS p90_delivery_days,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY delivery_days) AS p95_delivery_days
FROM fact_orders_clean
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL;


  -- Q-03 outlier summary: national outlier count based on IQR-derived threshold
WITH delivered_orders AS (
    SELECT
        order_id,
        customer_state,
        delivery_days
    FROM fact_orders_clean
    WHERE order_status = 'delivered'
      AND delivery_days IS NOT NULL
),
outlier_flagged AS (
    SELECT
        order_id,
        customer_state,
        delivery_days,
        CASE
            WHEN delivery_days >= 30 THEN 1
            ELSE 0
        END AS delivery_outlier_flag
    FROM delivered_orders
)
SELECT
    COUNT(*) AS delivered_orders,
    SUM(delivery_outlier_flag) AS outlier_orders,
    ROUND(SUM(delivery_outlier_flag)::numeric / COUNT(*), 4) AS outlier_rate
FROM outlier_flagged;


-- Q-03 outlier concentration by state
WITH delivered_orders AS (
    SELECT
        order_id,
        customer_state,
        delivery_days
    FROM fact_orders_clean
    WHERE order_status = 'delivered'
      AND delivery_days IS NOT NULL
),
outlier_flagged AS (
    SELECT
        order_id,
        customer_state,
        delivery_days,
        CASE
            WHEN delivery_days >= 30 THEN 1
            ELSE 0
        END AS delivery_outlier_flag
    FROM delivered_orders
)
SELECT
    customer_state,
    COUNT(*) AS delivered_orders,
    SUM(delivery_outlier_flag) AS outlier_orders,
    ROUND(SUM(delivery_outlier_flag)::numeric / COUNT(*), 4) AS outlier_rate,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days
FROM outlier_flagged
GROUP BY
    customer_state
ORDER BY
    outlier_rate DESC,
    delivered_orders DESC;

--Adding a minimum-volume filter for state outlier concentration

WITH delivered_orders AS (
    SELECT
        order_id,
        customer_state,
        delivery_days
    FROM fact_orders_clean
    WHERE order_status = 'delivered'
      AND delivery_days IS NOT NULL
),
outlier_flagged AS (
    SELECT
        order_id,
        customer_state,
        delivery_days,
        CASE
            WHEN delivery_days >= 30 THEN 1
            ELSE 0
        END AS delivery_outlier_flag
    FROM delivered_orders
),
state_outlier_metrics AS (
    SELECT
        customer_state,
        COUNT(*) AS delivered_orders,
        SUM(delivery_outlier_flag) AS outlier_orders,
        ROUND(SUM(delivery_outlier_flag)::numeric / COUNT(*), 4) AS outlier_rate,
        ROUND(AVG(delivery_days), 2) AS avg_delivery_days
    FROM outlier_flagged
    GROUP BY
        customer_state
)
SELECT
    customer_state,
    delivered_orders,
    outlier_orders,
    outlier_rate,
    avg_delivery_days
FROM state_outlier_metrics
WHERE delivered_orders >= 100
ORDER BY
    outlier_rate DESC,
    delivered_orders DESC;


-- 11_q05_monthly_gmv_trend.sql
/*
Purpose:
 Analyse monthly GMV trend across the dataset period to understand growth
 trajectory and identify seasonal peaks.

Grain:
 One row per purchase_month.

Primary inputs:
 fact_orders_clean

Business definitions:
 monthly_gmv = total GMV for all included orders in the month
 total_orders = total included orders in the month
 avg_order_value = average order GMV in the month

Key assumptions / caveats:
 GMV is used as transaction value, not audited revenue or margin.
 Cancelled and unavailable orders are excluded.
 Rows with null order_gmv are excluded from the trend.
 The final trailing month appears incomplete and is excluded from the
 main trend view to avoid misleading interpretation.
*/

SELECT
    purchase_month,
    ROUND(SUM(order_gmv), 2) AS monthly_gmv,
    COUNT(*) AS total_orders,
    ROUND(AVG(order_gmv), 2) AS avg_order_value
FROM fact_orders_clean
WHERE order_status NOT IN ('canceled', 'unavailable')
  AND order_gmv IS NOT NULL
  AND purchase_month < '2018-09-01'
GROUP BY
    purchase_month
ORDER BY
    purchase_month;

-- 11_q05_monthly_gmv_trend.sql
-- Follow-up cut: month-over-month GMV growth

WITH monthly_gmv AS (
    SELECT
        purchase_month,
        ROUND(SUM(order_gmv), 2) AS monthly_gmv
    FROM fact_orders_clean
    WHERE order_status NOT IN ('canceled', 'unavailable')
      AND order_gmv IS NOT NULL
      AND purchase_month < '2018-09-01'
    GROUP BY
        purchase_month
),
monthly_gmv_with_lag AS (
    SELECT
        purchase_month,
        monthly_gmv,
        LAG(monthly_gmv) OVER (
            ORDER BY purchase_month
        ) AS previous_month_gmv
    FROM monthly_gmv
)
SELECT
    purchase_month,
    monthly_gmv,
    previous_month_gmv,
    ROUND(monthly_gmv - previous_month_gmv, 2) AS gmv_change,
    ROUND(
        ((monthly_gmv - previous_month_gmv) / previous_month_gmv) * 100,
        2
    ) AS mom_gmv_growth_pct
FROM monthly_gmv_with_lag
ORDER BY
    purchase_month;

-- 10_q04_order_timing_patterns.sql
/*
Purpose:
 Analyse order placement timing patterns by day of week and hour of day
 to identify when marketplace demand peaks.

Grain:
 One row per purchase_day_of_week and purchase_hour combination.

Primary inputs:
 fact_orders_clean

Business definitions:
 orders_placed = number of orders placed in the given day-hour combination
 purchase_day_of_week = day name derived from order_purchase_timestamp
 purchase_hour = hour of day derived from order_purchase_timestamp

Key assumptions / caveats:
 This analysis focuses on order placement timing, not delivery outcomes.
 All orders are included because cancelled or undelivered orders still reflect
 demand timing at the moment of purchase.
 Numeric weekday is retained for correct chronological sorting.
*/

WITH order_timing AS (
    SELECT
        order_id,
        EXTRACT(DOW FROM order_purchase_timestamp) AS purchase_dow_num,
        TRIM(TO_CHAR(order_purchase_timestamp, 'Day')) AS purchase_day_of_week,
        EXTRACT(HOUR FROM order_purchase_timestamp) AS purchase_hour
    FROM fact_orders_clean
)
SELECT
    purchase_dow_num,
    purchase_day_of_week,
    purchase_hour,
    COUNT(*) AS orders_placed
FROM order_timing
GROUP BY
    purchase_dow_num,
    purchase_day_of_week,
    purchase_hour
ORDER BY
    purchase_dow_num,
    purchase_hour;
SELECT
    EXTRACT(HOUR FROM order_purchase_timestamp) AS purchase_hour,
    COUNT(*) AS orders_placed
FROM fact_orders_clean
GROUP BY
    purchase_hour
ORDER BY
    orders_placed DESC;

--Busiest days overall
SELECT
    EXTRACT(DOW FROM order_purchase_timestamp) AS purchase_dow_num,
    TRIM(TO_CHAR(order_purchase_timestamp, 'Day')) AS purchase_day_of_week,
    COUNT(*) AS orders_placed
FROM fact_orders_clean
GROUP BY
    purchase_dow_num,
    purchase_day_of_week
ORDER BY
    orders_placed DESC;

SELECT
    EXTRACT(DOW FROM order_purchase_timestamp) AS purchase_dow_num,
    TRIM(TO_CHAR(order_purchase_timestamp, 'Day')) AS purchase_day_of_week,
    COUNT(*) AS orders_placed
FROM fact_orders_clean
GROUP BY
    purchase_dow_num,
    purchase_day_of_week
ORDER BY
    purchase_dow_num;

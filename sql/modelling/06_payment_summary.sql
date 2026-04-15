-- 06_payment_summary.sql
/*
Purpose:
 Create an order-level payment summary table so payment method analysis
 can be joined safely to fact_orders_clean without causing fan-out.

Grain:
 One row per order_id.

Primary inputs:
 order_payments

Business definitions:
 primary_payment_type = payment_type associated with the largest payment_value for the order
 primary_payment_value = largest payment_value observed for the order
 payment_record_count = number of payment rows recorded for the order

Key assumptions / caveats:
 order_payments may contain multiple payment rows per order_id.
 The primary payment method is defined as the payment_type with the largest
 payment_value for the order.
 This is a practical classification rule for order-level analysis and may
 simplify mixed-payment orders.
*/

DROP TABLE IF EXISTS payment_summary;

WITH ranked_payments AS (
    SELECT
        order_id,
        payment_type,
        payment_value,
        COUNT(*) OVER (
            PARTITION BY order_id
        ) AS payment_record_count,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY payment_value DESC, payment_type
        ) AS payment_rank
    FROM order_payments
)
SELECT
    order_id,
    payment_type AS primary_payment_type,
    payment_value AS primary_payment_value,
    payment_record_count
INTO payment_summary
FROM ranked_payments
WHERE payment_rank = 1;

-- Check 1: row count in payment_summary
SELECT COUNT(*) AS payment_summary_rows
FROM payment_summary;

-- Check 2: confirm uniqueness of order_id
SELECT
    order_id,
    COUNT(*) AS row_count
FROM payment_summary
GROUP BY
    order_id
HAVING COUNT(*) > 1;

-- Check 3: inspect orders with multiple payment rows
SELECT
    order_id,
    COUNT(*) AS payment_rows,
    SUM(payment_value) AS total_payment_value
FROM order_payments
GROUP BY
    order_id
HAVING COUNT(*) > 1
ORDER BY
    payment_rows DESC, order_id
LIMIT 10;
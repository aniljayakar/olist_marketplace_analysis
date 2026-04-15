-- 13_q07_payment_mix_and_boleto_abandonment.sql
/*
Purpose:
 Analyse payment method mix and cancellation rate by primary payment type.

Grain:
 One row per primary_payment_type.

Primary inputs:
 fact_orders_clean
 payment_summary

Business definitions:
 total_orders = total number of orders using the payment type
 canceled_orders = total orders with order_status = 'canceled'
 cancellation_rate = canceled_orders / total_orders
 order_share = total_orders / all orders in the analysis

Key assumptions / caveats:
 payment_summary is joined at order grain on order_id to avoid fan-out.
 primary_payment_type is defined using the largest payment_value per order.
 Cancellation is used here as a proxy for abandonment risk at the order level.
*/

WITH payment_type_metrics AS (
    SELECT
        ps.primary_payment_type,
        COUNT(*) AS total_orders,
        SUM(
            CASE
                WHEN fo.order_status = 'canceled' THEN 1
                ELSE 0
            END
        ) AS canceled_orders
    FROM fact_orders_clean fo
    LEFT JOIN payment_summary ps
        ON fo.order_id = ps.order_id
    GROUP BY
        ps.primary_payment_type
),
payment_type_with_share AS (
    SELECT
        primary_payment_type,
        total_orders,
        canceled_orders,
        ROUND(canceled_orders::numeric / total_orders, 4) AS cancellation_rate,
        ROUND(total_orders::numeric / SUM(total_orders) OVER (), 4) AS order_share
    FROM payment_type_metrics
)
SELECT
    primary_payment_type,
    total_orders,
    order_share,
    canceled_orders,
    cancellation_rate
FROM payment_type_with_share
ORDER BY
    total_orders DESC;


SELECT
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN fo.order_status = 'canceled' THEN 1
            ELSE 0
        END
    ) AS canceled_orders,
    ROUND(
        SUM(CASE WHEN fo.order_status = 'canceled' THEN 1 ELSE 0 END)::numeric / COUNT(*),
        4
    ) AS cancellation_rate
FROM fact_orders_clean fo
LEFT JOIN payment_summary ps
    ON fo.order_id = ps.order_id
WHERE ps.primary_payment_type = 'boleto';

/* Payment mix is dominated by credit cards, which account for 75.4% of orders, followed by Boleto at 19.9%. 
Voucher and debit card usage are much smaller at 3.17% and 1.54% respectively.

At the order level, Boleto does not show a higher cancellation rate than credit card in this dataset. 
Credit card orders show a 0.58% cancellation rate, compared with 0.48% for Boleto. Voucher orders show 
the highest cancellation rate at 2.79%, but their share of total orders is relatively small. This suggests 
that payment-method risk is more nuanced than the initial hypothesis and that Boleto, while important in volume terms,
 is not the clearest source of cancellation risk under the current classification logic. */

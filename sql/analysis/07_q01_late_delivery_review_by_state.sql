



-- 07_q01_late_delivery_review_by_state.sql

-- Q-01 Base analysis: late delivery rate and average review score by state

/*
Purpose:
 Analyse late delivery performance by customer state and compare it with
 average customer review score.

Grain:
 One row per customer_state.

Primary inputs:
 fact_orders_clean
 review_summary

Business definitions:
 delivered_orders = total number of delivered orders in the state
 late_delivered_orders = delivered orders with late_delivery_flag = 1
 late_delivery_rate = late_delivered_orders / delivered_orders
 avg_review_score = average order-level review score for delivered orders in the state

Key assumptions / caveats:
 Late delivery rate is calculated only on delivered orders.
 review_summary is joined at order grain on order_id to avoid fan-out.
 A LEFT JOIN is used so operational delivery metrics are not biased by
 missing review rows.
 AVG(avg_review_score) assumes each order contributes equally to the
 state-level review average.
*/

WITH state_metrics AS (
    SELECT
        fo.customer_state,
        COUNT(*) AS delivered_orders,
        SUM(fo.late_delivery_flag) AS late_delivered_orders,
        ROUND(SUM(fo.late_delivery_flag)::numeric / COUNT(*), 4) AS late_delivery_rate,
        ROUND(AVG(rs.avg_review_score), 2) AS avg_review_score
    FROM fact_orders_clean fo
    LEFT JOIN review_summary rs
        ON fo.order_id = rs.order_id
    WHERE fo.order_status = 'delivered'
    GROUP BY
        fo.customer_state
)
SELECT
    customer_state,
    delivered_orders,
    late_delivered_orders,
    late_delivery_rate,
    avg_review_score
FROM state_metrics
ORDER BY
    late_delivery_rate DESC,
    delivered_orders DESC;

-- Validation checks
-- Check 1: Manually check late delivery rate for one state
SELECT
    COUNT(*) AS delivered_orders,
    SUM(late_delivery_flag) AS late_delivered_orders,
    ROUND(SUM(late_delivery_flag)::numeric / COUNT(*), 4) AS late_delivery_rate
FROM fact_orders_clean
WHERE order_status = 'delivered'
  AND customer_state = 'SP';

-- Check 2: Manually check avg_review_score for one state
SELECT
    ROUND(AVG(rs.avg_review_score), 2) AS avg_review_score
FROM fact_orders_clean fo
LEFT JOIN review_summary rs
    ON fo.order_id = rs.order_id
WHERE fo.order_status = 'delivered'
  AND fo.customer_state = 'SP';

-- Check 3: Confirm grouped output for the same state
WITH state_metrics AS (
    SELECT
        fo.customer_state,
        COUNT(*) AS delivered_orders,
        SUM(fo.late_delivery_flag) AS late_delivered_orders,
        ROUND(SUM(fo.late_delivery_flag)::numeric / COUNT(*), 4) AS late_delivery_rate,
        ROUND(AVG(rs.avg_review_score), 2) AS avg_review_score
    FROM fact_orders_clean fo
    LEFT JOIN review_summary rs
        ON fo.order_id = rs.order_id
    WHERE fo.order_status = 'delivered'
    GROUP BY
        fo.customer_state
)
SELECT
    *
FROM state_metrics
WHERE customer_state = 'SP';

-- Q-01 Business recommendation cut:
-- top 3 states above national late delivery benchmark
/*
Purpose:
 Identify the top 3 customer states where late delivery performance is worse
 than the national benchmark, and compare that with average review score.

Grain:
 One row per customer_state.

Primary inputs:
 fact_orders_clean
 review_summary

Business definitions:
 delivered_orders = total number of delivered orders in the state
 late_delivered_orders = delivered orders with late_delivery_flag = 1
 late_delivery_rate = late_delivered_orders / delivered_orders
 national_late_delivery_rate = late delivery rate across all delivered orders nationally
 late_rate_vs_national = state late_delivery_rate - national_late_delivery_rate
 avg_review_score = average order-level review score for delivered orders in the state

Key assumptions / caveats:
 Late delivery rate is calculated only on delivered orders.
 review_summary is joined at order grain on order_id to avoid fan-out.
 A LEFT JOIN is used so operational delivery metrics are not biased by
 missing review rows.
 AVG(avg_review_score) assumes each order contributes equally to the
 state-level review average.
*/

WITH state_metrics AS (
    SELECT
        fo.customer_state,
        COUNT(*) AS delivered_orders,
        SUM(fo.late_delivery_flag) AS late_delivered_orders,
        ROUND(SUM(fo.late_delivery_flag)::numeric / COUNT(*), 4) AS late_delivery_rate,
        ROUND(AVG(rs.avg_review_score), 2) AS avg_review_score
    FROM fact_orders_clean fo
    LEFT JOIN review_summary rs
        ON fo.order_id = rs.order_id
    WHERE fo.order_status = 'delivered'
    GROUP BY
        fo.customer_state
),
national_benchmark AS (
    SELECT
        ROUND(SUM(late_delivery_flag)::numeric / COUNT(*), 4) AS national_late_delivery_rate
    FROM fact_orders_clean
    WHERE order_status = 'delivered'
),
ranked_states AS (
    SELECT
        sm.customer_state,
        sm.delivered_orders,
        sm.late_delivered_orders,
        sm.late_delivery_rate,
        sm.avg_review_score,
        nb.national_late_delivery_rate,

        -- Compare each state to the national baseline.
        ROUND(sm.late_delivery_rate - nb.national_late_delivery_rate, 4) AS late_rate_vs_national,

        -- Rank states from worst to best based on late delivery rate.
        RANK() OVER (
            ORDER BY sm.late_delivery_rate DESC
        ) AS late_delivery_rank
    FROM state_metrics sm
    CROSS JOIN national_benchmark nb
)

SELECT
    customer_state,
    delivered_orders,
    late_delivered_orders,
    late_delivery_rate,
    national_late_delivery_rate,
    late_rate_vs_national,
    avg_review_score,
    late_delivery_rank
FROM ranked_states
WHERE late_delivery_rate > national_late_delivery_rate
ORDER BY
    late_delivery_rate DESC,
    delivered_orders DESC
LIMIT 3;

/* Delivery performance varied sharply by state. The national late-delivery rate was 8.11%, but 
AL, MA, and PI were all materially above that benchmark at 23.93%, 19.67%, and 15.97% respectively. 
These states also posted weaker average review scores than stronger-performing states such as SP and PR, 
suggesting a meaningful association between logistics reliability and customer experience.

AL stands out as the clearest operational risk. It combined the highest late-delivery rate 
in the dataset with a below-4.0 average review score across 397 delivered orders, which makes 
it more than a small-sample outlier. The result points to regional delivery performance as a 
likely pressure point worth further investigation. */


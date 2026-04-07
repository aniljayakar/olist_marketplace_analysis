/*
Purpose:
 Create an order-level review summary table from the raw order_reviews table.
 This summary is built so review metrics can be joined safely to fact_orders_clean
 without creating fan-out or inflating downstream aggregates.

Grain:
 One row per order_id.

Primary inputs:
 order_reviews

Business definitions:
 avg_review_score = average review_score across all review rows for the same order_id
 review_count = number of review rows recorded for the same order_id

Key assumptions / caveats:
- order_reviews may contain more than one row per order_id, so the table is aggregated
 before being joined to order-level fact tables.
- AVG(review_score) is used to collapse potentially multiple review rows into one 
 order-level metric without arbitrarily discarding any row.
- review_count is retained to make the summary auditable and to highlight orders with
 multiple review rows.
-This table is intended for order-level analysis and should be joined on order_id.
*/

DROP TABLE IF EXISTS review_summary;

CREATE TABLE review_summary AS
SELECT
      order_id,
      ROUND(AVG(review_score), 2) AS avg_review_score,
      COUNT(*) AS review_count
FROM order_reviews
GROUP BY  
    order_id;

-- Validation 1:
-- Total rows in review_summary
SELECT COUNT(*) AS review_summary_rows
FROM review_summary;

SELECT
    COUNT(DISTINCT order_id) AS distinct_review_orders
FROM order_reviews;


-- Validation 2:
-- Check for nulls in key output columns.

SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE avg_review_score IS NULL) AS null_avg_review_score
FROM review_summary;


-- Validation 3:
-- Confirm review_summary is truly at order grain by checking for duplicate order_id values.

SELECT
    order_id,
    COUNT(*) AS row_count
FROM review_summary
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Validation 4:
-- Inspect orders with multiple raw review rows
-- and compare them to the summary output
SELECT
    order_id,
    COUNT(*) AS raw_review_rows,
    ROUND(AVG(review_score), 2) AS expected_avg_review_score
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY raw_review_rows DESC, order_id
LIMIT 10;


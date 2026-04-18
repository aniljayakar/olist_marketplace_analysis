-- 03_reference_table_validation.sql
/*
Purpose:
Validate reference table completeness before using enrichment tables in analysis.

Checks:
1. category_mapping row count.
2. No duplicate category keys.
3. No null business segments.
4. Every commercial fact-table category maps to a business segment.
5. Segment-level GMV equals direct fact-table GMV.
6. brazil_state_reference has all expected state rows.
7. Customer and seller states map correctly to brazil_state_reference.

Data quality note:
The Olist category labels include spelling inconsistencies such as
'costruction_tools_garden' and 'costruction_tools_tools'.
The mapping table preserves raw category keys exactly as they appear in
fact_order_items_clean to maintain join integrity.
*/

-- 1. Category mapping row count
SELECT
    COUNT(*) AS mapping_rows
FROM category_mapping;

-- 2. Duplicate category mapping keys
SELECT
    product_category_english,
    COUNT(*) AS row_count
FROM category_mapping
GROUP BY
    product_category_english
HAVING COUNT(*) > 1
ORDER BY
    row_count DESC,
    product_category_english;

-- 3. Null business segments
SELECT
    COUNT(*) AS null_business_segments
FROM category_mapping
WHERE business_segment IS NULL;

-- 4. Commercial fact-table categories that fail to map
SELECT
    foi.product_category_english,
    COUNT(*) AS order_items,
    COUNT(DISTINCT foi.order_id) AS orders_containing_category,
    ROUND(SUM(foi.item_gmv)::numeric, 2) AS category_gmv
FROM fact_order_items_clean AS foi
LEFT JOIN category_mapping AS cm
    ON foi.product_category_english = cm.product_category_english
WHERE foi.order_status NOT IN ('canceled', 'unavailable')
  AND foi.item_gmv IS NOT NULL
  AND cm.product_category_english IS NULL
GROUP BY
    foi.product_category_english
ORDER BY
    category_gmv DESC;

-- 5. Segment GMV total vs direct fact-table GMV total
WITH segment_total AS (
    SELECT
        ROUND(SUM(foi.item_gmv)::numeric, 2) AS segment_rollup_gmv
    FROM fact_order_items_clean AS foi
    LEFT JOIN category_mapping AS cm
        ON foi.product_category_english = cm.product_category_english
    WHERE foi.order_status NOT IN ('canceled', 'unavailable')
      AND foi.item_gmv IS NOT NULL
      AND cm.business_segment IS NOT NULL
),
fact_total AS (
    SELECT
        ROUND(SUM(item_gmv)::numeric, 2) AS direct_fact_gmv
    FROM fact_order_items_clean
    WHERE order_status NOT IN ('canceled', 'unavailable')
      AND item_gmv IS NOT NULL
)
SELECT
    st.segment_rollup_gmv,
    ft.direct_fact_gmv,
    ROUND((st.segment_rollup_gmv - ft.direct_fact_gmv)::numeric, 2) AS gmv_difference
FROM segment_total AS st
CROSS JOIN fact_total AS ft;

-- 6. Final business segment list
SELECT
    business_segment,
    COUNT(*) AS category_count
FROM category_mapping
GROUP BY
    business_segment
ORDER BY
    category_count DESC;

-- 7. Brazil state reference row count
SELECT
    COUNT(*) AS state_reference_rows
FROM brazil_state_reference;

-- 8. Customer states that fail to map
SELECT DISTINCT
    foc.customer_state
FROM fact_orders_clean AS foc
LEFT JOIN brazil_state_reference AS bsr
    ON foc.customer_state = bsr.state_code
WHERE bsr.state_code IS NULL
ORDER BY
    foc.customer_state;

-- 9. Seller states that fail to map
SELECT DISTINCT
    foi.seller_state
FROM fact_order_items_clean AS foi
LEFT JOIN brazil_state_reference AS bsr
    ON foi.seller_state = bsr.state_code
WHERE bsr.state_code IS NULL
ORDER BY
    foi.seller_state;
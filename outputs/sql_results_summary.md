# SQL Results Summary

This file summarises the business findings from the SQL analysis layer of the Olist marketplace project.

## Q-01 Late delivery and review by state

Main finding:
Late delivery performance varies sharply by customer geography. Several states sit materially above the national late-delivery benchmark, and many of those states also show weaker average review scores.

Key metrics:
- National late-delivery rate: 8.11%
- Highest late-delivery states:
  - AL: 23.93% late-delivery rate, 3.85 avg review score
  - MA: 19.67% late-delivery rate, 3.83 avg review score
  - PI: 15.97% late-delivery rate, 3.99 avg review score
- Regional view:
  - Northeast: 14.33% late-delivery rate, 3.97 avg review score, 19.95 avg delivery days
  - North: 9.80% late-delivery rate, 4.03 avg review score, 22.54 avg delivery days
  - South: 7.05% late-delivery rate, 4.19 avg review score
  - Southeast: 7.45% late-delivery rate, 4.18 avg review score

Business interpretation:
Operational underperformance is geographically concentrated. At state level, AL, MA, and PI are the clearest outliers, with late-delivery rates well above the national benchmark. 
The regional support cut strengthens this pattern: the Northeast has the highest late-delivery rate and the weakest average review score, while the South and Southeast perform better on both delivery reliability and review score. This suggests that delivery reliability is associated with customer satisfaction, especially in underperforming regions.

Gotcha / caveat:
Only delivered orders are included because late-delivery rate and delivery duration are only meaningful for fulfilled orders. Review score is joined at order grain through `review_summary` to avoid duplication. The relationship between delivery delay and review score should be described as association, not causation.


## Q-02 Delivery performance by product category

Main finding:
Delivery performance varies meaningfully by product category, but the story changes depending on whether categories are ranked by rate or by absolute late-delivery burden. Smaller categories such as audio, fashion_underwear_beach, christmas_supplies, books_technical, and home_confort show the highest late-delivery rates, while larger categories create more operational burden even when their rates are lower.

Key metrics:
- Highest late-delivery rates among categories with sufficient volume:
  - audio: 12.71%
  - fashion_underwear_beach: 12.60%
  - christmas_supplies: 12.00%
  - books_technical: 11.03%
  - home_confort: 10.26%
- Highest absolute late-delivery burden:
  - bed_bath_table: 920 late delivered item rows
  - health_beauty: 857
  - furniture_decor: 688
  - sports_leisure: 625
  - computers_accessories: 594
- Segment-level support view:
  - Beauty, Health & Baby had the highest segment late-delivery rate at 8.63%
  - Electronics & Tech followed at 8.27%
  - Office, Industry & Construction had the longest average delivery duration at 14.00 days
  - Home & Living created the largest absolute burden, with 2,624 late delivered item rows

Business interpretation:
The rate view identifies categories with weaker delivery reliability, while the burden view identifies where operations would feel the largest volume impact. At segment level, delivery issues are not isolated to one narrow category. Beauty, Health & Baby and Electronics & Tech show the highest segment-level late-delivery rates, while Home & Living creates the largest absolute number of late delivered item rows because of its scale. This means intervention prioritisation should consider both rate and volume.

Gotcha / caveat:
This analysis uses `fact_order_items_clean` because product category is an item-level attribute. However, delivery fields are inherited from the parent order, so the metric should be read as the share of delivered item rows whose parent orders were delivered late, not true item-level shipping performance.


## Q-03 Delivery duration distribution and outlier analysis

Main finding:
Delivery duration is right-skewed. Most delivered orders arrive within a relatively normal window, but a small long-delay tail creates important operational outliers.

Key metrics:
- Delivered orders analysed: 96,470
- Average delivery days: 12.50
- Median delivery days: 10
- P25: 7 days
- P75: 16 days
- P90: 23 days
- P95: 29 days
- Maximum delivery duration: 210 days
- Outlier threshold used: delivery_days >= 30
- Outlier orders: 4,729
- National outlier rate: 4.90%

Highest outlier concentration among states with at least 100 delivered orders:
- AM: 35.17% outlier rate, 26.36 avg delivery days
- AL: 28.46%, 24.50 avg delivery days
- PA: 23.15%, 23.73 avg delivery days
- SE: 18.21%, 21.46 avg delivery days
- MA: 16.88%, 21.51 avg delivery days
- PB: 16.05%, 20.39 avg delivery days
- CE: 15.64%, 21.20 avg delivery days

Business interpretation:
The average delivery duration is pulled upward by a long right tail, so the median gives a better picture of a typical order. The outlier analysis shows that long-delay orders are geographically concentrated, especially in northern and northeastern states. This reinforces Q-01: some states are not only more likely to miss delivery promises, they are also overrepresented in the extreme-delay tail.

Gotcha / caveat:
Outliers are defined using a practical threshold of 30+ delivery days, based on the distribution where P95 is 29 days. Only delivered orders are included because delivery duration is not meaningful for undelivered, canceled, or unavailable orders.

## Q-04 Order timing patterns

Main finding:
Order placement is concentrated during daytime and evening hours, with very low demand overnight. Weekday demand is stronger than weekend demand, especially from Monday to Wednesday.

Key metrics:
- Busiest hour: 16:00, with 6,674 orders placed
- Other high-volume hours:
  - 11:00: 6,578 orders
  - 14:00: 6,568 orders
  - 13:00: 6,516 orders
  - 15:00: 6,455 orders
- Lowest-volume hours:
  - 05:00: 188 orders
  - 04:00: 206 orders
  - 03:00: 272 orders
  - 06:00: 502 orders
  - 02:00: 510 orders
- Busiest days:
  - Monday: 16,196 orders
  - Tuesday: 15,963 orders
  - Wednesday: 15,552 orders
- Lowest-volume day:
  - Saturday: 10,887 orders

Business interpretation:
Marketplace demand is strongest during weekday working and early evening hours rather than late-night or weekend periods. This pattern could inform campaign timing, customer support coverage, and downstream fulfilment planning. The weekday skew suggests that order placement is not evenly distributed across the week, so operational teams should expect heavier demand early in the work week.

Gotcha / caveat:
Do not filter to delivered orders for this question. Order timing reflects demand at the point of purchase, so all placed orders should be included regardless of final fulfilment status.

## Q-05 Monthly GMV trend

Main finding:
Monthly GMV grew strongly through 2017 and reached a high-GMV plateau in early to mid-2018. The main usable trend window is 2017-01 through 2018-08, because the very early and trailing months have incomplete or sparse coverage.

Key metrics:
- Main growth phase: 2017-01 to 2017-11
- January 2017 GMV: 136,943.46
- November 2017 GMV: 1,172,191.68
- December 2017 GMV: 861,526.77
- January 2018 GMV: 1,110,920.01
- March 2018 GMV: 1,152,656.99
- April 2018 GMV: 1,156,248.89
- May 2018 GMV: 1,145,686.46
- August 2018 GMV: 996,973.51
- Strongest visible growth month: 2017-11, with a 53.28% month-over-month increase
- Early sparse months such as 2016-09, 2016-10, and 2016-12 should not be over-interpreted

Business interpretation:
The marketplace shows clear commercial expansion through 2017, with GMV rising from 136.9K in January 2017 to over 1.17M by November 2017. In 2018, GMV remains high but no longer accelerates in the same way. March, April, and May 2018 all sit around the 1.15M mark, suggesting a high-GMV plateau rather than continued rapid growth. This indicates that 2017 was the main expansion period, while early 2018 reflects a more mature and stable GMV base.

Gotcha / caveat:
Month-over-month growth is calculated after aggregating GMV to month level, not on raw order rows. Early and trailing months should be treated cautiously because dataset coverage is incomplete. GMV is transaction value, not audited revenue or margin.

## Q-06 GMV concentration by business segment

Main finding:
GMV is concentrated in a small number of broad business segments. The concentration remains visible even after rolling raw product categories into higher-level business groups.

Key metrics:
- Home & Living: 4,268,515.97 GMV, 27.13% share
- Leisure, Gifts & Hobbies: 2,758,769.90 GMV, 17.53% share
- Beauty, Health & Baby: 2,368,667.50 GMV, 15.05% share
- Electronics & Tech: 2,190,832.98 GMV, 13.92% share
- Top 3 segments cumulative GMV share: 59.71%
- Top 4 segments cumulative GMV share: 73.63%
- Raw category drilldown:
  - health_beauty: 1,437,665.78 GMV, 9.14% share
  - watches_gifts: 1,298,292.47 GMV, 8.25% share
  - bed_bath_table: 1,240,386.13 GMV, 7.88% share
  - sports_leisure: 1,147,244.63 GMV, 7.29% share
  - computers_accessories: 1,050,941.58 GMV, 6.68% share

Business interpretation:
Marketplace GMV is not evenly spread across the catalogue. Home & Living is the largest business segment, and the top three segments account for nearly 60% of total GMV. The raw category drilldown shows that concentration inside these segments is also driven by a small number of high-value categories. This creates commercial dependency: performance changes in a limited set of segments and categories could have a large impact on total marketplace GMV.
This segment view depends on the analyst-defined `category_mapping` reference table, which was validated to preserve total GMV.

Gotcha / caveat:
Category analysis uses `fact_order_items_clean` because product category is an item-level attribute. Business segments are analyst-defined using `category_mapping`, so they should be treated as a portfolio grouping layer rather than an official Olist taxonomy. GMV is transaction value, not audited revenue or margin.


## Q-07 Payment method mix and Boleto cancellation

Main finding:
Credit card is the dominant payment method by order share, while Boleto is the second-largest method. However, Boleto does not show a higher cancellation rate than credit card under the current order-level primary-payment classification.

Key metrics:
- Credit card: 74,975 orders, 75.40% order share, 0.58% cancellation rate
- Boleto: 19,784 orders, 19.90% order share, 0.48% cancellation rate
- Voucher: 3,151 orders, 3.17% order share, 2.79% cancellation rate
- Debit card: 1,527 orders, 1.54% order share, 0.46% cancellation rate
- Boleto cancellation check: 95 canceled orders out of 19,784 total Boleto orders

Business interpretation:
The data does not support the initial hypothesis that Boleto has a higher cancellation rate than credit card. Credit card dominates the payment mix, while Boleto is a meaningful secondary payment method, but its cancellation rate is slightly lower than credit card in this classification. The main payment-related outlier is voucher, which has a higher cancellation rate, although its order share is much smaller.

Gotcha / caveat:
Payment analysis uses `payment_summary`, where each order is assigned a primary payment type based on the largest payment value. This avoids raw payment-table duplication, but it also means split-payment behavior is simplified into one dominant payment method per order. The dataset uses the status value `canceled`, not `cancelled`.
Very small `not_defined` and null payment-type groups exist but are not large enough to drive the payment-mix interpretation.


## Q-08 Average basket size and GMV by geography

Main finding:
The largest customer states drive GMV mainly through order volume, while several smaller states show higher average order value. Average items per order is stable across states and regions, so basket-size differences are not mainly caused by customers buying many more items per order.

Key metrics:
- Largest states by total GMV:
  - SP: 41,125 orders, 5,878,132.06 GMV, 142.93 AOV, 1.15 avg items per order
  - RJ: 12,697 orders, 2,115,667.56 GMV, 166.63 AOV, 1.14 avg items per order
  - MG: 11,496 orders, 1,843,074.43 GMV, 160.32 AOV, 1.14 avg items per order
  - RS: 5,415 orders, 877,290.59 GMV, 162.01 AOV, 1.15 avg items per order
  - PR: 4,982 orders, 794,196.61 GMV, 159.41 AOV, 1.15 avg items per order

- Highest AOV states:
  - PB: 264.64 AOV
  - AC: 242.84 AOV
  - AP: 239.16 AOV
  - AL: 234.13 AOV
  - RO: 233.43 AOV

- Regional support view:
  - Southeast: 67,336 orders, 10,159,955.08 GMV, 150.88 AOV, 1.14 avg items per order
  - South: 13,996 orders, 2,279,510.90 GMV, 162.87 AOV, 1.15 avg items per order
  - Northeast: 9,305 orders, 1,872,583.31 GMV, 201.24 AOV, 1.12 avg items per order
  - Central-West: 5,728 orders, 1,013,752.38 GMV, 176.98 AOV, 1.15 avg items per order
  - North: 1,834 orders, 409,725.36 GMV, 223.41 AOV, 1.12 avg items per order

Business interpretation:
The Southeast is the marketplace’s main demand engine because of scale, not because it has the highest order value. Smaller regions such as the North and Northeast show higher AOV, but their order volumes are much lower. Since average items per order remains close to 1.1 across states and regions, AOV differences are more likely linked to product mix, price mix, or freight than customers buying much larger baskets.

Gotcha / caveat:
This is demand-side geography based on `customer_state`, not seller geography. Canceled and unavailable orders are excluded, and GMV is transaction value rather than audited revenue or margin.


## Q-09 Seller quality quadrant

Main finding:
Seller quality risk is concentrated in commercially important sellers, not just the long tail. The high-volume, low-rating quadrant contains fewer sellers than the low-volume groups, but it accounts for a large share of GMV.

Key metrics:
- Sellers analysed after stability filter: 800
- High volume / High rating: 103 sellers, 32.30% GMV share, 4.31 avg review score
- High volume / Low rating: 98 sellers, 30.36% GMV share, 3.93 avg review score
- Low volume / High rating: 331 sellers, 20.77% GMV share, 4.41 avg review score
- Low volume / Low rating: 268 sellers, 16.58% GMV share, 3.90 avg review score
- High-volume sellers total: 201 sellers
- High-volume sellers below review benchmark: 98 sellers, around 48.8% of high-volume sellers

Business interpretation:
The most important intervention group is the High volume / Low rating quadrant. These 98 sellers represent almost half of all high-volume sellers and account for 30.36% of GMV in the quadrant dataset. This means seller quality risk is commercially material. Improving performance among this group could protect customer experience while also addressing a meaningful share of marketplace value.

Gotcha / caveat:
Seller quality is measured as a proxy using order-level reviews from orders containing each seller. For multi-seller orders, the same order review may be attributed to more than one seller. To reduce noise, the quadrant analysis only includes sellers with at least 20 reviewed delivered orders.


## Q-10 Revenue concentration by seller

Main finding:
Marketplace GMV is heavily concentrated among a relatively small seller cohort. The seller base is broad, but commercial value is not evenly distributed across sellers.

Key metrics:
- Total sellers analysed: 3,053
- Top 10% seller count: 306 sellers
- Top 10% seller GMV: 10,492,372.82
- Top 10% GMV share: 66.68%
- Top 20% seller count: 611 sellers
- Top 20% seller GMV: 12,892,697.36
- Top 20% GMV share: 81.93%
- Total marketplace GMV: 15,735,527.03
- Top seller GMV share: 1.58%
- Top 10 sellers cumulative GMV share: 12.86%
- Top 20 sellers cumulative GMV share: 20.92%
- Top 50 sellers cumulative GMV share: 32.36%

Business interpretation:
The marketplace is highly dependent on its top seller cohort. The top 10% of sellers generate about two-thirds of GMV, and the top 20% generate more than four-fifths. At the same time, no single seller dominates the marketplace, since the top seller contributes only 1.58% of total GMV. This points to cohort-level concentration risk rather than single-seller dependency.

Gotcha / caveat:
Seller concentration is calculated after aggregating item-level GMV to seller grain. Top 10% and top 20% refer to seller count, not GMV share thresholds.


## Q-11 Category review score drivers

Main finding:
Customer satisfaction varies by category, and weaker-rated categories often show worse delivery performance. The pattern is visible at raw category level and remains directionally useful when rolled up to business segments.

Key metrics:
- Low-rated categories with at least 100 reviewed orders:
  - office_furniture: 3.64 avg review score, 9.17% late-delivery rate, 20.59 avg delivery days
  - fashion_male_clothing: 3.82 avg review score
  - audio: 3.84 avg review score, 12.93% late-delivery rate
  - home_confort: 3.89 avg review score, 10.46% late-delivery rate
  - fixed_telephony: 3.97 avg review score
  - construction_tools_safety: 3.97 avg review score
  - home_construction: 3.99 avg review score

- High-rated category:
  - books_general_interest: 4.53 avg review score

- Segment-level support view:
  - Electronics & Tech: 4.08 avg review score, 8.40% late-delivery rate, 13.04 avg delivery days
  - Office, Industry & Construction: 4.09 avg review score, 8.06% late-delivery rate, 13.84 avg delivery days
  - Home & Living: 4.10 avg review score, 8.08% late-delivery rate, 12.58 avg delivery days
  - Leisure, Gifts & Hobbies: 4.24 avg review score, 7.55% late-delivery rate, 12.06 avg delivery days

Business interpretation:
The weakest review scores appear in categories where customer experience may be affected by a mix of delivery reliability, product expectations, item complexity, and damage risk. Delivery performance helps explain part of the gap, especially for office_furniture, audio, and home_confort, but it does not fully explain satisfaction differences across all categories. At segment level, weaker satisfaction clusters around Electronics & Tech, Office, Industry & Construction, and Home & Living, while Leisure, Gifts & Hobbies performs best.

Gotcha / caveat:
Reviews are order-level signals, not pure category-level ratings. To reduce item-level fan-out, the analysis first collapses to order-category grain before joining `review_summary`. If an order contains multiple categories or segments, the same order review may be attributed to each group present in the order.


## Q-12 Regional seller performance

Main finding:
Seller performance varies by region, but the strongest business signal is where performance and scale overlap. The Southeast dominates seller activity and GMV, while the South and Central-West show stronger review and delivery performance.

Key metrics:
- Southeast: 2,190 active sellers, 81,687 delivered orders, 12,112,256.61 seller GMV, 4.13 avg review score, 8.36% late-delivery rate
- Northeast: 54 active sellers, 1,535 delivered orders, 506,383.96 seller GMV, 4.17 avg review score, 10.10% late-delivery rate
- South: 644 active sellers, 13,128 delivered orders, 2,571,649.71 seller GMV, 4.19 avg review score, 5.97% late-delivery rate
- Central-West: 78 active sellers, 1,444 delivered orders, 221,356.58 seller GMV, 4.21 avg review score, 5.33% late-delivery rate

State drilldown:
- SP dominates the seller base: 1,769 active sellers, 69,401 delivered orders, 9,957,056.91 seller GMV
- SP has only mid-range quality metrics: 4.11 avg review score and 8.67% late-delivery rate
- RS and GO show stronger state-level performance, with lower late-delivery rates and higher review scores
- DF has the weakest review score in the filtered state view, but lower late-delivery rate than SP

Business interpretation:
Regional seller performance is not uniform. The South and Central-West perform best on review score and late-delivery rate, while the Northeast shows the weakest logistics performance among stable regions. The Southeast is the most important operational region because it carries the majority of seller GMV and order volume, even though its quality metrics are only mid-range. This makes Southeast, especially SP, the most commercially important region to monitor and improve.

Gotcha / caveat:
This is seller-side geography based on `seller_state`, not customer geography. The analysis collapses item rows to seller-order grain before joining reviews to reduce item-level fan-out. Regions or states with very small seller bases should be interpreted cautiously, which is why the main regional view excludes low-volume unstable groups.
Low-volume regions such as the North were excluded from the main regional comparison after applying stability filters.
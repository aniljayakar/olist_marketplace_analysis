# Olist Marketplace Risk Monitor

## Executive Summary

This project analyses Olist’s marketplace performance to identify where commercial value is most exposed across seller concentration, delivery reliability, seller quality, and product segment pressure.

The analysis found that marketplace GMV is highly concentrated among top sellers, with the top 20% of sellers generating 81.93% of GMV. A commercially important seller group, high-volume sellers with below-benchmark review scores, accounts for 30.36% of GMV in the seller-quality view. Delivery issues are also geographically concentrated, with the Northeast showing the highest late-delivery rate and weakest regional review score.

The final output is a Power BI Marketplace Risk Monitor designed to help marketplace, operations, and seller management teams prioritise seller intervention, logistics improvement, and segment-level monitoring.

## Business Problem

Olist operates as a marketplace, which means performance risk can come from multiple areas: seller concentration, weak seller quality, late delivery, and product segments with poor customer experience.

The goal of this project was to answer:

**Where is marketplace value most exposed, and what should the business prioritise?**

The analysis focuses on three business themes:

1. Seller and GMV concentration risk
2. Delivery reliability and customer experience
3. Product segment exposure and quality pressure

## Key Findings

### 1. GMV is highly concentrated among top sellers

The top 20% of sellers generate 81.93% of marketplace GMV, creating concentration risk if high-value sellers underperform.

### 2. A meaningful share of GMV sits with weaker seller quality

The high-volume / low-rating seller group contains 98 sellers and accounts for 30.36% of GMV in the seller-quality view. This group should be prioritised for account management, monitoring, or seller coaching.

### 3. Delivery reliability is geographically concentrated

The Northeast has the highest late-delivery rate at 14.33% and the weakest average review score among customer regions. This suggests that logistics intervention should prioritise regions where late delivery and weak reviews overlap.

### 4. Segment prioritisation should not be based on GMV alone

Home & Living is the largest segment by GMV, but quality pressure appears in other segments as well. Beauty, Health & Baby has the highest segment late-delivery rate, while Electronics & Tech has the weakest average review score.

## Dashboard Preview

The Power BI dashboard was designed as a marketplace risk monitor, not a generic reporting dashboard. Each page answers a specific business question.

### Executive Summary

**Question answered:** Where is marketplace value most exposed?

![Executive Summary](readme_assets/dashboard/executive_summary.png)

### Seller Risk

**Question answered:** Which seller groups create the greatest marketplace risk?

![Seller Risk](readme_assets/dashboard/seller_risk.png)

### Delivery Reliability

**Question answered:** Where is delivery reliability damaging customer experience?

![Delivery Reliability](readme_assets/dashboard/delivery_reliability.png)

### Segment Exposure

**Question answered:** Which product segments drive GMV and quality pressure?

![Segment Exposure](readme_assets/dashboard/segment_exposure.png)

## Analytical Approach

The project followed a layered analytical workflow:

1. Audited raw Olist tables for missing values, duplicates, date issues, and grain mismatches.
2. Built cleaned fact tables at order grain and order-item grain.
3. Created summary tables for reviews and payments to avoid fan-out during joins.
4. Added reference enrichment for business segment and Brazilian region analysis.
5. Answered 12 business questions using PostgreSQL.
6. Exported validated SQL outputs into Python for chart-ready CSV generation.
7. Built a Power BI dashboard focused on marketplace risk and prioritisation.

## Data Model and Grain Decisions

A key part of this project was choosing the correct table grain for each type of analysis.

- `fact_orders_clean`: order-level fact table used for delivery performance, customer region analysis, order GMV, and review joins.
- `fact_order_items_clean`: order-item-level fact table used for category, segment, seller, and item-GMV analysis.
- `review_summary`: order-level review table used to avoid review fan-out when joining reviews to item-level or order-level facts.
- `payment_summary`: order-level payment table used for payment mix and boleto abandonment analysis.
- `category_mapping`: analyst-defined enrichment table mapping raw product categories into business segments.
- `brazil_state_reference`: regional reference table used for customer and seller geography analysis.

Separating order-grain and item-grain analysis helped prevent inflated metrics and ensured that each question used the correct base table.

## Key Analytical Decisions

Several modelling and analysis decisions were made to keep the metrics reliable and business-facing:

- **Separated order grain from item grain:** Delivery performance, customer region analysis, and review joins were handled at order grain, while category, segment, and seller analysis used item grain. This prevented category and seller metrics from distorting order-level outcomes.
- **Pre-aggregated reviews before joining:** Reviews were summarised into `review_summary` at order grain before joining to fact tables. This avoided fan-out from raw review rows and kept review metrics aligned with the correct denominator.
- **Used business segments instead of only raw categories:** Raw Olist product categories were mapped into analyst-defined business segments to make the dashboard easier for stakeholders to interpret.
- **Prioritised seller risk over generic customer segmentation:** Since marketplace value and performance risk were more clearly concentrated around sellers, the dashboard focuses on seller quality, seller concentration, delivery reliability, and segment exposure rather than generic customer segmentation.
- **Used Python as a repeatable export layer:** PostgreSQL remained the analytical source of truth, while Python was used to export validated SQL outputs into reproducible CSVs and chart assets for reporting.

## Project Workflow

```text
Raw Olist CSVs
      ↓
PostgreSQL schema load and audit
      ↓
Cleaned fact and summary tables
      ↓
Business question SQL analysis
      ↓
Python export notebook
      ↓
CSV outputs and chart assets
      ↓
Power BI marketplace risk dashboard
```

The SQL layer is the analytical source of truth. Python is used to extract validated SQL outputs into reproducible CSV files. Power BI is used as the stakeholder-facing dashboard layer.

## Tools and Skills Demonstrated

- **SQL, PostgreSQL:** data cleaning, joins, aggregations, window functions, CTEs, validation checks
- **Data modelling:** order-grain and item-grain fact tables, summary tables, reference enrichment
- **Python:** SQL extraction, pandas exports, chart generation, repeatable workflow
- **Power BI:** KPI design, dashboard storytelling, business question framing, interactive visuals
- **Analytics skills:** metric definition, grain control, fan-out prevention, business prioritisation, dashboard communication

## Repository Structure

```text
olist_marketplace_analysis/
├── data/
│   └── reference/
├── sql/
│   ├── setup/
│   ├── audit/
│   ├── modelling/
│   └── analysis/
├── notebooks/
│   └── 01_sql_outputs_to_python.ipynb
├── outputs/
│   ├── python_exports/
│   └── sql_results_summary.md
├── readme_assets/
│   ├── charts/
│   └── dashboard/
├── dashboard/
│   └── powerbi/
└── README.md
```

## How to Reproduce

1. Load the raw Olist CSVs into PostgreSQL using the setup scripts.
2. Run the audit scripts to validate raw table quality.
3. Run the modelling scripts to create cleaned fact and summary tables.
4. Run the analysis scripts to reproduce the business question outputs.
5. Use the Python notebook to export chart-ready CSVs into `outputs/python_exports/`.
6. Open the Power BI file in `dashboard/powerbi/` to view the final dashboard.

Database credentials should be configured locally using `.env.example` as a template. Real credentials are not committed.

## Scope Notes

The payment mix and boleto cancellation analysis was included as a supporting business question, but the main dashboard focuses on marketplace risk across sellers, delivery, and product segments. A deeper fintech-focused version of the project could extend the boleto analysis into a payment abandonment view by state, order value band, product segment, and customer region.

Python was used as a reproducible export and chart-preparation layer. The analytical source of truth remains PostgreSQL because the core questions involved table-grain control, joins, aggregation, ranking, and validation.


## Limitations

- The dataset is historical and does not represent live marketplace performance.
- GMV is treated as transaction value, not audited revenue or profit.
- Product segment mapping is analyst-defined and should be reviewed with business stakeholders before production use.
- Review scores are analysed at order level, but customer sentiment text is not included in this version.
- Delivery analysis focuses on delivered orders because delivery duration is not meaningful for cancelled or unavailable orders.

## Next Steps

If this were extended into a production workflow, the next steps would be:

- **Build a seller-level intervention table:** The high-volume / low-rating seller group contains 98 sellers and accounts for 30.36% of GMV in the seller-quality view. The immediate next step would be a seller-level drilldown ranking sellers by GMV at risk, review score, late delivery rate, and order volume so account managers can prioritise outreach.
- **Extend payment abandonment analysis:** The boleto cancellation analysis could be expanded by state, order value band, product segment, and customer region to identify whether payment-related abandonment is concentrated in specific customer or transaction groups.
- **Investigate Northeast delivery failures:** The Northeast has the highest regional late-delivery rate and weakest average review score. A deeper analysis would compare customer region, seller region, carrier performance, and delivery distance to separate seller-side issues from logistics network constraints.
- **Measure intervention impact:** For seller coaching or logistics interventions, define pre/post measurement windows and compare treated sellers or regions against a similar control group using late delivery rate, review score, and GMV retention.
- **Add margin or cost data:** GMV identifies commercial exposure, but profitability data would help prioritise interventions based on financial impact, not transaction value alone.
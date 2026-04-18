-- 02_create_reference_tables.sql
/*
Purpose:
Create reference tables used to enrich the Olist marketplace analysis.

Reference tables:
1. category_mapping
   Maps raw product_category_english values to broader analyst-defined business segments.

2. brazil_state_reference
   Maps Brazilian state codes to state names and macro-regions.

Important:
This file only creates empty reference tables.
CSV import is done separately through pgAdmin.
Do not insert repair values here.
*/

DROP TABLE IF EXISTS category_mapping;

CREATE TABLE category_mapping (
    product_category_english TEXT PRIMARY KEY,
    business_segment TEXT NOT NULL
);

DROP TABLE IF EXISTS brazil_state_reference;

CREATE TABLE brazil_state_reference (
    state_code TEXT PRIMARY KEY,
    state_name TEXT NOT NULL,
    region TEXT NOT NULL
);
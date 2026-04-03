/*
Purpose:
  Define the raw Olist source tables used for marketplace performance and customer
  experience analysis.

Grain:
  Source table grain.

Primary inputs:
  None. This file defines the base tables loaded by the project.

Business definitions:
  Not applicable in this layer. This file establishes source-facing storage only.

Key assumptions / caveats:
  - Tables are recreated without constraints or indexes in this script.
  - Column names and data types mirror the existing source structure.
  - Load operations are assumed to occur outside this file.
*/

-- ============================================================================
-- Source Table DDL
-- ============================================================================

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state TEXT
);

DROP TABLE IF EXISTS order_items;

CREATE TABLE order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

DROP TABLE IF EXISTS order_payments;

CREATE TABLE order_payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC
);

DROP TABLE IF EXISTS order_reviews;

CREATE TABLE order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

DROP TABLE IF EXISTS products;

CREATE TABLE products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght NUMERIC,
    product_description_lenght NUMERIC,
    product_photos_qty NUMERIC,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

DROP TABLE IF EXISTS sellers;

CREATE TABLE sellers (
    seller_id TEXT,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state TEXT
);

DROP TABLE IF EXISTS category_translation;

CREATE TABLE category_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);

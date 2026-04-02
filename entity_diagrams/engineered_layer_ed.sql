CREATE TABLE "orders" (
  "order_id" TEXT PRIMARY KEY,
  "customer_id" TEXT,
  "order_status" TEXT,
  "order_purchase_timestamp" TIMESTAMP,
  "order_approved_at" TIMESTAMP,
  "order_delivered_carrier_date" TIMESTAMP,
  "order_delivered_customer_date" TIMESTAMP,
  "order_estimated_delivery_date" TIMESTAMP
);

CREATE TABLE "customers" (
  "customer_id" TEXT PRIMARY KEY,
  "customer_unique_id" TEXT,
  "customer_zip_code_prefix" INTEGER,
  "customer_city" TEXT,
  "customer_state" TEXT
);

CREATE TABLE "order_items" (
  "order_id" TEXT,
  "order_item_id" INTEGER,
  "product_id" TEXT,
  "seller_id" TEXT,
  "shipping_limit_date" TIMESTAMP,
  "price" NUMERIC,
  "freight_value" NUMERIC
);

CREATE TABLE "order_payments" (
  "order_id" TEXT,
  "payment_sequential" INTEGER,
  "payment_type" TEXT,
  "payment_installments" INTEGER,
  "payment_value" NUMERIC
);

CREATE TABLE "order_reviews" (
  "review_id" TEXT PRIMARY KEY,
  "order_id" TEXT,
  "review_score" INTEGER,
  "review_comment_title" TEXT,
  "review_comment_message" TEXT,
  "review_creation_date" TIMESTAMP,
  "review_answer_timestamp" TIMESTAMP
);

CREATE TABLE "products" (
  "product_id" TEXT PRIMARY KEY,
  "product_category_name" TEXT,
  "product_name_lenght" NUMERIC,
  "product_description_lenght" NUMERIC,
  "product_photos_qty" NUMERIC,
  "product_weight_g" NUMERIC,
  "product_length_cm" NUMERIC,
  "product_height_cm" NUMERIC,
  "product_width_cm" NUMERIC
);

CREATE TABLE "sellers" (
  "seller_id" TEXT PRIMARY KEY,
  "seller_zip_code_prefix" INTEGER,
  "seller_city" TEXT,
  "seller_state" TEXT
);

CREATE TABLE "category_translation" (
  "product_category_name" TEXT PRIMARY KEY,
  "product_category_name_english" TEXT
);

CREATE TABLE "fact_order_items_clean" (
  "order_id" TEXT,
  "order_item_id" INTEGER,
  "product_id" TEXT,
  "seller_id" TEXT,
  "customer_id" TEXT,
  "order_status" TEXT,
  "order_purchase_timestamp" TIMESTAMP,
  "order_approved_at" TIMESTAMP,
  "order_delivered_carrier_date" TIMESTAMP,
  "order_delivered_customer_date" TIMESTAMP,
  "order_estimated_delivery_date" TIMESTAMP,
  "product_category_name" TEXT,
  "product_category_english" TEXT,
  "customer_city" TEXT,
  "customer_state" TEXT,
  "seller_city" TEXT,
  "seller_state" TEXT,
  "price" NUMERIC,
  "freight_value" NUMERIC,
  "item_gmv" NUMERIC,
  "purchase_date" DATE,
  "purchase_month" DATE,
  "delivery_days" INTEGER,
  "late_delivery_flag" INTEGER
);

CREATE TABLE "fact_orders_clean" (
  "order_id" TEXT,
  "customer_id" TEXT,
  "order_status" TEXT,
  "order_purchase_timestamp" TIMESTAMP,
  "order_approved_at" TIMESTAMP,
  "order_delivered_carrier_date" TIMESTAMP,
  "order_delivered_customer_date" TIMESTAMP,
  "order_estimated_delivery_date" TIMESTAMP,
  "customer_city" TEXT,
  "customer_state" TEXT,
  "total_items" INTEGER,
  "distinct_products" INTEGER,
  "distinct_sellers" INTEGER,
  "items_gmv" NUMERIC,
  "total_freight_value" NUMERIC,
  "order_gmv" NUMERIC,
  "purchase_date" DATE,
  "purchase_month" DATE,
  "delivery_days" INTEGER,
  "late_delivery_flag" INTEGER
);

ALTER TABLE "orders" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("order_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("product_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_items" ADD FOREIGN KEY ("seller_id") REFERENCES "sellers" ("seller_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_payments" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("order_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "order_reviews" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("order_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "products" ADD FOREIGN KEY ("product_category_name") REFERENCES "category_translation" ("product_category_name") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_order_items_clean" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("order_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_order_items_clean" ADD FOREIGN KEY ("product_id") REFERENCES "products" ("product_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_order_items_clean" ADD FOREIGN KEY ("seller_id") REFERENCES "sellers" ("seller_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_order_items_clean" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_orders_clean" ADD FOREIGN KEY ("order_id") REFERENCES "orders" ("order_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_orders_clean" ADD FOREIGN KEY ("customer_id") REFERENCES "customers" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

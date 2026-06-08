-- ============================================================
-- Codelab 2: BigQuery Federation SQL
-- Run these statements in AlloyDB Studio one at a time
-- Project: codevipasana-4
-- ============================================================

-- Step 1: Enable bigquery_fdw extension
CREATE EXTENSION IF NOT EXISTS bigquery_fdw;

-- Step 2: Create foreign data wrapper server
CREATE SERVER bigquery_server
FOREIGN DATA WRAPPER bigquery_fdw;

-- Step 3: Create user mapping
CREATE USER MAPPING FOR postgres
SERVER bigquery_server;

-- Step 4: Create live_orders table (native AlloyDB table)
CREATE TABLE IF NOT EXISTS live_orders (
    order_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    product_id VARCHAR(255),
    quantity INTEGER NOT NULL,
    order_status VARCHAR(50) DEFAULT 'Pending',
    order_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 5: Create foreign tables pointing to BigQuery
-- Replace 'your-project-id' with your actual project ID

CREATE FOREIGN TABLE allergen (
    allergen_name VARCHAR
) SERVER bigquery_server OPTIONS (
    project 'your-project-id',
    dataset 'froyo_data',
    table 'allergen'
);

CREATE FOREIGN TABLE consistsof (
    product_id VARCHAR,
    ingredient_id VARCHAR
) SERVER bigquery_server OPTIONS (
    project 'your-project-id',
    dataset 'froyo_data',
    table 'consistsof'
);

CREATE FOREIGN TABLE containsallergen (
    ingredient_id VARCHAR,
    allergen_name VARCHAR
) SERVER bigquery_server OPTIONS (
    project 'your-project-id',
    dataset 'froyo_data',
    table 'containsallergen'
);

CREATE FOREIGN TABLE froyo_data_materialized (
    allergen VARCHAR,
    containsallergen VARCHAR,
    ingredient VARCHAR,
    product VARCHAR,
    suppliedby VARCHAR,
    supplier VARCHAR,
    ref VARCHAR,
    md5_hash VARCHAR
) SERVER bigquery_server OPTIONS (
    project 'your-project-id',
    dataset 'froyo_data',
    table 'froyo_data_materialized'
);

CREATE FOREIGN TABLE ingredient (
    ingredient_id VARCHAR,
    ingredient_name VARCHAR,
    purity VARCHAR,
    moisture_content VARCHAR,
    ph_range VARCHAR,
    specific_gravity_range VARCHAR
) SERVER bigquery_server OPTIONS (
    project 'your-project-id',
    dataset 'froyo_data',
    table 'ingredient'
);

CREATE FOREIGN TABLE product (
    product_id VARCHAR,
    product_name VARCHAR,
    category VARCHAR,
    stability VARCHAR
) SERVER bigquery_server OPTIONS (
    project 'your-project-id',
    dataset 'froyo_data',
    table 'product'
);

CREATE FOREIGN TABLE suppliedby (
    ingredient_id VARCHAR,
    supplier_id VARCHAR
) SERVER bigquery_server OPTIONS (
    project 'your-project-id',
    dataset 'froyo_data',
    table 'suppliedby'
);

CREATE FOREIGN TABLE supplier (
    supplier_id VARCHAR,
    supplier_name VARCHAR,
    production_site_id VARCHAR,
    facility_grade VARCHAR
) SERVER bigquery_server OPTIONS (
    project 'your-project-id',
    dataset 'froyo_data',
    table 'supplier'
);

-- Step 6: Verify federation works
SELECT p.product_name, i.ingredient_name, a.allergen_name
FROM consistsof c
INNER JOIN product p ON c.product_id = p.product_id
INNER JOIN ingredient i ON c.ingredient_id = i.ingredient_name
LEFT OUTER JOIN containsallergen a ON i.ingredient_id = a.ingredient_id
WHERE UPPER(p.product_name) LIKE '%MIDNIGHT%SWIRL%'
AND a.allergen_name IS NOT NULL;
-- Expected: Returns allergen data for Midnight Swirl product

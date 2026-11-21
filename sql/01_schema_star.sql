DROP TABLE IF EXISTS fact_orders CASCADE;
DROP TABLE IF EXISTS dim_customers CASCADE;
DROP TABLE IF EXISTS dim_products CASCADE;
DROP TABLE IF EXISTS dim_locations CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

CREATE TABLE dim_customers (
    customer_id   VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    segment       VARCHAR(50) NOT NULL
);

CREATE TABLE dim_products (
    product_id   VARCHAR(30) PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category     VARCHAR(50) NOT NULL,
    sub_category VARCHAR(50) NOT NULL
);

CREATE TABLE dim_locations (
    location_id INT PRIMARY KEY,
    country     VARCHAR(50) NOT NULL,
    region      VARCHAR(50) NOT NULL,
    state       VARCHAR(50) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL
);

CREATE TABLE dim_date (
    date_key    DATE PRIMARY KEY,
    year        INT NOT NULL,
    quarter     INT NOT NULL,
    month       INT NOT NULL,
    month_name  VARCHAR(15) NOT NULL,
    day_of_week VARCHAR(15) NOT NULL,
    is_weekend  BOOLEAN NOT NULL
);

CREATE TABLE fact_orders (
    row_id      INT PRIMARY KEY,
    order_id    VARCHAR(30) NOT NULL,
    order_date  DATE NOT NULL REFERENCES dim_date(date_key),
    ship_date   DATE NOT NULL REFERENCES dim_date(date_key),
    ship_mode   VARCHAR(50) NOT NULL,
    customer_id VARCHAR(20) NOT NULL REFERENCES dim_customers(customer_id),
    product_id  VARCHAR(30) NOT NULL REFERENCES dim_products(product_id),
    location_id INT NOT NULL REFERENCES dim_locations(location_id),
    sales       NUMERIC(12, 4) NOT NULL,
    quantity    INT NOT NULL,
    discount    NUMERIC(5, 4) NOT NULL,
    profit      NUMERIC(12, 4) NOT NULL
);

CREATE INDEX idx_fact_order_date  ON fact_orders(order_date);
CREATE INDEX idx_fact_customer_id ON fact_orders(customer_id);
CREATE INDEX idx_fact_product_id  ON fact_orders(product_id);
CREATE INDEX idx_fact_location_id ON fact_orders(location_id);

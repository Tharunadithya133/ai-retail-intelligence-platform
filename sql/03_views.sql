DROP VIEW IF EXISTS vw_sales;

CREATE VIEW vw_sales AS

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value,
        STRING_AGG(DISTINCT payment_type, ', ') AS payment_type,
        MAX(payment_installments) AS payment_installments
    FROM olist_order_payments_dataset
    GROUP BY order_id
),

review_summary AS (
    SELECT
        order_id,
        ROUND(AVG(review_score)::numeric, 2) AS review_score
    FROM olist_order_reviews_dataset
    GROUP BY order_id
)

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,

    o.order_purchase_timestamp::timestamp
        AS order_purchase_timestamp,

    o.order_estimated_delivery_date::timestamp
        AS order_estimated_delivery_date,

    o.order_delivered_customer_date::timestamp
        AS order_delivered_customer_date,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN
            o.order_delivered_customer_date::timestamp
            - o.order_estimated_delivery_date::timestamp
    END AS delivery_delay,

    CASE
        WHEN o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
        THEN NULL

        WHEN o.order_delivered_customer_date::timestamp
           > o.order_estimated_delivery_date::timestamp
        THEN 'Late'

        ELSE 'On Time'
    END AS delivery_status,

    c.customer_unique_id,
    c.customer_city,
    c.customer_state,

    oi.order_item_id,
    oi.product_id,
    oi.seller_id,
    oi.shipping_limit_date::timestamp
        AS shipping_limit_date,

    oi.price,
    oi.freight_value,

    p.product_category_name,
    ct.product_category_name_english,

    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    (
        p.product_length_cm
        * p.product_height_cm
        * p.product_width_cm
    ) AS product_volume_cm3,

    s.seller_city,
    s.seller_state,
    s.seller_zip_code_prefix,

    ps.payment_value,
    ps.payment_type,
    ps.payment_installments,

    rs.review_score

FROM olist_orders_dataset o

INNER JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id

INNER JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id

LEFT JOIN olist_products_dataset p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation ct
    ON p.product_category_name =
       ct.product_category_name

LEFT JOIN olist_sellers_dataset s
    ON oi.seller_id = s.seller_id

LEFT JOIN payment_summary ps
    ON o.order_id = ps.order_id

LEFT JOIN review_summary rs
    ON o.order_id = rs.order_id;


DROP VIEW IF EXISTS vw_geo_clean;

CREATE VIEW vw_geo_clean AS
SELECT
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude,
    MAX(geolocation_city) AS city,
    MAX(geolocation_state)   AS state
FROM olist_geolocation_dataset
GROUP BY geolocation_zip_code_prefix;

DROP VIEW IF EXISTS vw_seller_performance;

CREATE VIEW vw_seller_performance AS

WITH seller_revenue AS (
    SELECT
        seller_id,
        SUM(price) AS total_revenue
    FROM vw_sales
    GROUP BY seller_id
),

seller_orders AS (
    SELECT DISTINCT
        seller_id,
        order_id,
        review_score,
        delivery_delay
    FROM vw_sales
    WHERE seller_id IS NOT NULL
)

SELECT
    so.seller_id,

    sr.total_revenue,

    ROUND(
        AVG(so.review_score)::numeric,
        2
    ) AS avg_review_score,

    ROUND(
        AVG(
            EXTRACT(EPOCH FROM so.delivery_delay) / 86400
        )::numeric,
        2
    ) AS avg_delivery_delay_days,

    COUNT(DISTINCT so.order_id) AS order_count

FROM seller_orders so

JOIN seller_revenue sr
    ON so.seller_id = sr.seller_id

GROUP BY
    so.seller_id,
    sr.total_revenue;

    DROP VIEW IF EXISTS vw_customer_rfm;

CREATE VIEW vw_customer_rfm AS

WITH customer_metrics AS (
    SELECT
        customer_unique_id,

        MAX(order_purchase_timestamp) AS last_purchase_date,

        COUNT(DISTINCT order_id) AS frequency,

        SUM(price) AS monetary

    FROM vw_sales

    GROUP BY customer_unique_id
),

reference_date AS (
    SELECT
        MAX(order_purchase_timestamp) AS max_purchase_date
    FROM vw_sales
)

SELECT
    cm.customer_unique_id,

    (
        rd.max_purchase_date::date
        - cm.last_purchase_date::date
    ) AS recency_days,

    cm.frequency,

    ROUND(cm.monetary::numeric, 2) AS monetary,

    CASE
        WHEN cm.frequency >= 4
             AND cm.monetary >= 1000
             AND (
                 rd.max_purchase_date::date
                 - cm.last_purchase_date::date
             ) <= 90
        THEN 'Champions'

        WHEN cm.frequency >= 2
             AND (
                 rd.max_purchase_date::date
                 - cm.last_purchase_date::date
             ) <= 180
        THEN 'Loyal'

        WHEN cm.frequency = 1
             AND (
                 rd.max_purchase_date::date
                 - cm.last_purchase_date::date
             ) <= 180
        THEN 'Potential'

        WHEN (
                 rd.max_purchase_date::date
                 - cm.last_purchase_date::date
             ) <= 365
        THEN 'At Risk'

        ELSE 'Lost'
    END AS customer_segment

FROM customer_metrics cm
CROSS JOIN reference_date rd;

DROP VIEW IF EXISTS vw_cohort_retention;

CREATE VIEW vw_cohort_retention AS

WITH customer_orders AS (
    SELECT DISTINCT
        customer_unique_id,
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS order_month
    FROM vw_sales
),

first_purchase AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS first_purchase_month
    FROM customer_orders
    GROUP BY customer_unique_id
)

SELECT
    co.customer_unique_id,
    fp.first_purchase_month,
    co.order_month,

    (
        EXTRACT(
            YEAR FROM AGE(
                co.order_month,
                fp.first_purchase_month
            )
        ) * 12
        +
        EXTRACT(
            MONTH FROM AGE(
                co.order_month,
                fp.first_purchase_month
            )
        )
    )::integer AS month_number,

    1 AS active

FROM customer_orders co

JOIN first_purchase fp
    ON co.customer_unique_id = fp.customer_unique_id;

    DROP VIEW IF EXISTS vw_data_quality;

CREATE VIEW vw_data_quality AS

SELECT
    order_id,
    order_item_id,
    customer_unique_id,
    seller_id,
    product_id,

    price,
    freight_value,

    order_purchase_timestamp,
    order_estimated_delivery_date,
    order_delivered_customer_date,

    delivery_delay,
    delivery_status,

    review_score,

    CASE
        WHEN delivery_delay IS NOT NULL
         AND EXTRACT(EPOCH FROM delivery_delay) / 86400 > 30
        THEN 'Extreme Delivery Delay'

        WHEN price > 5000
        THEN 'High Price'

        WHEN order_delivered_customer_date IS NULL
         AND order_status = 'delivered'
        THEN 'Missing Delivery Date'

        WHEN review_score IS NULL
        THEN 'Missing Review'

        ELSE 'Normal'
    END AS anomaly_type

FROM vw_sales;
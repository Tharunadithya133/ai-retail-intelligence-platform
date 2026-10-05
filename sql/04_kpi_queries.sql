SELECT
    SUM(price) AS total_revenue,

    COUNT(DISTINCT order_id) AS total_orders,

    COUNT(DISTINCT customer_unique_id) AS total_customers,

    ROUND(
        (SUM(price) / COUNT(DISTINCT order_id))::numeric,
        2
    ) AS average_order_value,

    ROUND(
        AVG(review_score)::numeric,
        2
    ) AS average_review_score

FROM vw_sales;


-- Delivery Performance KPIs

-- Delivery Performance KPIs

WITH order_delivery AS (
    SELECT DISTINCT
        order_id,
        delivery_status,
        delivery_delay
    FROM vw_sales
    WHERE delivery_status IN ('On Time', 'Late')
)

SELECT
    COUNT(*) FILTER (
        WHERE delivery_status = 'On Time'
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE delivery_status = 'Late'
    ) AS late_orders,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_status = 'On Time'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_percentage,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE delivery_status = 'Late'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_percentage,

    ROUND(
        AVG(
            EXTRACT(EPOCH FROM delivery_delay) / 86400
        )::numeric,
        2
    ) AS average_delivery_delay_days

FROM order_delivery;

-- Repeat Customer KPI

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM vw_sales
    GROUP BY customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE order_count > 1
    ) AS repeat_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_count > 1
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_percentage

FROM customer_orders;

-- Monthly Revenue and MoM Growth

WITH monthly AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::date AS month,

        SUM(price) AS revenue

    FROM vw_sales

    GROUP BY 1
)

SELECT
    month,

    ROUND(
        revenue::numeric,
        2
    ) AS revenue,

    ROUND(
        LAG(revenue) OVER (
            ORDER BY month
        )::numeric,
        2
    ) AS previous_month_revenue,

    ROUND(
        (
            100.0 *
            (
                revenue
                - LAG(revenue) OVER (
                    ORDER BY month
                )
            )
            /
            NULLIF(
                LAG(revenue) OVER (
                    ORDER BY month
                ),
                0
            )
        )::numeric,
        2
    ) AS mom_growth_percentage

FROM monthly

ORDER BY month;
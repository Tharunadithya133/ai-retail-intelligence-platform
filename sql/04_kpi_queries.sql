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

SELECT
    COUNT(*) FILTER (
        WHERE delivery_status = 'On Time'
    ) AS on_time_items,

    COUNT(*) FILTER (
        WHERE delivery_status = 'Late'
    ) AS late_items,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE delivery_status = 'On Time'
            )::numeric
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE delivery_status IN ('On Time', 'Late')
                ),
                0
            )
        ) * 100,
        2
    ) AS on_time_percentage,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE delivery_status = 'Late'
            )::numeric
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE delivery_status IN ('On Time', 'Late')
                ),
                0
            )
        ) * 100,
        2
    ) AS late_percentage,

    ROUND(
        (
            AVG(
                EXTRACT(EPOCH FROM delivery_delay) / 86400
            )
        )::numeric,
        2
    ) AS average_delivery_delay_days

FROM vw_sales;
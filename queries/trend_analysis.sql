WITH valid_orders AS (
    SELECT
        order_id,
        order_date::date AS order_date
    FROM orders
    WHERE status = 'completed'
),

daily_metrics AS (
    SELECT
        vo.order_date AS order_day,
        SUM(oi.quantity * oi.unit_price) AS daily_revenue,
        COUNT(DISTINCT vo.order_id) AS daily_order_count
    FROM valid_orders vo
    JOIN order_items oi
        ON vo.order_id = oi.order_id
    GROUP BY vo.order_date
)

SELECT
    order_day,
    daily_revenue,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY order_day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_ma_7d,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY order_day
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_ma_30d,
    daily_order_count,
    ROUND(
        AVG(daily_order_count) OVER (
            ORDER BY order_day
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS orders_ma_7d
FROM daily_metrics
ORDER BY order_day;
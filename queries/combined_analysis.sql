-- Query 1: Monthly revenue by customer segment with MoM growth and running total

WITH valid_orders AS (
    SELECT
        order_id,
        customer_id,
        order_date::date AS order_date
    FROM orders
    WHERE status = 'completed'
),

segment_monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', vo.order_date)::date AS month_start,
        c.segment,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM valid_orders vo
    JOIN customers c
        ON vo.customer_id = c.customer_id
    JOIN order_items oi
        ON vo.order_id = oi.order_id
    GROUP BY 1, 2
)

SELECT
    month_start,
    segment,
    revenue,
    LAG(revenue) OVER (
        PARTITION BY segment
        ORDER BY month_start
    ) AS prev_month_revenue,
    ROUND(
        100.0 * (
            revenue - LAG(revenue) OVER (
                PARTITION BY segment
                ORDER BY month_start
            )
        )
        / NULLIF(
            LAG(revenue) OVER (
                PARTITION BY segment
                ORDER BY month_start
            ),
            0
        ),
        2
    ) AS mom_growth_pct,
    ROUND(
        SUM(revenue) OVER (
            PARTITION BY segment
            ORDER BY month_start
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_total_revenue
FROM segment_monthly_revenue
ORDER BY segment, month_start;

-- Query 2: Category monthly revenue share with 3-month moving average

WITH valid_orders AS (
    SELECT
        order_id,
        order_date::date AS order_date
    FROM orders
    WHERE status = 'completed'
),

category_monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', vo.order_date)::date AS month_start,
        p.category,
        SUM(oi.quantity * oi.unit_price) AS category_revenue
    FROM valid_orders vo
    JOIN order_items oi
        ON vo.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY 1, 2
),

category_with_share AS (
    SELECT
        month_start,
        category,
        category_revenue,
        SUM(category_revenue) OVER (
            PARTITION BY month_start
        ) AS total_month_revenue
    FROM category_monthly_revenue
)

SELECT
    month_start,
    category,
    category_revenue,
    ROUND(100.0 * category_revenue / NULLIF(total_month_revenue, 0), 2) AS revenue_share_pct,
    ROUND(
        AVG(category_revenue) OVER (
            PARTITION BY category
            ORDER BY month_start
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS revenue_ma_3m
FROM category_with_share
ORDER BY category, month_start;
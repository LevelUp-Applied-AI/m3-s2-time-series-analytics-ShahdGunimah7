WITH valid_orders AS (
    SELECT
        order_id,
        customer_id,
        order_date::date AS order_date
    FROM orders
    WHERE status = 'completed'
),

monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', vo.order_date)::date AS month_start,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        COUNT(DISTINCT vo.order_id) AS order_count
    FROM valid_orders vo
    JOIN order_items oi
        ON vo.order_id = oi.order_id
    GROUP BY 1
),

monthly_growth AS (
    SELECT
        month_start,
        revenue,
        order_count,
        LAG(revenue) OVER (ORDER BY month_start) AS prev_revenue,
        LAG(order_count) OVER (ORDER BY month_start) AS prev_orders
    FROM monthly_metrics
)

SELECT
    month_start,
    revenue,
    prev_revenue,
    ROUND(
        100.0 * (revenue - prev_revenue) / NULLIF(prev_revenue, 0),
        2
    ) AS revenue_growth_pct,
    order_count,
    prev_orders,
    ROUND(
        100.0 * (order_count - prev_orders) / NULLIF(prev_orders, 0),
        2
    ) AS order_growth_pct
FROM monthly_growth
ORDER BY month_start;

WITH valid_orders AS (
    SELECT
        order_id,
        order_date::date AS order_date
    FROM orders
    WHERE status = 'completed'
),

quarterly_revenue AS (
    SELECT
        DATE_TRUNC('quarter', vo.order_date)::date AS quarter_start,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM valid_orders vo
    JOIN order_items oi
        ON vo.order_id = oi.order_id
    GROUP BY 1
),

quarterly_growth AS (
    SELECT
        quarter_start,
        revenue,
        LAG(revenue) OVER (ORDER BY quarter_start) AS prev_revenue
    FROM quarterly_revenue
)

SELECT
    quarter_start,
    revenue,
    prev_revenue,
    ROUND(
        100.0 * (revenue - prev_revenue) / NULLIF(prev_revenue, 0),
        2
    ) AS qoq_growth_pct
FROM quarterly_growth
ORDER BY quarter_start;

WITH valid_orders AS (
    SELECT
        order_id,
        customer_id,
        order_date::date AS order_date
    FROM orders
    WHERE status = 'completed'
),

monthly_drivers AS (
    SELECT
        DATE_TRUNC('month', vo.order_date)::date AS month_start,
        COUNT(DISTINCT vo.customer_id) AS unique_customers,
        COUNT(DISTINCT vo.order_id) AS total_orders,
        SUM(oi.quantity * oi.unit_price) AS revenue,
        ROUND(
            SUM(oi.quantity * oi.unit_price) 
            / NULLIF(COUNT(DISTINCT vo.order_id), 0),
            2
        ) AS avg_order_value
    FROM valid_orders vo
    JOIN order_items oi
        ON vo.order_id = oi.order_id
    GROUP BY 1
)

SELECT
    month_start,
    unique_customers,
    total_orders,
    revenue,
    avg_order_value,
    LAG(unique_customers) OVER (ORDER BY month_start) AS prev_customers,
    LAG(avg_order_value) OVER (ORDER BY month_start) AS prev_aov
FROM monthly_drivers
ORDER BY month_start;

WITH valid_orders AS (
    SELECT order_id, order_date::date AS order_date
    FROM orders
    WHERE status = 'completed'
)

SELECT
    DATE_TRUNC('month', vo.order_date)::date AS month_start,
    p.category,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM valid_orders vo
JOIN order_items oi ON vo.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY 1, 2
ORDER BY 1, revenue DESC;
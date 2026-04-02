WITH valid_orders AS (
    SELECT
        order_id,
        customer_id,
        order_date::date AS order_date
    FROM orders
    WHERE status = 'completed'
),

ranked_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS rn
    FROM valid_orders
),

first_purchase AS (
    SELECT
        customer_id,
        order_date AS first_purchase_date,
        DATE_TRUNC('month', order_date)::date AS cohort_month
    FROM ranked_orders
    WHERE rn = 1
),

repeat_orders AS (
    SELECT
        fp.customer_id,
        fp.cohort_month,
        fp.first_purchase_date,
        vo.order_date,
        (vo.order_date - fp.first_purchase_date) AS days_since_first
    FROM first_purchase fp
    JOIN valid_orders vo
        ON fp.customer_id = vo.customer_id
    WHERE vo.order_date > fp.first_purchase_date
),

retention_flags AS (
    SELECT
        customer_id,
        cohort_month,
        MAX(CASE WHEN days_since_first <= 30 THEN 1 ELSE 0 END) AS repeat_30d,
        MAX(CASE WHEN days_since_first <= 60 THEN 1 ELSE 0 END) AS repeat_60d,
        MAX(CASE WHEN days_since_first <= 90 THEN 1 ELSE 0 END) AS repeat_90d
    FROM repeat_orders
    GROUP BY customer_id, cohort_month
),

cohort_base AS (
    SELECT
        customer_id,
        cohort_month
    FROM first_purchase
)

SELECT
    cb.cohort_month,
    COUNT(*) AS cohort_size,
    ROUND(100.0 * AVG(COALESCE(rf.repeat_30d, 0)), 2) AS repeat_30d_pct,
    ROUND(100.0 * AVG(COALESCE(rf.repeat_60d, 0)), 2) AS repeat_60d_pct,
    ROUND(100.0 * AVG(COALESCE(rf.repeat_90d, 0)), 2) AS repeat_90d_pct
FROM cohort_base cb
LEFT JOIN retention_flags rf
    ON cb.customer_id = rf.customer_id
    AND cb.cohort_month = rf.cohort_month
GROUP BY cb.cohort_month
ORDER BY cb.cohort_month;
WITH customer_base AS (
    SELECT DISTINCT
        c.customer_id,
        c.customer_name,
        c.city,
        c.country,
        c.created_date,
        c.status
    FROM customers c
    WHERE YEAR(c.created_date) >= 2020
),
order_base AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.total_amount,
        o.status
    FROM orders o
    WHERE MONTH(o.order_date) IN (1,2,3,4,5,6,7,8,9,10,11,12)
),
payment_base AS (
    SELECT
        p.payment_id,
        p.order_id,
        p.payment_date,
        p.amount,
        p.payment_method
    FROM payments p
),
shipment_base AS (
    SELECT
        s.shipment_id,
        s.order_id,
        s.ship_date,
        s.delivery_date
    FROM shipments s
),
product_sales AS (
    SELECT
        oi.order_id,
        oi.product_id,
        oi.quantity,
        oi.unit_price,
        oi.quantity * oi.unit_price AS line_total
    FROM order_items oi
),
customer_metrics AS (
    SELECT
        cb.customer_id,

        (
            SELECT COUNT(*)
            FROM orders o1
            WHERE o1.customer_id = cb.customer_id
        ) AS total_orders,

        (
            SELECT SUM(o2.total_amount)
            FROM orders o2
            WHERE o2.customer_id = cb.customer_id
        ) AS total_revenue,

        (
            SELECT MAX(o3.order_date)
            FROM orders o3
            WHERE o3.customer_id = cb.customer_id
        ) AS last_order_date

    FROM customer_base cb
),
product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,

        (
            SELECT COUNT(*)
            FROM order_items oi
            WHERE oi.product_id = p.product_id
        ) AS sale_count,

        (
            SELECT AVG(oi.unit_price)
            FROM order_items oi
            WHERE oi.product_id = p.product_id
        ) AS avg_price

    FROM products p
),
ranking_data AS (
    SELECT
        cm.*,
        ROW_NUMBER() OVER (
            PARTITION BY country
            ORDER BY total_revenue DESC
        ) AS rn
    FROM customer_metrics cm
    JOIN customer_base cb
        ON cm.customer_id = cb.customer_id
),
duplicate_orders AS (
    SELECT *
    FROM order_base
    UNION
    SELECT *
    FROM order_base
),
expanded_data AS (
    SELECT
        cb.customer_id,
        cb.customer_name,
        ob.order_id,
        ob.order_date,
        pb.payment_id,
        sb.shipment_id,
        ps.product_id,
        pm.product_name,
        ps.line_total
    FROM customer_base cb
        LEFT JOIN order_base ob
            ON cb.customer_id = ob.customer_id
        LEFT JOIN payment_base pb
            ON ob.order_id = pb.order_id
        LEFT JOIN shipment_base sb
            ON ob.order_id = sb.order_id
        LEFT JOIN product_sales ps
            ON ob.order_id = ps.order_id
        LEFT JOIN product_metrics pm
            ON ps.product_id = pm.product_id
)

SELECT DISTINCT
    e.customer_id,
    e.customer_name,
    e.order_id,
    e.order_date,

    (
        SELECT SUM(amount)
        FROM payments p
        WHERE p.order_id = e.order_id
    ) AS payment_total,

    (
        SELECT COUNT(*)
        FROM shipments s
        WHERE s.order_id = e.order_id
    ) AS shipment_count,

    rd.total_orders,
    rd.total_revenue,
    rd.last_order_date,

    pm.sale_count,
    pm.avg_price,

    CASE
        WHEN rd.total_revenue > 100000 THEN 'PLATINUM'
        WHEN rd.total_revenue > 50000 THEN 'GOLD'
        ELSE 'SILVER'
    END AS customer_tier,

    DATEDIFF(
        DAY,
        rd.last_order_date,
        GETDATE()
    ) AS days_since_last_order

FROM expanded_data e

LEFT JOIN ranking_data rd
    ON e.customer_id = rd.customer_id

LEFT JOIN product_metrics pm
    ON e.product_id = pm.product_id

LEFT JOIN customers c1
    ON c1.customer_id = e.customer_id

LEFT JOIN customers c2
    ON c2.customer_id = e.customer_id

LEFT JOIN customers c3
    ON c3.customer_id = e.customer_id

LEFT JOIN customers c4
    ON c4.customer_id = e.customer_id

LEFT JOIN customers c5
    ON c5.customer_id = e.customer_id

WHERE
    UPPER(e.customer_name) LIKE '%JOHN%'
    OR YEAR(e.order_date) = 2024
    OR EXISTS (
        SELECT 1
        FROM orders ox
        WHERE ox.customer_id = e.customer_id
    )

ORDER BY
    e.customer_name,
    e.order_date DESC;
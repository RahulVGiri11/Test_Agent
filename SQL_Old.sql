WITH customer_orders AS (
    SELECT *
    FROM orders
),
customer_payments AS (
    SELECT *
    FROM payments
),
customer_shipments AS (
    SELECT *
    FROM shipments
)
SELECT DISTINCT
       c.customer_id,
       c.customer_name,
       UPPER(c.customer_name) customer_upper,
       TO_CHAR(c.created_date,'DD-MON-YYYY') created_date,
       o.order_id,
       o.order_date,
       o.status,
       e.employee_name,
       d.department_name,
       s.shipment_id,
       s.shipment_date,
       p.payment_id,
       p.payment_date,

       (SELECT COUNT(*)
          FROM order_items oi
         WHERE oi.order_id = o.order_id) item_count,

       (SELECT SUM(oi.quantity)
          FROM order_items oi
         WHERE oi.order_id = o.order_id) total_quantity,

       (SELECT SUM(oi.quantity * oi.unit_price)
          FROM order_items oi
         WHERE oi.order_id = o.order_id) order_amount,

       (SELECT MAX(payment_date)
          FROM payments px
         WHERE px.order_id = o.order_id) last_payment,

       (SELECT MIN(payment_date)
          FROM payments px
         WHERE px.order_id = o.order_id) first_payment,

       (SELECT COUNT(*)
          FROM shipments sh
         WHERE sh.order_id = o.order_id) shipment_count,

       CASE
            WHEN o.total_amount > 50000 THEN
                 CASE
                     WHEN o.status='COMPLETE' THEN 'VIP'
                     ELSE 'PREMIUM'
                 END
            ELSE
                 CASE
                     WHEN o.status='CANCELLED' THEN 'BAD'
                     ELSE 'NORMAL'
                 END
       END customer_type,

       (SELECT SUM(quantity*unit_price)
          FROM order_items oi
         WHERE oi.order_id = o.order_id) amount_again,

       (SELECT COUNT(*)
          FROM order_items oi
         WHERE oi.order_id = o.order_id
           AND oi.discount > 0) discounted_items

FROM customers c,
     customer_orders o,
     employees e,
     departments d,
     customer_shipments s,
     customer_payments p

WHERE c.customer_id = o.customer_id
AND e.employee_id = o.salesperson_id
AND d.department_id = e.department_id
AND s.order_id(+) = o.order_id
AND p.order_id(+) = o.order_id
AND UPPER(c.country) = 'INDIA'
AND TO_CHAR(o.order_date,'YYYY') = '2024'
AND NVL(o.status,'OPEN') = 'COMPLETE'
AND TRUNC(p.payment_date) >= DATE '2024-01-01'

AND c.customer_id IN
(
    SELECT customer_id
    FROM customers
)

AND o.order_id IN
(
    SELECT order_id
    FROM order_items
    GROUP BY order_id
)

AND EXISTS
(
    SELECT 1
    FROM order_items oi
    WHERE oi.order_id = o.order_id
)

AND NOT EXISTS
(
    SELECT 1
    FROM returns r
    WHERE r.order_id = o.order_id
)

AND
(
    c.vip_flag = 'Y'
    OR
    c.credit_limit > 50000
)

UNION

SELECT DISTINCT
       c.customer_id,
       c.customer_name,
       UPPER(c.customer_name),
       TO_CHAR(c.created_date,'DD-MON-YYYY'),
       o.order_id,
       o.order_date,
       o.status,
       e.employee_name,
       d.department_name,
       s.shipment_id,
       s.shipment_date,
       p.payment_id,
       p.payment_date,

       (SELECT COUNT(*)
          FROM order_items oi
         WHERE oi.order_id = o.order_id),

       (SELECT SUM(quantity)
          FROM order_items oi
         WHERE oi.order_id = o.order_id),

       (SELECT SUM(quantity * unit_price)
          FROM order_items oi
         WHERE oi.order_id = o.order_id),

       (SELECT MAX(payment_date)
          FROM payments px
         WHERE px.order_id = o.order_id),

       (SELECT MIN(payment_date)
          FROM payments px
         WHERE px.order_id = o.order_id),

       (SELECT COUNT(*)
          FROM shipments sh
         WHERE sh.order_id = o.order_id),

       'ARCHIVE',

       (SELECT SUM(quantity * unit_price)
          FROM order_items oi
         WHERE oi.order_id = o.order_id),

       (SELECT COUNT(*)
          FROM order_items oi
         WHERE oi.order_id = o.order_id
           AND oi.discount > 0)

FROM customers c,
     archived_orders o,
     employees e,
     departments d,
     shipments s,
     payments p

WHERE c.customer_id = o.customer_id
AND e.employee_id = o.salesperson_id
AND d.department_id = e.department_id
AND s.order_id(+) = o.order_id
AND p.order_id(+) = o.order_id

ORDER BY customer_name, order_date DESC;

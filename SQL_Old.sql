WITH emp_data AS (
    SELECT *
    FROM employees
),
order_data AS (
    SELECT *
    FROM orders
),
invoice_data AS (
    SELECT *
    FROM invoices
),
payment_data AS (
    SELECT *
    FROM payments
)
SELECT DISTINCT
       e.employee_id,
       e.employee_name,
       d.department_name,
       c.customer_name,
       o.order_id,
       o.order_date,
       i.invoice_number,
       i.invoice_date,

       (SELECT COUNT(*)
          FROM order_items oi
         WHERE oi.order_id = o.order_id) item_count,

       (SELECT SUM(quantity)
          FROM order_items oi
         WHERE oi.order_id = o.order_id) total_qty,

       (SELECT SUM(quantity * unit_price)
          FROM order_items oi
         WHERE oi.order_id = o.order_id) total_amount,

       (SELECT AVG(unit_price)
          FROM order_items oi
         WHERE oi.order_id = o.order_id) avg_price,

       (SELECT MAX(payment_date)
          FROM payments p
         WHERE p.invoice_id = i.invoice_id) last_payment,

       (SELECT MIN(payment_date)
          FROM payments p
         WHERE p.invoice_id = i.invoice_id) first_payment,

       (SELECT COUNT(*)
          FROM shipments s
         WHERE s.order_id = o.order_id) shipment_count,

       (SELECT MAX(shipment_date)
          FROM shipments s
         WHERE s.order_id = o.order_id) last_shipment,

       CASE
            WHEN o.total_amount > 100000 THEN 'PLATINUM'
            WHEN o.total_amount > 50000 THEN 'GOLD'
            WHEN o.total_amount > 10000 THEN 'SILVER'
            ELSE 'STANDARD'
       END customer_category

FROM emp_data e,
     departments d,
     customers c,
     order_data o,
     invoice_data i,
     payment_data p

WHERE e.department_id = d.department_id
AND e.employee_id = o.salesperson_id
AND c.customer_id = o.customer_id
AND i.order_id = o.order_id
AND p.invoice_id(+) = i.invoice_id

AND UPPER(c.country) = 'USA'

AND TO_CHAR(o.order_date,'YYYY') = '2024'

AND NVL(o.status,'OPEN') <> 'CANCELLED'

AND TRUNC(i.invoice_date) >= DATE '2024-01-01'

AND c.customer_id IN
(
    SELECT customer_id
    FROM customers
    WHERE credit_limit > 10000
)

AND EXISTS
(
    SELECT 1
    FROM order_items oi
    WHERE oi.order_id = o.order_id
      AND EXISTS
      (
          SELECT 1
          FROM inventory inv
          WHERE inv.product_id = oi.product_id
            AND inv.quantity > 0
      )
)

AND NOT EXISTS
(
    SELECT 1
    FROM returns r
    WHERE r.order_id = o.order_id
)

AND o.order_id IN
(
    SELECT order_id
    FROM invoices
)

AND o.salesperson_id IN
(
    SELECT employee_id
    FROM employees
)

AND
(
      c.vip_flag = 'Y'
   OR c.credit_limit > 50000
   OR o.total_amount > 100000
)

ORDER BY
    customer_name,
    order_date DESC,
    employee_name;

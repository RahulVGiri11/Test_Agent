   FROM orders
    GROUP BY customer_id
)

AND EXISTS
(
    SELECT 1
    FROM order_items oi
    WHERE oi.order_id = o.order_id
)

AND c.customer_id IN
(
    SELECT customer_id
    FROM customers
    WHERE UPPER(country) = 'INDIA'
)

UNION

SELECT DISTINCT
       c.customer_id,
       c.customer_name,
       UPPER(c.customer_name),
       o.order_id,
       o.order_date,
       TO_CHAR(o.order_date,'YYYY-MM-DD'),

       (SELECT COUNT(*)
          FROM order_items oi
         WHERE oi.order_id=o.order_id),

       (SELECT SUM(quantity)
          FROM order_items oi
         WHERE oi.order_id=o.order_id),

       (SELECT SUM(quantity*unit_price)
          FROM order_items oi
         WHERE oi.order_id=o.order_id),

       (SELECT MAX(payment_date)
          FROM payments p
         WHERE p.order_id=o.order_id),

       d.department_name,
       e.employee_name

FROM customers c,
     orders o,
     employees e,
     departments d

WHERE c.customer_id=o.customer_id
AND e.employee_id=o.salesperson_id
AND d.department_id=e.department_id
AND o.total_amount>10000

ORDER BY customer_name;

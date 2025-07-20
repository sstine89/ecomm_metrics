WITH recent_orders AS (
  SELECT *
  FROM orders
  WHERE order_date >= DATEADD(year, -1, CURRENT_DATE)
),

order_profits AS (
  SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    oi.product_id,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    p.base_cost,
    (oi.quantity * (oi.unit_price - p.base_cost)) AS profit
  FROM recent_orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  JOIN products p ON oi.product_id = p.product_id
),

customer_metrics AS (
  SELECT
    c.customer_id,
    c.name,
    c.region,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.order_date) AS active_days,
    SUM(op.profit) AS total_profit,
    AVG(op.profit) AS avg_profit_per_item,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    COUNT(DISTINCT s.ticket_id) AS support_tickets,
    SUM(CASE WHEN s.resolved_at IS NULL THEN 1 ELSE 0 END) AS unresolved_tickets
  FROM customers c
  JOIN recent_orders o ON c.customer_id = o.customer_id
  JOIN order_profits op ON o.order_id = op.order_id
  LEFT JOIN support_tickets s ON c.customer_id = s.customer_id
  GROUP BY c.customer_id, c.name, c.region
),

ranked_customers AS (
  SELECT *,
         PERCENT_RANK() OVER (ORDER BY total_profit DESC) AS profit_percentile,
         DENSE_RANK() OVER (PARTITION BY region ORDER BY total_profit DESC) AS regional_rank
  FROM customer_metrics
)
# CU-86aacg3vh: This is a test file to trigger ClickUp GitHub integration
SELECT
  customer_id,
  name,
  region,
  total_orders,
  active_days,
  ROUND(total_profit, 2) AS total_profit,
  ROUND(avg_profit_per_item, 2) AS avg_profit_per_item,
  ROUND(total_orders * 1.0 / NULLIF(active_days, 0), 2) AS avg_orders_per_day,
  first_order_date,
  last_order_date,
  support_tickets,
  unresolved_tickets,
  CASE WHEN unresolved_tickets > 0 THEN '⚠️ Needs Attention' ELSE '✅ Healthy' END AS support_flag,
  regional_rank
FROM ranked_customers
WHERE profit_percentile >= 0.90
ORDER BY total_profit DESC
LIMIT 100;

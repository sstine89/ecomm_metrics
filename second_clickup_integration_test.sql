


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


# ClickUp GitHub Integration Test
This file is used to test commit and PR tracking with ClickUp task CU-86aacg3vh

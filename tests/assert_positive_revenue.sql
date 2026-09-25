select
    order_id,
    revenue_usd

from {{ ref('fct_daily_revenue') }}

where revenue_usd <= 0
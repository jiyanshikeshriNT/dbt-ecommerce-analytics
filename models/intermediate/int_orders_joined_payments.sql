with orders as (
    select *
    from {{ ref('stg_orders') }}
),

payments as (
    select *
    from {{ ref('stg_payments') }}
),

joined as (
    select
        o.order_id,
        o.customer_id,
        o.order_date,
        o.status,
        sum(coalesce(p.amount_cents, 0)) as revenue_cents,
        sum(coalesce(p.amount_cents, 0)) / 100.0 as revenue_usd,
        max(p.created_at) as last_payment_at
    from orders o
    left join payments p
        on o.order_id = p.order_id
    group by
        o.order_id,
        o.customer_id,
        o.order_date,
        o.status
)

select *
from joined
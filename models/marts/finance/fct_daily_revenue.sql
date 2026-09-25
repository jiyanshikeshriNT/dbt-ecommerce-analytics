{{
    config(
        materialized='incremental',
        unique_key='order_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns'
    )
}}

with orders_revenue as (

    select *
    from {{ ref('int_orders_joined_payments') }}

),

customers as (

    select
        customer_id
    from {{ ref('dim_customers') }}

),

revenue as (

    select
        r.order_id,
        r.customer_id,
        r.order_date,
        r.status,
        r.revenue_cents,

        {{ cents_to_dollars('r.revenue_cents') }} as revenue_usd,

        r.last_payment_at

    from orders_revenue r

    left join customers c
        on r.customer_id = c.customer_id

)

select *
from revenue

{% if is_incremental() %}

where order_date >= (

    select
        (
            coalesce(
                max(order_date),
                date '1900-01-01'
            ) - interval '3 days'
        )::date

    from {{ this }}

)

{% endif %}
with source as (
    select *
    from {{ source('ecommerce', 'raw_payments') }}
),
renamed as (
    select
        cast(payment_id as integer) as payment_id,
        cast(order_id as integer) as order_id,
        cast(payment_method as varchar) as payment_method,
        cast(amount_cents as integer) as amount_cents,
        cast(created_at as timestamp) as created_at,
        cast(_fivetran_synced as timestamp) as _fivetran_synced
    from source
)
select * from renamed
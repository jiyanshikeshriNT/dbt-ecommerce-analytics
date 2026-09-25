with source as (
    select *
    from {{ source('ecommerce', 'raw_orders') }}
),
renamed as (
    select
        cast(order_id as integer) as order_id,
        cast(customer_id as integer) as customer_id,
        cast(order_date as date) as order_date,
        cast(status as varchar) as status,
        cast(_fivetran_synced as timestamp) as _fivetran_synced
    from source
)
select * from renamed
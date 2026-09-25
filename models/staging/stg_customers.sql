with source as (
    select *
    from {{ source('ecommerce', 'raw_customers') }}
),
renamed as (
    select
        cast(customer_id as integer) as customer_id,
        cast(first_name as varchar) as first_name,
        cast(last_name as varchar) as last_name,
        cast(email as varchar) as email,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at
    from source
)
select * from renamed
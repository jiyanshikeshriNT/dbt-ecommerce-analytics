with requested_times as (

    select
        'before_change' as lookup_type,
        timestamp '2026-09-20 12:00:00' as as_of_timestamp

    union all

    select
        'after_change' as lookup_type,
        timestamp '2026-09-25 16:00:00' as as_of_timestamp

)

select
    r.lookup_type,
    r.as_of_timestamp,
    s.customer_id,
    s.email,
    s.dbt_valid_from,
    s.dbt_valid_to

from {{ ref('snap_customers') }} s

cross join requested_times r

where s.customer_id = 1

  and r.as_of_timestamp >= s.dbt_valid_from

  and (
        r.as_of_timestamp < s.dbt_valid_to
        or s.dbt_valid_to is null
      )

order by r.as_of_timestamp;
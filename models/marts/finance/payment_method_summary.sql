select
    order_id,
    {{ pivot_payment_methods() }}
from {{ ref('stg_payments') }}
group by order_id
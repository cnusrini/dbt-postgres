select
    order_id,
    revenue,
    cost,
    {{ add_margin('revenue', 'cost') }}
from (
    select
        order_id,
        amount as revenue,
        amount * 0.6 as cost
    from {{ ref('stg_orders') }}
) base
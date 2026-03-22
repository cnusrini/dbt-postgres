select
    order_id,
    amount,
    amount * 0.1 as tax
from {{ ref('stg_orders') }}
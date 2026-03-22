select
    order_id,
    amount,
    tax,
    amount + tax as total_amount
from {{ ref('int_order_metrics') }}
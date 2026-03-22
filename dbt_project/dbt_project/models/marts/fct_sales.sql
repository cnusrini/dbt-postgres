{{ config(materialized='incremental') }}

select
    order_id,
    amount,
    amount * 0.1 as tax,
    amount + (amount * 0.1) as total_amount
from {{ ref('int_order_metrics') }}

{% if is_incremental() %}
where order_id > (select max(order_id) from {{ this }})
{% endif %}
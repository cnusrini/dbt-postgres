{{ config(materialized='view') }}

select
    order_id,
    amount,
    amount * {{ var('tax_rate', 0.1) }} as tax
from {{ ref('stg_orders') }}

{% if target.name == 'dev' %}
limit 5
{% endif %}
{% macro add_margin(revenue_col, cost_col) %}
({{ revenue_col }} - {{ cost_col }}) / {{ revenue_col }} as margin
{% endmacro %}
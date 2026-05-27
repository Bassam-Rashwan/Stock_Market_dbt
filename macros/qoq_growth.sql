{% macro qoq_growth(column_name,
                    partition_by = 'ticker',
                    order_by = 'fiscal_date') %}

(
    {{ column_name }} - lag({{ column_name }}) over (
        partition by {{ partition_by }}
        order by {{ order_by }}
    )
) / nullif(
    abs(
        lag({{ column_name }}) over (
            partition by {{ partition_by }}
            order by {{ order_by }}
        )
    ),
    0
)
{% endmacro %}

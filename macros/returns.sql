{% macro simple_return(price_column , partition_by = 'ticker',order_by = 'trade_date') %}

    (
        {{price_column}} /
        nullif(
            lag({{price_column}}) over (
            partition by {{partition_by}}
            order by {{order_by}}
        ),
         0)
    ) - 1
{% endmacro %}

{% macro log_return(price_column , partition_by = 'ticker',order_by = 'trade_date') %}

    ln(
        {{price_column}} /
        nullif(
            lag({{price_column}}) over (
            partition by {{partition_by}}
            order by {{order_by}}
        ),
         0)
    )
{% endmacro %}

-- {% macro compound_annual_return(price_column, partition_by='ticker', order_by='trade_date') %}

-- (
--     exp(
--         sum(
--             ln(
--                 {{ price_column }} /
--                 nullif(
--                     lag({{ price_column }}) over (
--                         partition by {{ partition_by }}
--                         order by {{ order_by }}
--                     ),
--                     0
--                 )
--             )
--         ) over (
--             partition by {{ partition_by }}
--             order by {{ order_by }}
--             rows between unbounded preceding and current row
--         ) * 252 /
--         count(*) over (
--             partition by {{ partition_by }}
--             order by {{ order_by }}
--             rows between unbounded preceding and current row
--         )
--     ) - 1
-- )

-- {% endmacro %}
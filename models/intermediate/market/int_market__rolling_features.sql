{{ config(
    materialized = 'table',
    schema = 'intermediate',
    tags = ['intermediate', 'market', 'rolling']
) }}

WITH base AS(
    SELECT *
    FROM {{ ref('int_market__daily_returns') }}
),

final AS(

    SELECT
    {{dbt_utils.generate_surrogate_key(['ticker', 'trade_date'])}} as rolling_features_sk,
    ticker,
    trade_date,
    adj_close,
    volume,
    daily_return,
    daily_log_return,
    intraday_return,
    daily_range_pct,

    --Rolling mean returns
    avg(daily_return)
     over (partition by ticker
            order by trade_date
            rows between 4 preceding and current row) as avg_return_5d,
    avg(daily_return)
     over (partition by ticker
            order by trade_date
            rows between 20 preceding and current row) as avg_return_21d  ,    

    -- Rolling Volatility
        stddev(daily_return) over (
            partition by ticker
            order by trade_date
            rows between 20 preceding and current row
        ) as volatility_21d,

        stddev(daily_return) over (
            partition by ticker
            order by trade_date
            rows between 62 preceding and current row
        ) as volatility_63d,

        -- rolling price averages
        avg(adj_close) over (
            partition by ticker
            order by trade_date
            rows between 9 preceding and current row
        ) as sma_10d,

        avg(adj_close) over (
            partition by ticker
            order by trade_date
            rows between 19 preceding and current row
        ) as sma_20d,

        avg(adj_close) over (
            partition by ticker
            order by trade_date
            rows between 49 preceding and current row
        ) as sma_50d,

        -- trailing returns using lag
        (adj_close / nullif(lag(adj_close, 5) over (
            partition by ticker order by trade_date
        ), 0)) - 1 as return_5d,

        (adj_close / nullif(lag(adj_close, 21) over (
            partition by ticker order by trade_date
        ), 0)) - 1 as return_21d,

        (adj_close / nullif(lag(adj_close, 63) over (
            partition by ticker order by trade_date
        ), 0)) - 1 as return_63d

    from base

)

select
    rolling_features_sk,
    ticker,
    trade_date,
    adj_close,
    volume,
    daily_return,
    daily_log_return,
    intraday_return,
    daily_range_pct,
    avg_return_5d,
    avg_return_21d,
    volatility_21d,
    volatility_63d,
    sma_10d,
    sma_20d,
    sma_50d,
    return_5d,
    return_21d,
    return_63d,
    adj_close / nullif(sma_20d, 0) - 1 as price_to_sma20_pct,
    adj_close / nullif(sma_50d, 0) - 1 as price_to_sma50_pct
from final
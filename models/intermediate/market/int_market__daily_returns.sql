{{
    config(
        materialized = 'table',
        schema = 'intermediate',
        tags = ['intermediate', 'market', 'returns']
    )
}}

WITH base AS(
    select
        ticker,
        trade_date,
        open,
        high,
        low,
        close,
        adj_close,
        volume
    from {{ ref('stg_market__ohlc_prices') }}

),

final AS(

    SELECT
    {{dbt_utils.generate_surrogate_key(['ticker', 'trade_date'])}} as daily_returns_sk,
    *,
    {{simple_return('adj_close')}} as daily_return,
    {{log_return('adj_close')}} as daily_log_return,
    {{ simple_return('close') }} as daily_return_close,
    {{ simple_return('volume') }} as volume_return ,    
    (close - open) / nullif(open, 0) as intraday_return,
    (high - low) / nullif(low, 0) as daily_range_pct

    from base
)

SELECT * FROM final
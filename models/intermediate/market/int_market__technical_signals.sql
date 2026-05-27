
{{ config(
    materialized = 'table',
    schema = 'intermediate',
    tags = ['intermediate', 'market', 'technical']
) }}

with base as (

    select *
    from {{ ref('int_market__rolling_features') }}

),

signal_prep as (

    select
        rolling_features_sk,
        ticker,
        trade_date,
        adj_close,
        daily_return,
        avg_return_5d,
        avg_return_21d,
        volatility_21d,
        sma_10d,
        sma_20d,
        sma_50d,
        return_5d,
        return_21d,
        return_63d,
        price_to_sma20_pct,
        price_to_sma50_pct,

        lag(sma_10d) over (
            partition by ticker
            order by trade_date
        ) as prev_sma_10d,

        lag(sma_20d) over (
            partition by ticker
            order by trade_date
        ) as prev_sma_20d,

        lag(sma_50d) over (
            partition by ticker
            order by trade_date
        ) as prev_sma_50d

    from base

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['ticker', 'trade_date']) }} as technical_signal_sk,
        ticker,
        trade_date,

        adj_close,
        daily_return,
        avg_return_5d,
        avg_return_21d,
        volatility_21d,
        sma_10d,
        sma_20d,
        sma_50d,
        return_5d,
        return_21d,
        return_63d,
        price_to_sma20_pct,
        price_to_sma50_pct,

        case
            when adj_close > sma_20d and adj_close > sma_50d then 'bullish'
            when adj_close < sma_20d and adj_close < sma_50d then 'bearish'
            else 'neutral'
        end as price_trend_regime,

        case
            when sma_10d > sma_20d then 1
            else 0
        end as sma10_above_sma20_flag,    

        case
            when sma_20d > sma_50d then 1
            else 0
        end as sma20_above_sma50_flag,

        case
            when prev_sma_10d <= prev_sma_20d
             and sma_10d > sma_20d then 1
            else 0
        end as bullish_sma10_sma20_cross,

        case
            when prev_sma_10d >= prev_sma_20d
             and sma_10d < sma_20d then 1
            else 0
        end as bearish_sma10_sma20_cross,

        case
            when prev_sma_20d <= prev_sma_50d
             and sma_20d > sma_50d then 1
            else 0
        end as bullish_sma20_sma50_cross,

        case
            when prev_sma_20d >= prev_sma_50d
             and sma_20d < sma_50d then 1
            else 0
        end as bearish_sma20_sma50_cross,

        case
            when return_21d > 0 and avg_return_5d > 0 then 1
            else 0
        end as momentum_confirmed_flag,

        case
            when return_21d < 0 and avg_return_5d < 0 then 1
            else 0
        end as downside_momentum_flag,

        case
            when price_to_sma20_pct > 0.05 then 1
            else 0
        end as extended_above_sma20_flag,

        case
            when price_to_sma20_pct < -0.05 then 1
            else 0
        end as extended_below_sma20_flag

    from signal_prep
    
)

SELECT * FROM final
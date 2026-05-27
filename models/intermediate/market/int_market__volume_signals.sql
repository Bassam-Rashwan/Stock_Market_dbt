{{ config(
    materialized = 'table',
    schema = 'intermediate',
    tags = ['intermediate', 'market', 'volume']
) }}

with base as (

    select
        ticker,
        trade_date,
        adj_close,
        volume,
        daily_return
    from {{ ref('int_market__daily_returns') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['ticker', 'trade_date']) }} as volume_signal_sk,
        ticker,
        trade_date,
        volume,
        adj_close,
        daily_return,

        -- rolling average volume
        avg(volume) over (
            partition by ticker
            order by trade_date
            rows between 9 preceding and current row
        ) as avg_volume_10d,

        avg(volume) over (
            partition by ticker
            order by trade_date
            rows between 19 preceding and current row
        ) as avg_volume_20d,

        -- relative volume vs 20d avg
        volume / nullif(
            avg(volume) over (
                partition by ticker
                order by trade_date
                rows between 19 preceding and current row
            ), 0
        ) as relative_volume_20d,

        -- volume spike flag (>2x 20-day avg)
        case
            when volume > 2 * avg(volume) over (
                partition by ticker
                order by trade_date
                rows between 19 preceding and current row
            ) then 1
            else 0
        end as volume_spike_flag,

        -- volume trend
        avg(volume) over (
            partition by ticker
            order by trade_date
            rows between 4 preceding and current row
        ) / nullif(
            avg(volume) over (
                partition by ticker
                order by trade_date
                rows between 19 preceding and current row
            ), 0
        ) - 1 as volume_trend_5d_vs_20d,

        -- price-volume confirmation flags
        case
            when daily_return > 0
             and volume > avg(volume) over (
                    partition by ticker
                    order by trade_date
                    rows between 19 preceding and current row
                )
            then 1
            else 0
        end as bullish_volume_confirmation,

        case
            when daily_return < 0
             and volume > avg(volume) over (
                    partition by ticker
                    order by trade_date
                    rows between 19 preceding and current row
                )
            then 1
            else 0
        end as bearish_volume_confirmation,

        -- dollar volume
        adj_close * volume as dollar_volume

    from base

)

select *
from final
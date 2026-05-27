{{ config(
    materialized = 'table',
    tags = ['mart', 'equity', 'bi']
) }}

with latest_daily as (

    select
        *,
        row_number() over (
            partition by ticker
            order by trade_date desc
        ) as row_num
    from {{ ref('mart_equity__daily_market') }}

),

latest as (

    select *
    from latest_daily
    where row_num = 1

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['latest.ticker']) }} as latest_snapshot_sk,
        latest.ticker,
        latest.trade_date as latest_trade_date,

        meta.company_name,
        meta.industry,

        latest.adj_close as latest_adj_close,
        latest.daily_return as return_1d,
        latest.return_21d,
        latest.volatility_21d,
        latest.price_trend_regime,

        latest.volume,
        latest.avg_volume_20d,
        latest.relative_volume_20d,
        latest.volume_spike_flag,

        latest.sma10_above_sma20_flag,
        latest.sma20_above_sma50_flag,
        latest.momentum_confirmed_flag,
        latest.downside_momentum_flag,
        latest.bullish_volume_confirmation,
        latest.bearish_volume_confirmation

    from latest
    left join {{ ref('stg_meta__ticker_name') }} as meta
        on latest.ticker = meta.ticker

)

select *
from final

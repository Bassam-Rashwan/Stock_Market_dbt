{{ config(
    materialized = 'table',
    tags = ['mart', 'equity', 'bi']
) }}

with technical as (

    select
        ticker,
        trade_date,
        adj_close,
        daily_return,
        return_21d,
        volatility_21d,
        price_trend_regime,
        sma10_above_sma20_flag,
        sma20_above_sma50_flag,
        bullish_sma10_sma20_cross,
        bearish_sma10_sma20_cross,
        bullish_sma20_sma50_cross,
        bearish_sma20_sma50_cross,
        momentum_confirmed_flag,
        downside_momentum_flag,
        extended_above_sma20_flag,
        extended_below_sma20_flag
    from {{ ref('int_market__technical_signals') }}

),

volume as (

    select
        ticker,
        trade_date,
        volume,
        avg_volume_20d,
        relative_volume_20d,
        volume_spike_flag,
        volume_trend_5d_vs_20d,
        bullish_volume_confirmation,
        bearish_volume_confirmation,
        dollar_volume
    from {{ ref('int_market__volume_signals') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['technical.ticker', 'technical.trade_date']) }}
            as daily_market_sk,
        technical.ticker,
        technical.trade_date,

        technical.adj_close,
        technical.daily_return,
        technical.return_21d,
        technical.volatility_21d,

        volume.volume,
        volume.avg_volume_20d,
        volume.relative_volume_20d,
        volume.volume_spike_flag,
        volume.volume_trend_5d_vs_20d,
        volume.bullish_volume_confirmation,
        volume.bearish_volume_confirmation,
        volume.dollar_volume,

        technical.price_trend_regime,
        technical.sma10_above_sma20_flag,
        technical.sma20_above_sma50_flag,
        technical.bullish_sma10_sma20_cross,
        technical.bearish_sma10_sma20_cross,
        technical.bullish_sma20_sma50_cross,
        technical.bearish_sma20_sma50_cross,
        technical.momentum_confirmed_flag,
        technical.downside_momentum_flag,
        technical.extended_above_sma20_flag,
        technical.extended_below_sma20_flag

    from technical
    inner join volume
        on technical.ticker = volume.ticker
       and technical.trade_date = volume.trade_date

)

select *
from final

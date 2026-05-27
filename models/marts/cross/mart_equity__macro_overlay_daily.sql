{{ config(
    materialized = 'table',
    tags = ['mart', 'equity', 'macro', 'bi']
) }}

with equity as (

    select *
    from {{ ref('mart_equity__daily_market') }}

),

mapped as (

    select
        equity.*,
        map.cot_market_code
    from equity
    inner join {{ ref('int_macro__cot_equity_map') }} as map
        on equity.ticker = map.ticker

),

cot as (

    select *
    from {{ ref('mart_macro__cot_weekly') }}

),

as_of_join as (

    select
        mapped.*,
        cot.report_date as cot_report_date,
        cot.market_name as cot_market_name,
        cot.cot_asset_class,
        cot.commercial_net_pct_oi as cot_commercial_net_pct_oi,
        cot.noncommercial_net_pct_oi as cot_noncommercial_net_pct_oi,
        cot.noncommercial_cot_index_52w,
        cot.commercial_cot_index_52w,
        cot.noncommercial_cot_regime_52w,
        cot.commercial_cot_regime_52w,
        cot.noncommercial_zscore_regime_52w,
        cot.commercial_zscore_regime_52w,
        cot.open_interest as cot_open_interest,
        cot.noncommercial_net_pct_oi_wow_change as cot_noncommercial_net_pct_oi_wow_change,
        row_number() over (
            partition by mapped.ticker, mapped.trade_date
            order by cot.report_date desc
        ) as cot_match_rank
    from mapped
    inner join cot
        on mapped.cot_market_code = cot.cot_market_code
       and cot.report_date <= mapped.trade_date

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['ticker', 'trade_date']) }}
            as macro_overlay_daily_sk,
        ticker,
        trade_date,
        cot_market_code,
        cot_report_date,

        adj_close,
        daily_return,
        return_21d,
        volatility_21d,
        price_trend_regime,
        volume,
        relative_volume_20d,
        volume_spike_flag,
        momentum_confirmed_flag,
        downside_momentum_flag,

        cot_market_name,
        cot_asset_class,
        cot_commercial_net_pct_oi,
        cot_noncommercial_net_pct_oi,
        noncommercial_cot_index_52w,
        commercial_cot_index_52w,
        noncommercial_cot_regime_52w,
        commercial_cot_regime_52w,
        noncommercial_zscore_regime_52w,
        commercial_zscore_regime_52w,
        cot_open_interest,
        cot_noncommercial_net_pct_oi_wow_change

    from as_of_join
    where cot_match_rank = 1

)

select *
from final

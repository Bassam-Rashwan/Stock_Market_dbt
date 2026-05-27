{{ config(
    materialized = 'table',
    schema = 'intermediate',
    tags = ['intermediate', 'macro', 'cot']
) }}

with base as (

    select
        cot_sk,
        market_name,
        report_date,
        cot_asset_class,
        cot_market_code,

        commercial_long,
        commercial_short,
        commercial_net,

        noncommercial_long,
        noncommercial_short,
        noncommercial_net,

        nonreportable_long,
        nonreportable_short,
        nonreportable_net,

        open_interest,

        commercial_long_pct_oi,
        commercial_short_pct_oi,
        commercial_net_pct_oi,

        noncommercial_long_pct_oi,
        noncommercial_short_pct_oi,
        noncommercial_net_pct_oi,

        nonreportable_long_pct_oi,
        nonreportable_short_pct_oi,
        nonreportable_net_pct_oi,

        commercial_net_wow_change,
        noncommercial_net_wow_change,
        nonreportable_net_wow_change,

        commercial_net_pct_oi_wow_change,
        noncommercial_net_pct_oi_wow_change,
        nonreportable_net_pct_oi_wow_change,

        spec_vs_hedger_net_spread,
        spec_vs_hedger_net_spread_pct_oi,
        noncommercial_directional_bias_pct_oi,
        commercial_directional_bias_pct_oi,
        open_interest_wow_change,
        open_interest_wow_pct_change,

        noncommercial_net_pct_oi_52w_min,
        noncommercial_net_pct_oi_52w_max,
        commercial_net_pct_oi_52w_min,
        commercial_net_pct_oi_52w_max,

        noncommercial_net_pct_oi_52w_avg,
        noncommercial_net_pct_oi_52w_std,
        commercial_net_pct_oi_52w_avg,
        commercial_net_pct_oi_52w_std,

        noncommercial_net_pct_oi_full_sample_percentile,
        commercial_net_pct_oi_full_sample_percentile,

        noncommercial_cot_index_52w,
        commercial_cot_index_52w,

        noncommercial_net_pct_oi_zscore_52w,
        commercial_net_pct_oi_zscore_52w,

        loaded_at

    from {{ ref('int_macro__cot_zscores') }}

),

final as (

    select
        *,

        case
            when noncommercial_cot_index_52w >= 0.80 then 'extreme_long'
            when noncommercial_cot_index_52w <= 0.20 then 'extreme_short'
            else 'neutral'
        end as noncommercial_cot_regime_52w,

        case
            when commercial_cot_index_52w >= 0.80 then 'extreme_long'
            when commercial_cot_index_52w <= 0.20 then 'extreme_short'
            else 'neutral'
        end as commercial_cot_regime_52w,

        case
            when noncommercial_net_pct_oi_zscore_52w >= 2 then 'extreme_long'
            when noncommercial_net_pct_oi_zscore_52w <= -2 then 'extreme_short'
            else 'neutral'
        end as noncommercial_zscore_regime_52w,

        case
            when commercial_net_pct_oi_zscore_52w >= 2 then 'extreme_long'
            when commercial_net_pct_oi_zscore_52w <= -2 then 'extreme_short'
            else 'neutral'
        end as commercial_zscore_regime_52w

    from base

)

select *
from final
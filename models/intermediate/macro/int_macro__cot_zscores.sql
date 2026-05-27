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

        loaded_at

    from {{ ref('int_macro__cot_positioning') }}

),

normalized as (

    select
        *,

        min(noncommercial_net_pct_oi) over (
            partition by market_name
            order by report_date
            rows between 51 preceding and current row
        ) as noncommercial_net_pct_oi_52w_min,

        max(noncommercial_net_pct_oi) over (
            partition by market_name
            order by report_date
            rows between 51 preceding and current row
        ) as noncommercial_net_pct_oi_52w_max,

        min(commercial_net_pct_oi) over (
            partition by market_name
            order by report_date
            rows between 51 preceding and current row
        ) as commercial_net_pct_oi_52w_min,

        max(commercial_net_pct_oi) over (
            partition by market_name
            order by report_date
            rows between 51 preceding and current row
        ) as commercial_net_pct_oi_52w_max,

        avg(noncommercial_net_pct_oi) over (
            partition by market_name
            order by report_date
            rows between 51 preceding and current row
        ) as noncommercial_net_pct_oi_52w_avg,

        stddev_samp(noncommercial_net_pct_oi) over (
            partition by market_name
            order by report_date
            rows between 51 preceding and current row
        ) as noncommercial_net_pct_oi_52w_std,

        avg(commercial_net_pct_oi) over (
            partition by market_name
            order by report_date
            rows between 51 preceding and current row
        ) as commercial_net_pct_oi_52w_avg,

        stddev_samp(commercial_net_pct_oi) over (
            partition by market_name
            order by report_date
            rows between 51 preceding and current row
        ) as commercial_net_pct_oi_52w_std,

        percent_rank() over (
            partition by market_name
            order by noncommercial_net_pct_oi
        ) as noncommercial_net_pct_oi_full_sample_percentile,

        percent_rank() over (
            partition by market_name
            order by commercial_net_pct_oi
        ) as commercial_net_pct_oi_full_sample_percentile

    from base

),

final as (

    select
        *,

        case
            when noncommercial_net_pct_oi_52w_max = noncommercial_net_pct_oi_52w_min
                then null
            else (
                noncommercial_net_pct_oi - noncommercial_net_pct_oi_52w_min
            ) / nullif(
                noncommercial_net_pct_oi_52w_max - noncommercial_net_pct_oi_52w_min,
                0
            )
        end as noncommercial_cot_index_52w,

        case
            when commercial_net_pct_oi_52w_max = commercial_net_pct_oi_52w_min
                then null
            else (
                commercial_net_pct_oi - commercial_net_pct_oi_52w_min
            ) / nullif(
                commercial_net_pct_oi_52w_max - commercial_net_pct_oi_52w_min,
                0
            )
        end as commercial_cot_index_52w,

        case
            when noncommercial_net_pct_oi_52w_std is null
              or noncommercial_net_pct_oi_52w_std = 0
                then null
            else (
                noncommercial_net_pct_oi - noncommercial_net_pct_oi_52w_avg
            ) / noncommercial_net_pct_oi_52w_std
        end as noncommercial_net_pct_oi_zscore_52w,

        case
            when commercial_net_pct_oi_52w_std is null
              or commercial_net_pct_oi_52w_std = 0
                then null
            else (
                commercial_net_pct_oi - commercial_net_pct_oi_52w_avg
            ) / commercial_net_pct_oi_52w_std
        end as commercial_net_pct_oi_zscore_52w

    from normalized

)

select *
from final
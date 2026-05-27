{{ config(
    materialized = 'table',
    tags = ['mart', 'macro', 'bi']
) }}

with source as (

    select *
    from {{ ref('int_macro__cot_regime_flags') }}

),

deduped as (

    select *
    from (
        select
            *,
            row_number() over (
                partition by cot_market_code, report_date
                order by loaded_at desc, market_name
            ) as row_num
        from source
    ) ranked
    where row_num = 1

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['cot_market_code', 'report_date']) }}
            as cot_weekly_sk,
        cot_market_code,
        market_name,
        cot_asset_class,
        report_date,

        commercial_net_pct_oi,
        noncommercial_net_pct_oi,
        nonreportable_net_pct_oi,

        noncommercial_cot_index_52w,
        commercial_cot_index_52w,

        noncommercial_cot_regime_52w,
        commercial_cot_regime_52w,
        noncommercial_zscore_regime_52w,
        commercial_zscore_regime_52w,

        open_interest,

        commercial_net_wow_change,
        noncommercial_net_wow_change,
        nonreportable_net_wow_change,
        commercial_net_pct_oi_wow_change,
        noncommercial_net_pct_oi_wow_change,
        open_interest_wow_change,
        open_interest_wow_pct_change

    from deduped

)

select *
from final

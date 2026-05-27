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
        cot_asset_class ::varchar,
        cot_market_code ::varchar,

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
        loaded_at ::timestamp

    from {{ ref('int_macro__cot_markets') }}

),

positioning as (

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

        commercial_long::float / nullif(open_interest, 0)       as commercial_long_pct_oi,
        commercial_short::float / nullif(open_interest, 0)      as commercial_short_pct_oi,
        commercial_net::float / nullif(open_interest, 0)        as commercial_net_pct_oi,

        noncommercial_long::float / nullif(open_interest, 0)    as noncommercial_long_pct_oi,
        noncommercial_short::float / nullif(open_interest, 0)   as noncommercial_short_pct_oi,
        noncommercial_net::float / nullif(open_interest, 0)     as noncommercial_net_pct_oi,

        nonreportable_long::float / nullif(open_interest, 0)    as nonreportable_long_pct_oi,
        nonreportable_short::float / nullif(open_interest, 0)   as nonreportable_short_pct_oi,
        nonreportable_net::float / nullif(open_interest, 0)     as nonreportable_net_pct_oi,

        commercial_net
            - lag(commercial_net) over (
                partition by market_name
                order by report_date
            )                                                   as commercial_net_wow_change,

        noncommercial_net
            - lag(noncommercial_net) over (
                partition by market_name
                order by report_date
            )                                                   as noncommercial_net_wow_change,

        nonreportable_net
            - lag(nonreportable_net) over (
                partition by market_name
                order by report_date
            )                                                   as nonreportable_net_wow_change,

        (
            commercial_net::float / nullif(open_interest, 0)
            - lag(commercial_net::float / nullif(open_interest, 0)) over (
                partition by market_name
                order by report_date
            )
        )                                                       as commercial_net_pct_oi_wow_change,

        (
            noncommercial_net::float / nullif(open_interest, 0)
            - lag(noncommercial_net::float / nullif(open_interest, 0)) over (
                partition by market_name
                order by report_date
            )
        )                                                       as noncommercial_net_pct_oi_wow_change,

        (
            nonreportable_net::float / nullif(open_interest, 0)
            - lag(nonreportable_net::float / nullif(open_interest, 0)) over (
                partition by market_name
                order by report_date
            )
        )                                                       as nonreportable_net_pct_oi_wow_change,

        (noncommercial_net - commercial_net)                    as spec_vs_hedger_net_spread,
        (noncommercial_net::float / nullif(open_interest, 0))
            - (commercial_net::float / nullif(open_interest, 0))
                                                                as spec_vs_hedger_net_spread_pct_oi,

        (noncommercial_long::float / nullif(open_interest, 0))
            - (noncommercial_short::float / nullif(open_interest, 0))
                                                                as noncommercial_directional_bias_pct_oi,

        (commercial_long::float / nullif(open_interest, 0))
            - (commercial_short::float / nullif(open_interest, 0))
                                                                as commercial_directional_bias_pct_oi,

        open_interest
            - lag(open_interest) over (
                partition by market_name
                order by report_date
            )                                                   as open_interest_wow_change,

        (
            open_interest
            - lag(open_interest) over (
                partition by market_name
                order by report_date
            )
        )::float
        / nullif(
            lag(open_interest) over (
                partition by market_name
                order by report_date
            ),
            0
        )                                                       as open_interest_wow_pct_change,

        loaded_at::timestamp

    from base

)

select *
from positioning
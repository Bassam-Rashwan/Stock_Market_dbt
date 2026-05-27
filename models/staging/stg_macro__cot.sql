{{ config(
    materialized = 'view',
    schema = 'staging',
    tags = ['staging', 'macro', 'cot']
) }}

select
    {{ dbt_utils.generate_surrogate_key(['"Market and Exchange Names"', '"As of Date in Form YYMMDD"']) }}
                                                    as cot_sk,

    -- identifiers
    "Market and Exchange Names"::varchar            as market_name,
    "As of Date in Form YYYY-MM-DD"::date as report_date,

    -- commercial (hedger) positions
    "Commercial Positions-Long (All)"::bigint              as commercial_long,
    "Commercial Positions-Short (All)"::bigint             as commercial_short,
    ("Commercial Positions-Long (All)"
     - "Commercial Positions-Short (All)")::bigint         as commercial_net,

    -- non-commercial (speculator) positions
    "Noncommercial Positions-Long (All)"::bigint           as noncommercial_long,
    "Noncommercial Positions-Short (All)"::bigint          as noncommercial_short,
    ("Noncommercial Positions-Long (All)"
     - "Noncommercial Positions-Short (All)")::bigint      as noncommercial_net,

    -- non-reportable (small trader) positions
    "Nonreportable Positions-Long (All)"::bigint           as nonreportable_long,
    "Nonreportable Positions-Short (All)"::bigint          as nonreportable_short,
    ("Nonreportable Positions-Long (All)"
     - "Nonreportable Positions-Short (All)")::bigint      as nonreportable_net,

    --Total Positions,               open interest
    "Open Interest (All)"::bigint                    as open_interest,

    -- audit
    current_timestamp ::timestamp                              as loaded_at

from {{ source('raw', 'COT') }}
where "Market and Exchange Names" is not null
  and "As of Date in Form YYMMDD" is not null
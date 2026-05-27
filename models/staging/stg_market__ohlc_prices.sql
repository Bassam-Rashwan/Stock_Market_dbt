{{ config(
    materialized = 'view',
    schema       = 'staging',
    tags         = ['staging', 'market']
) }}

select
    {{ dbt_utils.generate_surrogate_key(['"Ticker"', '"Date"']) }} as ohlc_sk,

    -- identifiers
        CASE WHEN "Ticker" LIKE 'BRK%' THEN REPLACE("Ticker", 'BRK-', 'BRK.')
        ELSE "Ticker" END ::varchar as ticker,
    "Date"::date                           as trade_date,

    -- prices
    "Open"::numeric                        as open,
    "High"::numeric                        as high,
    "Low"::numeric                         as low,
    "Close"::numeric                       as close,
    "Adj Close"::numeric                   as adj_close,

    -- volume
    "Volume"::bigint                       as volume,

    -- audit
    current_timestamp::timestamp                      as loaded_at
from {{ source('raw', 'Daily_Prices') }}
where "Ticker" is not null
  and "Date" is not null
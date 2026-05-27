{{ config(
    materialized = 'view',
    schema = 'staging',
    tags = ['staging', 'reference']
) }}

select
    "Ticker"::varchar as ticker,
    "Stock_Name"::varchar as company_name,
    "Industry"::varchar as industry,
    current_timestamp as loaded_at,
    'raw_tickers' as source
from {{ source('raw', 'TickerName') }}
where "Ticker" is not null
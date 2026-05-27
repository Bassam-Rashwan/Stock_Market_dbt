{{ 
    config(
    materialized = 'view',
    schema = 'staging',
    tags = ['staging', 'ratios', 'value']
) }}

select
    "Ticker"::varchar                 as ticker,
    "Date"::date                    as fiscal_date,
    "PB Ratio"::numeric             as pb_ratio,
    "Stock Price"::numeric          as stock_price,
    "Book Value per Share"::numeric          as book_value_per_share
from {{ source('raw', 'PB_Ratio') }}
where "Ticker" is not null
  and "Date" is not null
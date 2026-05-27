{{ 
    config(
    materialized = 'view',
    schema = 'staging',
    tags = ['staging', 'ratios', 'value']
) }}

select
    "Ticker"::varchar                 as ticker,
    "Date"::date                    as fiscal_date,
    "PS Ratio"::numeric             as ps_ratio,
    "Stock Price"::numeric          as stock_price,
    "TTM Sales per Share"::numeric          as sales_per_share_ttm
from {{ source('raw', 'PS_Ratio') }}
where "Ticker" is not null
  and "Date" is not null
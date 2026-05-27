{{ 
    config(
    materialized = 'view',
    schema = 'staging',
    tags = ['staging', 'ratios', 'value']
) }}

select
    "Ticker"::varchar                 as ticker,
    "Date"::date                    as fiscal_date,
    "Price/FCF"::numeric             as p_fcf_ratio,
    "Stock Price"::numeric          as stock_price,
    "TTM FCF per Share"::numeric          as fcf_per_share_ttm
from {{ source('raw', 'Price_FCF_Ratio') }}
where "Ticker" is not null
  and "Date" is not null
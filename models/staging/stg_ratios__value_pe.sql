{{ config(
    materialized = 'view',
    schema = 'staging',
    tags = ['staging', 'ratios', 'value']
) }}

select
    "Ticker"::varchar                 as ticker,
    "Date"::date                    as fiscal_date,
    "PE Ratio"::numeric             as pe_ratio,
    "Stock Price"::numeric          as stock_price,
    "TTM Net EPS"::numeric          as net_eps_ttm
from {{ source('raw', 'PE_Ratio') }}
where "Ticker" is not null
  and "Date" is not null
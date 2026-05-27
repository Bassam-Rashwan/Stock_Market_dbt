{{
    config(
        materialized = 'view',
        schema = 'staging',
        tags = ['staging', 'ratios', 'quality']

    )
}}

select
    "Ticker"::varchar                         as ticker,
    "Date"::date                            as fiscal_date,
    "Return on Assets"::numeric             as roa,
    "TTM Net Income"::numeric               as net_income_ttm,
    "Total Assets"::numeric                 as total_assets
from {{ source('raw', 'ROA') }}
where "Ticker" is not null
  and "Date" is not null
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
    "Return on Equity"::numeric             as roe,
    "TTM Net Income"::numeric               as net_income_ttm,
    "Shareholder Equity"::numeric                 as total_equity
from {{ source('raw', 'ROE') }}
where "Ticker" is not null
  and "Date" is not null
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
    "Return on Investment"::numeric             as roi,
    "TTM Net Income"::numeric               as net_income_ttm,
    "LT Investments & Debt"::numeric                 as LT_investments_debt
from {{ source('raw', 'ROI') }}
where "Ticker" is not null
  and "Date" is not null
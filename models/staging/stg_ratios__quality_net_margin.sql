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
    "Net Profit Margin"::numeric             as net_profit_margin,
    "TTM Net Income"::numeric               as net_income_ttm,
    "TTM Revenue"::numeric                 as revenue_ttm
from {{ source('raw', 'Net_Profit_Margin') }}
where "Ticker" is not null
  and "Date" is not null
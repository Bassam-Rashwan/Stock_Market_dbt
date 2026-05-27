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
    "Operating Margin"::numeric             as op_margin,
    "TTM Operating Income"::numeric               as op_income_ttm,
    "TTM Revenue"::numeric                 as revenue_ttm
from {{ source('raw', 'Operating_Margin') }}
where "Ticker" is not null
  and "Date" is not null
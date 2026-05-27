{{ config(
    materialized = 'table',
    schema = 'intermediate',
    tags = ['intermediate', 'ratios', 'value']
) }}

with base as (

    select ticker, fiscal_date from {{ ref('stg_ratios__value_pe') }}
    union
    select ticker, fiscal_date from {{ ref('stg_ratios__value_ps') }}
    union
    select ticker, fiscal_date from {{ ref('stg_ratios__value_pb') }}
    union
    select ticker, fiscal_date from {{ ref('stg_ratios__value_price_fcf') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['base.ticker', 'base.fiscal_date']) }} as value_ratios_sk,
        base.ticker,
        base.fiscal_date,

        pe.pe_ratio,
        ps.ps_ratio,
        pb.pb_ratio,
        pfcf.p_fcf_ratio,

        pe.stock_price as pe_stock_price,
        pe.net_eps_ttm as pe_net_eps_ttm,

        ps.sales_per_share_ttm as ps_sales_per_share_ttm,
        ps.stock_price as ps_stock_price,

        pb.stock_price as pb_stock_price,
        pb.book_value_per_share as pb_book_value_per_share,

        pfcf.stock_price as pfcf_stock_price,
        pfcf.fcf_per_share_ttm as pfcf_fcf_per_share_ttm

    from base
    left join {{ ref('stg_ratios__value_pe') }} pe
        on base.ticker = pe.ticker
       and base.fiscal_date = pe.fiscal_date
    left join {{ ref('stg_ratios__value_ps') }} ps
        on base.ticker = ps.ticker
       and base.fiscal_date = ps.fiscal_date
    left join {{ ref('stg_ratios__value_pb') }} pb
        on base.ticker = pb.ticker
       and base.fiscal_date = pb.fiscal_date
    left join {{ ref('stg_ratios__value_price_fcf') }} pfcf
        on base.ticker = pfcf.ticker
       and base.fiscal_date = pfcf.fiscal_date

)

select *
from final
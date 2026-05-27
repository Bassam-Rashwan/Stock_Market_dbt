{{ config(
    materialized = 'table',
    schema = 'intermediate',
    tags = ['intermediate', 'ratios', 'quality']
) }}

WITH base AS (
    SELECT ticker, fiscal_date FROM {{ ref('stg_ratios__quality_roa') }}
    UNION
    SELECT ticker, fiscal_date FROM {{ ref('stg_ratios__quality_roe') }}
    UNION
    SELECT ticker, fiscal_date FROM {{ ref('stg_ratios__quality_roi') }}
    UNION
    SELECT ticker, fiscal_date FROM {{ ref('stg_ratios__quality_op_margin') }}
    UNION
    SELECT ticker, fiscal_date FROM {{ ref('stg_ratios__quality_net_margin') }}
),
final AS (
    SELECT
        {{dbt_utils.generate_surrogate_key(['base.ticker', 'base.fiscal_date'])}} as quality_ratios_sk,
        base.ticker,
        base.fiscal_date,
        roa.roa,
        roe.roe,
        roi.roi,
        opm.op_margin,
        npm.net_profit_margin,
        roa.net_income_ttm as roa_net_income_ttm,
        roa.total_assets as roa_total_assets,
        roe.total_equity as roe_total_equity,
        roi.lt_investments_debt as roi_lt_investments_debt,
        opm.op_income_ttm as op_income_ttm,
        opm.revenue_ttm as op_revenue_ttm
    
    FROM base
    
    left join {{ ref('stg_ratios__quality_roa') }} roa
        on base.ticker = roa.ticker
       and base.fiscal_date = roa.fiscal_date
    left join {{ ref('stg_ratios__quality_roe') }} roe
        on base.ticker = roe.ticker
       and base.fiscal_date = roe.fiscal_date
    left join {{ ref('stg_ratios__quality_roi') }} roi
        on base.ticker = roi.ticker
       and base.fiscal_date = roi.fiscal_date
    left join {{ ref('stg_ratios__quality_op_margin') }} opm
        on base.ticker = opm.ticker
       and base.fiscal_date = opm.fiscal_date
    left join {{ ref('stg_ratios__quality_net_margin') }} npm
        on base.ticker = npm.ticker
       and base.fiscal_date = npm.fiscal_date

)

select *
from final
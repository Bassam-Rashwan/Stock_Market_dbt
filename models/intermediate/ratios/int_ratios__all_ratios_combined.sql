{{
    config(
        materialized = 'table',
        schema = 'intermediate',
        tags = ['intermediate', 'ratios', 'combined']
    )
}}

WITH quality AS (
    SELECT * FROM {{ ref('int_ratios__quality_unified') }}
),
value AS (
    SELECT * FROM {{ ref('int_ratios__value_unified') }}
        ),
final AS (

    SELECT
        {{dbt_utils.generate_surrogate_key([
            "COALESCE(quality.ticker, value.ticker)",
            "COALESCE(quality.fiscal_date, value.fiscal_date)"
        ]) }} AS all_ratios_sk,
        COALESCE(quality.ticker, value.ticker) AS ticker,
        COALESCE(quality.fiscal_date, value.fiscal_date) AS fiscal_date,

        -- Quality ratios
        quality.roa,
        quality.roe,
        quality.roi,
        quality.op_margin,
        quality.net_profit_margin,
        quality.roa_net_income_ttm,
        quality.roa_total_assets,
        quality.roe_total_equity,
        quality.roi_lt_investments_debt,
        quality.op_income_ttm,
        quality.op_revenue_ttm,

        -- Value ratios
        value.pe_ratio,
        value.ps_ratio,
        value.pb_ratio,
        value.p_fcf_ratio,
        value.pb_book_value_per_share,
        value.pe_net_eps_ttm,
        value.ps_sales_per_share_ttm,
        value.pfcf_fcf_per_share_ttm

    from quality
    full outer join value
        on quality.ticker = value.ticker
       and quality.fiscal_date = value.fiscal_date
)

select *
from final
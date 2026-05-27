{{
    config (
        materialized = 'table',
        schema = 'intermediate',
        tags = ['intermediate', 'ratios', 'growth']
    )
}}

WITH base AS (
    SELECT * FROM {{ ref('int_ratios__all_ratios_combined') }} 
),
final AS(
    SELECT
    {{dbt_utils.generate_surrogate_key(['ticker', 'fiscal_date'])}} as ratio_growth_sk,
    ticker,
    fiscal_date,
    -- base ratios
        roa,
        roe,
        roi,
        op_margin,
        net_profit_margin,
        pe_ratio,
        ps_ratio,
        pb_ratio,
        p_fcf_ratio,   

        -- QoQ growth
        {{ qoq_growth('roa') }} as roa_qoq_growth,
        {{ qoq_growth('roe') }} as roe_qoq_growth,
        {{ qoq_growth('roi') }} as roi_qoq_growth,
        {{ qoq_growth('op_margin') }} as op_margin_qoq_growth,
        {{ qoq_growth('net_profit_margin') }} as net_profit_margin_qoq_growth,

        {{ qoq_growth('pe_ratio') }} as pe_ratio_qoq_growth,
        {{ qoq_growth('ps_ratio') }} as ps_ratio_qoq_growth,
        {{ qoq_growth('pb_ratio') }} as pb_ratio_qoq_growth,
        {{ qoq_growth('p_fcf_ratio') }} as p_fcf_ratio_qoq_growth

    from base
)

SELECT * FROM final
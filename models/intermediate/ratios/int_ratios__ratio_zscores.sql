{{
    config(
        materialized = 'table',
        schema = 'intermediate',
        tags = ['intermediate', 'ratios', 'zscores']
    )
}}

WITH base AS(
    SELECT * FROM {{ ref('int_ratios__all_ratios_combined')}}
),

cross_sectional_stats  AS(

    SELECT
    fiscal_date,  --we will select the fiscal date only to groub by date not by stock, so we get the mean and stddev for each quarter for these stocks
    --Quality ratios Average
    avg(roa) as roa_mean,
    avg(roe) as roe_mean,
    avg(roi) as roi_mean,
    avg(op_margin) as op_margin_mean,
    avg(net_profit_margin) as net_profit_margin_mean,

    --Quality ratios Standard Deviation
    nullif(stddev(roa), 0) as roa_std,
    nullif(stddev(roe), 0) as roe_std,
    nullif(stddev(roi), 0) as roi_std,
    nullif(stddev(op_margin), 0) as op_margin_std,
    nullif(stddev(net_profit_margin), 0) as net_profit_margin_std,

    --Value ratios Average
    avg(pe_ratio) as pe_ratio_mean,
    avg(ps_ratio) as ps_ratio_mean,
    avg(pb_ratio) as pb_ratio_mean,
    avg(p_fcf_ratio) as p_fcf_ratio_mean,

    --Value ratios Standard Deviation
    nullif(stddev(pe_ratio), 0) as pe_ratio_std,
    nullif(stddev(ps_ratio), 0) as ps_ratio_std,
    nullif(stddev(pb_ratio), 0) as pb_ratio_std,
    nullif(stddev(p_fcf_ratio), 0) as p_fcf_ratio_std

    from base
    group by fiscal_date
),

final AS(
    SELECT
    {{dbt_utils.generate_surrogate_key(['base.ticker', 'base.fiscal_date'])}} as ratio_zscore_sk,
    base.ticker,
    base.fiscal_date,

    -- quality z-scores (higher is better → standard z-score)
    (base.roa - s.roa_mean) / roa_std AS roa_zscore ,
    (base.roe - s.roe_mean) / roe_std AS roe_zscore,
    (base.roi - s.roi_mean) / roi_std AS roi_zscore,
    (base.op_margin - s.op_margin_mean) / s.op_margin_std  AS op_margin_zscore,
    (base.net_profit_margin - s.net_profit_margin_mean)/ s.net_profit_margin_std  AS net_profit_margin_zscore,

        -- value z-scores (lower multiple is better → negate after z-scoring)
    -1 * (base.pe_ratio - s.pe_ratio_mean) / s.pe_ratio_std         as pe_ratio_zscore,
    -1 * (base.ps_ratio - s.ps_ratio_mean) / s.ps_ratio_std         as ps_ratio_zscore,
    -1 * (base.pb_ratio - s.pb_ratio_mean) / s.pb_ratio_std         as pb_ratio_zscore,
    -1 * (base.p_fcf_ratio - s.p_fcf_ratio_mean) / s.p_fcf_ratio_std as p_fcf_ratio_zscore

    FROM base
    inner join cross_sectional_stats s
    ON base.fiscal_date = s.fiscal_date

)

SELECT * FROM final


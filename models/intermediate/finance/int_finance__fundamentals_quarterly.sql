{{ config(
    materialized = 'table',
    schema = 'intermediate',
    tags = ['intermediate', 'finance', 'fundamentals']
) }}

WITH fundamentals AS(
    SELECT
        ticker,
        fiscal_date,
        metric_name,
        value
    FROM {{ ref('stg_finance__fundamentals') }}
    WHERE period_type = 'quarterly'
),
pivoted as (

    select
        {{ dbt_utils.generate_surrogate_key(['ticker', 'fiscal_date']) }} as fundamentals_quarterly_sk,
        ticker,
        fiscal_date,

        max(case when metric_name = 'revenue' then value end) as revenue,
        max(case when metric_name = 'gross_profit' then value end) as gross_profit,
        max(case when metric_name = 'operating_income' then value end) as operating_income,
        max(case when metric_name = 'net_income' then value end) as net_income,
        max(case when metric_name = 'ebitda' then value end) as ebitda,
        max(case when metric_name = 'eps_diluted' then value end) as eps_diluted,
        max(case when metric_name = 'shares_outstanding' then value end) as shares_outstanding,
        max(case when metric_name = 'rd_expense' then value end) as rd_expense,
        max(case when metric_name = 'cash_on_hand' then value end) as cash_on_hand,
        max(case when metric_name = 'total_current_assets' then value end) as total_current_assets,
        max(case when metric_name = 'total_assets' then value end) as total_assets,
        max(case when metric_name = 'total_current_liabilities' then value end) as total_current_liabilities,
        max(case when metric_name = 'total_liabilities' then value end) as total_liabilities,
        max(case when metric_name = 'long_term_debt' then value end) as long_term_debt,
        max(case when metric_name = 'shareholders_equity' then value end) as shareholders_equity,
        max(case when metric_name = 'free_cash_flow' then value end) as free_cash_flow

    from fundamentals
    group by 1, 2, 3

),

final as (

    select
        fundamentals_quarterly_sk,
        ticker,
        fiscal_date,

        revenue,
        gross_profit,
        operating_income,
        net_income,
        ebitda,
        eps_diluted,
        shares_outstanding,
        rd_expense,
        cash_on_hand,
        total_current_assets,
        total_assets,
        total_current_liabilities,
        total_liabilities,
        long_term_debt,
        shareholders_equity,
        free_cash_flow,
         -- derived features
        gross_profit / nullif(revenue, 0) as gross_margin,
        ebitda / nullif(revenue, 0) as ebitda_margin,
        total_current_assets - total_current_liabilities as working_capital,

        -- QoQ growth
        {{ qoq_growth('revenue') }} as revenue_qoq_growth,
        {{ qoq_growth('gross_profit') }} as gross_profit_qoq_growth,
        {{ qoq_growth('operating_income') }} as operating_income_qoq_growth,
        {{ qoq_growth('net_income') }} as net_income_qoq_growth,
        {{ qoq_growth('ebitda') }} as ebitda_qoq_growth,
        {{ qoq_growth('eps_diluted') }} as eps_diluted_qoq_growth,
        {{ qoq_growth('free_cash_flow') }} as free_cash_flow_qoq_growth

    from pivoted
)

select *
from final
{{ config(
    materialized = 'table',
    schema = 'intermediate',
    tags = ['intermediate', 'macro', 'cot']
) }}

with base as (

    select
        cot_sk,
        market_name,
        report_date,

        commercial_long,
        commercial_short,
        commercial_net,

        noncommercial_long,
        noncommercial_short,
        noncommercial_net,

        nonreportable_long,
        nonreportable_short,
        nonreportable_net,

        open_interest,
        loaded_at

    from {{ ref('stg_macro__cot') }}

),

normalized as (

    select
        cot_sk,
        trim(upper(market_name)) as market_name,
        report_date,

        commercial_long,
        commercial_short,
        commercial_net,

        noncommercial_long,
        noncommercial_short,
        noncommercial_net,

        nonreportable_long,
        nonreportable_short,
        nonreportable_net,

        open_interest,
        loaded_at

    from base

),

classified as (

    select
        cot_sk,
        market_name,
        report_date,

        commercial_long,
        commercial_short,
        commercial_net,

        noncommercial_long,
        noncommercial_short,
        noncommercial_net,

        nonreportable_long,
        nonreportable_short,
        nonreportable_net,

        open_interest,
        loaded_at::timestamp,

        case
            /* =========================
               EQUITY INDEX
               ========================= */
            when market_name = 'E-MINI S&P 500 - CHICAGO MERCANTILE EXCHANGE' then 'equity_index'
            when market_name = 'E-MINI NASDAQ-100 STOCK INDEX - CHICAGO MERCANTILE EXCHANGE' then 'equity_index'
            when market_name = 'DJIA X $5 - CHICAGO BOARD OF TRADE' then 'equity_index'
            when market_name = 'E-MINI RUSSELL 2000 INDEX FUTURES - CHICAGO MERCANTILE EXCHANGE' then 'equity_index'

            /* =========================
               FX
               ========================= */
            when market_name = 'EURO FX - CHICAGO MERCANTILE EXCHANGE' then 'fx'
            when market_name = 'JAPANESE YEN - CHICAGO MERCANTILE EXCHANGE' then 'fx'
            when market_name = 'BRITISH POUND - CHICAGO MERCANTILE EXCHANGE' then 'fx'
            when market_name = 'AUSTRALIAN DOLLAR - CHICAGO MERCANTILE EXCHANGE' then 'fx'
            when market_name = 'CANADIAN DOLLAR - CHICAGO MERCANTILE EXCHANGE' then 'fx'
            when market_name = 'SWISS FRANC - CHICAGO MERCANTILE EXCHANGE' then 'fx'
            when market_name = 'NZ DOLLAR - CHICAGO MERCANTILE EXCHANGE' then 'fx'
            when market_name = 'U.S. DOLLAR INDEX - ICE FUTURES U.S.' then 'fx'

            /* =========================
               RATES
               ========================= */
            when market_name = '2-YEAR U.S. TREASURY NOTES - CHICAGO BOARD OF TRADE' then 'rates'
            when market_name = '5-YEAR U.S. TREASURY NOTES - CHICAGO BOARD OF TRADE' then 'rates'
            when market_name = '10-YEAR U.S. TREASURY NOTES - CHICAGO BOARD OF TRADE' then 'rates'
            when market_name = 'ULTRA U.S. TREASURY BONDS - CHICAGO BOARD OF TRADE' then 'rates'
            when market_name = 'U.S. TREASURY BONDS - CHICAGO BOARD OF TRADE' then 'rates'

            /* =========================
               COMMODITIES
               ========================= */
            when market_name = 'WTI FINANCIAL CRUDE OIL - NEW YORK MERCANTILE EXCHANGE' then 'commodity'
            when market_name = 'CRUDE OIL, LIGHT SWEET - NEW YORK MERCANTILE EXCHANGE' then 'commodity'
            when market_name = 'GOLD - COMMODITY EXCHANGE INC.' then 'commodity'
            when market_name = 'SILVER - COMMODITY EXCHANGE INC.' then 'commodity'
            when market_name = 'NATURAL GAS - NEW YORK MERCANTILE EXCHANGE' then 'commodity'
            when market_name = 'COPPER-GRADE #1 - COMMODITY EXCHANGE INC.' then 'commodity'

            else 'other'
        end  ::varchar AS cot_asset_class ,

        case
            /* =========================
               EQUITY INDEX
               ========================= */
            when market_name = 'E-MINI S&P 500 - CHICAGO MERCANTILE EXCHANGE' then 'sp500'
            when market_name = 'E-MINI NASDAQ-100 STOCK INDEX - CHICAGO MERCANTILE EXCHANGE' then 'nasdaq100'
            when market_name = 'DJIA X $5 - CHICAGO BOARD OF TRADE' then 'dow'
            when market_name = 'E-MINI RUSSELL 2000 INDEX FUTURES - CHICAGO MERCANTILE EXCHANGE' then 'russell2000'

            /* =========================
               FX
               ========================= */
            when market_name = 'EURO FX - CHICAGO MERCANTILE EXCHANGE' then 'eurusd_proxy'
            when market_name = 'JAPANESE YEN - CHICAGO MERCANTILE EXCHANGE' then 'jpyusd_proxy'
            when market_name = 'BRITISH POUND - CHICAGO MERCANTILE EXCHANGE' then 'gbpusd_proxy'
            when market_name = 'AUSTRALIAN DOLLAR - CHICAGO MERCANTILE EXCHANGE' then 'audusd_proxy'
            when market_name = 'CANADIAN DOLLAR - CHICAGO MERCANTILE EXCHANGE' then 'cadusd_proxy'
            when market_name = 'SWISS FRANC - CHICAGO MERCANTILE EXCHANGE' then 'chfusd_proxy'
            when market_name = 'NZ DOLLAR - CHICAGO MERCANTILE EXCHANGE' then 'nzdusd_proxy'
            when market_name = 'U.S. DOLLAR INDEX - ICE FUTURES U.S.' then 'dxy'

            /* =========================
               RATES
               ========================= */
            when market_name = '2-YEAR U.S. TREASURY NOTES - CHICAGO BOARD OF TRADE' then 'us2y'
            when market_name = '5-YEAR U.S. TREASURY NOTES - CHICAGO BOARD OF TRADE' then 'us5y'
            when market_name = '10-YEAR U.S. TREASURY NOTES - CHICAGO BOARD OF TRADE' then 'us10y'
            when market_name = 'ULTRA U.S. TREASURY BONDS - CHICAGO BOARD OF TRADE' then 'ustbond_ultra'
            when market_name = 'U.S. TREASURY BONDS - CHICAGO BOARD OF TRADE' then 'ustbond'

            /* =========================
               COMMODITIES
               ========================= */
            when market_name = 'WTI FINANCIAL CRUDE OIL - NEW YORK MERCANTILE EXCHANGE' then 'wti_crude'
            when market_name = 'CRUDE OIL, LIGHT SWEET - NEW YORK MERCANTILE EXCHANGE' then 'wti_crude'
            when market_name = 'GOLD - COMMODITY EXCHANGE INC.' then 'gold'
            when market_name = 'SILVER - COMMODITY EXCHANGE INC.' then 'silver'
            when market_name = 'NATURAL GAS - NEW YORK MERCANTILE EXCHANGE' then 'natgas'
            when market_name = 'COPPER-GRADE #1 - COMMODITY EXCHANGE INC.' then 'copper'

            else null
        end  ::varchar AS cot_market_code 

    from normalized

),

filtered as (

    select *
    from classified
    where cot_asset_class <> 'other'
      and cot_market_code is not null

)

select *
from filtered
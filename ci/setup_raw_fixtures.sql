-- CI ONLY: runs in GitHub Actions against the ephemeral database "dbt_ci".
-- Does NOT run against Stock_DB or any other local/production database unless
-- you manually execute this file there (do not do that).
--
-- Safety: refuse to run outside the CI database name.
DO $$
BEGIN
    IF current_database() <> 'dbt_ci' THEN
        RAISE EXCEPTION
            'setup_raw_fixtures.sql is CI-only (expected database dbt_ci, got %)',
            current_database();
    END IF;
END $$;

-- Bootstrap minimal raw-layer tables for GitHub Actions CI (empty Postgres).
-- Column names match production sources used by models/staging/*.

CREATE SCHEMA IF NOT EXISTS raw;

-- ---------------------------------------------------------------------------
-- Ticker reference
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw."TickerName" (
    "Ticker" varchar,
    "Stock_Name" varchar,
    "Industry" varchar
);

TRUNCATE raw."TickerName";
INSERT INTO raw."TickerName" ("Ticker", "Stock_Name", "Industry") VALUES
    ('AAPL', 'Apple Inc.', 'Technology'),
    ('SPY', 'SPDR S&P 500 ETF Trust', 'ETF');

-- ---------------------------------------------------------------------------
-- Daily prices (~90 sessions for rolling / return windows)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw."Daily_Prices" (
    "Date" date,
    "Ticker" varchar,
    "Open" numeric,
    "High" numeric,
    "Low" numeric,
    "Close" numeric,
    "Volume" bigint,
    "Adj Close" numeric,
    ingestion_date timestamp
);

TRUNCATE raw."Daily_Prices";
INSERT INTO raw."Daily_Prices"
    ("Date", "Ticker", "Open", "High", "Low", "Close", "Volume", "Adj Close", ingestion_date)
SELECT
    d::date,
    t.ticker,
    100 + (row_number() OVER (PARTITION BY t.ticker ORDER BY d))::numeric * 0.1,
    101 + (row_number() OVER (PARTITION BY t.ticker ORDER BY d))::numeric * 0.1,
    99 + (row_number() OVER (PARTITION BY t.ticker ORDER BY d))::numeric * 0.1,
    100 + (row_number() OVER (PARTITION BY t.ticker ORDER BY d))::numeric * 0.1,
    1000000 + (row_number() OVER (PARTITION BY t.ticker ORDER BY d))::bigint * 1000,
    100 + (row_number() OVER (PARTITION BY t.ticker ORDER BY d))::numeric * 0.1,
    current_timestamp
FROM generate_series(current_date - 89, current_date, '1 day'::interval) AS d
CROSS JOIN (VALUES ('AAPL'), ('SPY')) AS t(ticker);

-- ---------------------------------------------------------------------------
-- Fundamentals (quarterly metrics for pivot / QoQ logic)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw."Fundamentals" (
    ticker varchar,
    metric_name varchar,
    period_type varchar,
    fiscal_date date,
    value numeric,
    ingested_at timestamp
);

TRUNCATE raw."Fundamentals";
INSERT INTO raw."Fundamentals" (ticker, metric_name, period_type, fiscal_date, value, ingested_at)
SELECT
    'AAPL',
    m.metric_name,
    'quarterly',
    q.fiscal_date,
    m.base_value + q.q_offset * 1000,
    current_timestamp
FROM (
    VALUES
        ('revenue', 100000000::numeric),
        ('gross_profit', 40000000::numeric),
        ('operating_income', 25000000::numeric),
        ('net_income', 20000000::numeric),
        ('ebitda', 28000000::numeric),
        ('eps_diluted', 1.5::numeric),
        ('shares_outstanding', 15000000000::numeric),
        ('rd_expense', 5000000::numeric),
        ('cash_on_hand', 30000000::numeric),
        ('total_current_assets', 120000000::numeric),
        ('total_assets', 350000000::numeric),
        ('total_current_liabilities', 90000000::numeric),
        ('total_liabilities', 250000000::numeric),
        ('long_term_debt', 80000000::numeric),
        ('shareholders_equity', 100000000::numeric),
        ('free_cash_flow', 18000000::numeric)
) AS m(metric_name, base_value)
CROSS JOIN (
    VALUES
        (date '2024-03-31', 0),
        (date '2024-06-30', 1),
        (date '2024-09-30', 2),
        (date '2024-12-31', 3)
) AS q(fiscal_date, q_offset);

-- ---------------------------------------------------------------------------
-- COT (60 weekly reports for 52w rolling metrics; includes S&P market)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw."COT" (
    "Market and Exchange Names" varchar,
    "As of Date in Form YYMMDD" varchar,
    "As of Date in Form YYYY-MM-DD" date,
    "Commercial Positions-Long (All)" bigint,
    "Commercial Positions-Short (All)" bigint,
    "Noncommercial Positions-Long (All)" bigint,
    "Noncommercial Positions-Short (All)" bigint,
    "Nonreportable Positions-Long (All)" bigint,
    "Nonreportable Positions-Short (All)" bigint,
    "Open Interest (All)" bigint,
    ingestion_date timestamp
);

TRUNCATE raw."COT";
INSERT INTO raw."COT"
SELECT
    'E-MINI S&P 500 - CHICAGO MERCANTILE EXCHANGE',
    to_char(w.report_date, 'YYMMDD'),
    w.report_date,
    200000 + w.week_i * 100,
    180000 + w.week_i * 80,
    150000 + w.week_i * 120,
    140000 + w.week_i * 90,
    50000,
    45000,
    500000 + w.week_i * 200,
    current_timestamp
FROM (
    SELECT
        (current_date - (n * 7))::date AS report_date,
        n AS week_i
    FROM generate_series(0, 59) AS n
) AS w;

-- ---------------------------------------------------------------------------
-- Ratio tables (shared shape: Date, Ticker, ratio-specific columns)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS raw."PE_Ratio" (
    "Date" date, "Ticker" varchar, "Stock Price" numeric,
    "TTM Net EPS" numeric, "PE Ratio" numeric, ingestion_date timestamp
);
CREATE TABLE IF NOT EXISTS raw."PB_Ratio" (
    "Date" date, "Ticker" varchar, "Stock Price" numeric,
    "Book Value per Share" numeric, "PB Ratio" numeric, ingestion_date timestamp
);
CREATE TABLE IF NOT EXISTS raw."PS_Ratio" (
    "Date" date, "Ticker" varchar, "Stock Price" numeric,
    "TTM Sales per Share" numeric, "PS Ratio" numeric, ingestion_date timestamp
);
CREATE TABLE IF NOT EXISTS raw."Price_FCF_Ratio" (
    "Date" date, "Ticker" varchar, "Stock Price" numeric,
    "TTM FCF per Share" numeric, "Price/FCF" numeric, ingestion_date timestamp
);
CREATE TABLE IF NOT EXISTS raw."ROA" (
    "Date" date, "Ticker" varchar, "TTM Net Income" numeric,
    "Total Assets" numeric, "Return on Assets" numeric, ingestion_date timestamp
);
CREATE TABLE IF NOT EXISTS raw."ROE" (
    "Date" date, "Ticker" varchar, "TTM Net Income" numeric,
    "Shareholder Equity" numeric, "Return on Equity" numeric, ingestion_date timestamp
);
CREATE TABLE IF NOT EXISTS raw."ROI" (
    "Date" date, "Ticker" varchar, "TTM Net Income" numeric,
    "LT Investments & Debt" numeric, "Return on Investment" numeric, ingestion_date timestamp
);
CREATE TABLE IF NOT EXISTS raw."Net_Profit_Margin" (
    "Date" date, "Ticker" varchar, "TTM Net Income" numeric,
    "TTM Revenue" numeric, "Net Profit Margin" numeric, ingestion_date timestamp
);
CREATE TABLE IF NOT EXISTS raw."Operating_Margin" (
    "Date" date, "Ticker" varchar, "TTM Operating Income" numeric,
    "TTM Revenue" numeric, "Operating Margin" numeric, ingestion_date timestamp
);

TRUNCATE raw."PE_Ratio", raw."PB_Ratio", raw."PS_Ratio", raw."Price_FCF_Ratio",
    raw."ROA", raw."ROE", raw."ROI", raw."Net_Profit_Margin", raw."Operating_Margin";

INSERT INTO raw."PE_Ratio"
    ("Date", "Ticker", "Stock Price", "TTM Net EPS", "PE Ratio", ingestion_date)
SELECT fiscal_date, 'AAPL', 180, 6, 30, current_timestamp
FROM (VALUES (date '2024-03-31'), (date '2024-06-30'), (date '2024-09-30'), (date '2024-12-31')) v(fiscal_date);

INSERT INTO raw."PB_Ratio"
    ("Date", "Ticker", "Stock Price", "Book Value per Share", "PB Ratio", ingestion_date)
SELECT fiscal_date, 'AAPL', 180, 20, 9, current_timestamp
FROM (VALUES (date '2024-03-31'), (date '2024-06-30'), (date '2024-09-30'), (date '2024-12-31')) v(fiscal_date);

INSERT INTO raw."PS_Ratio"
    ("Date", "Ticker", "Stock Price", "TTM Sales per Share", "PS Ratio", ingestion_date)
SELECT fiscal_date, 'AAPL', 180, 25, 7.2, current_timestamp
FROM (VALUES (date '2024-03-31'), (date '2024-06-30'), (date '2024-09-30'), (date '2024-12-31')) v(fiscal_date);

INSERT INTO raw."Price_FCF_Ratio"
    ("Date", "Ticker", "Stock Price", "TTM FCF per Share", "Price/FCF", ingestion_date)
SELECT fiscal_date, 'AAPL', 180, 5, 36, current_timestamp
FROM (VALUES (date '2024-03-31'), (date '2024-06-30'), (date '2024-09-30'), (date '2024-12-31')) v(fiscal_date);

INSERT INTO raw."ROA"
    ("Date", "Ticker", "TTM Net Income", "Total Assets", "Return on Assets", ingestion_date)
SELECT fiscal_date, 'AAPL', 20e6, 350e6, 0.057, current_timestamp
FROM (VALUES (date '2024-03-31'), (date '2024-06-30'), (date '2024-09-30'), (date '2024-12-31')) v(fiscal_date);

INSERT INTO raw."ROE"
    ("Date", "Ticker", "TTM Net Income", "Shareholder Equity", "Return on Equity", ingestion_date)
SELECT fiscal_date, 'AAPL', 20e6, 100e6, 0.20, current_timestamp
FROM (VALUES (date '2024-03-31'), (date '2024-06-30'), (date '2024-09-30'), (date '2024-12-31')) v(fiscal_date);

INSERT INTO raw."ROI"
    ("Date", "Ticker", "TTM Net Income", "LT Investments & Debt", "Return on Investment", ingestion_date)
SELECT fiscal_date, 'AAPL', 20e6, 80e6, 0.25, current_timestamp
FROM (VALUES (date '2024-03-31'), (date '2024-06-30'), (date '2024-09-30'), (date '2024-12-31')) v(fiscal_date);

INSERT INTO raw."Net_Profit_Margin"
    ("Date", "Ticker", "TTM Net Income", "TTM Revenue", "Net Profit Margin", ingestion_date)
SELECT fiscal_date, 'AAPL', 20e6, 100e6, 0.20, current_timestamp
FROM (VALUES (date '2024-03-31'), (date '2024-06-30'), (date '2024-09-30'), (date '2024-12-31')) v(fiscal_date);

INSERT INTO raw."Operating_Margin"
    ("Date", "Ticker", "TTM Operating Income", "TTM Revenue", "Operating Margin", ingestion_date)
SELECT fiscal_date, 'AAPL', 25e6, 100e6, 0.25, current_timestamp
FROM (VALUES (date '2024-03-31'), (date '2024-06-30'), (date '2024-09-30'), (date '2024-12-31')) v(fiscal_date);

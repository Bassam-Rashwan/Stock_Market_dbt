# Stock Research dbt Project

A modular dbt project for equity research and macro analysis, combining market data, company fundamentals, financial ratios, and COT-based positioning signals into analytics-ready models.

## Overview

This repository organizes a stock research warehouse into the standard dbt layers: staging, intermediate, and marts. The project transforms raw market, finance, ratio, and macro inputs into reusable datasets for screening, monitoring, and cross-asset research.

## Project structure

- `models/staging/`: source-aligned cleanup and standardization models for market prices, fundamentals, ticker metadata, ratios, and COT data.
- `models/intermediate/market/`: return, rolling feature, technical signal, and volume signal models that prepare daily market features for marts.
- `models/intermediate/finance/`: quarterly fundamentals reshaped for analysis.
- `models/intermediate/ratios/`: unified valuation, quality, growth, and z-score models for ratio analysis.
- `models/intermediate/macro/`: COT market classification, positioning, z-scores, and regime flags for macro sentiment analysis.
- `models/marts/equity/`: business-facing equity marts including daily market signals and latest stock snapshot views.
- `models/marts/macro/`: weekly macro mart for COT data used downstream in cross-domain joins.
- `models/marts/cross/`: cross-domain mart that overlays equity and macro signals using ticker-to-COT mapping.
- `seeds/`: reference mapping files such as the equity-to-COT market map used in the macro overlay mart.

## Mart models

### `mart_equity__daily_market`

This mart combines technical and volume-based daily features into one equity-facing fact table keyed by ticker and trade date. It includes price, returns, volatility, trend regime, moving-average signals, volume trend, and momentum confirmation fields for downstream screening and monitoring.

### `mart_equity__latest_snapshot`

This mart extracts the most recent daily row for each ticker and enriches it with company metadata such as company name and industry. It is designed for watchlists, dashboards, and current-state stock screening.

### `mart_macro__cot_weekly`

This macro mart serves as the weekly COT consumption layer and exposes market-level positioning features such as net positioning, COT index values, z-score regimes, and open interest for selected macro contracts.

### `mart_equity__macro_overlay_daily`

This cross mart joins the equity daily mart to weekly COT macro signals through a seed-based ticker-to-market mapping and an as-of join on report dates. It makes equity price behavior and macro positioning available in a single daily-grain dataset for exploratory research and signal testing.

## Typical use cases

- Daily equity signal screening using trend, momentum, and volume confirmation fields.
- Latest snapshot dashboards by ticker, company, and industry.
- Macro overlay analysis that compares stock behavior with COT positioning regimes in equity index, FX, rates, and commodity proxies.
- Quarterly ratio and fundamentals analysis for valuation and quality research.

## How to run

Install dbt dependencies:

```bash
dbt deps
```

Build the full project:

```bash
dbt build
```

Build only macro-tagged models:

```bash
dbt build --select tag:macro
```

Build only marts:

```bash
dbt build --select path:models/marts
```

Build a specific mart:

```bash
dbt build --select mart_equity__daily_market
```

## Notes

- The project uses modular dbt layering, where staging remains source-close, intermediate models hold reusable transformations, and marts provide business-facing datasets.
- Weekly macro COT data is mapped to equities through a maintained seed file, which means macro overlay coverage depends on the quality and completeness of that mapping.
- If working on Windows, `.gitattributes` can help keep line endings consistent for `.sql`, `.yml`, `.md`, and `.csv` files.

## Next ideas

Possible future additions include PIT-style point-in-time integration, richer equity-to-macro mapping, factor backtesting marts, and documentation generated from dbt docs metadata.
=======
Welcome to your new dbt project!

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices


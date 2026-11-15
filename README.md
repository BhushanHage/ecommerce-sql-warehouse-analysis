# Olist E-Commerce SQL Analysis

End-to-end SQL project built on the public Olist Brazilian E-Commerce dataset (~500K rows across 9 tables, 2016–2018). Covers database design, indexing strategy, view-based denormalization, and 40 analytical queries ranging from basic filtering to RFM segmentation and cohort analysis.

## Project Overview

This project simulates a real analytics engineering workflow on e-commerce transaction data:
- Designed a normalized relational schema with explicit primary/foreign keys
- Applied a hybrid rowstore + columnstore indexing strategy based on actual query patterns (OLTP point-lookups vs. OLAP aggregation)
- Built reusable views to eliminate repeated joins and prevent grain-mismatch bugs (fan-out from joining line-item-grain tables to order-grain tables)
- Wrote 40 SQL queries organized by difficulty, covering joins, window functions, CTEs, correlated subqueries, RFM segmentation, and cohort analysis

## Dataset

Source: public Olist Brazilian E-Commerce dataset — real orders placed on the Olist marketplace between 2016 and 2018.

| Table | Rows | Description |
|---|---|---|
| `orders` | 99,441 | One row per order — status, timestamps, customer link |
| `order_items` | 112,650 | Line items per order — price, freight, product, seller (fact table) |
| `customer` | 99,441 | Customer ID, location. Note: `customer_id` is per-order; `customer_unique_id` identifies the real person |
| `order_product` | 32,951 | Product category, dimensions, weight |
| `order_seller` | 3,095 | Seller location |
| `order_payment` | 103,886 | Payment type, installments, value (can be multiple rows per order) |
| `order_review` | 99,224 | Review score and dates |
| `order_gio` | 1,000,163 | Zip prefix → lat/long |
| `order_cat_name` | 71 | Portuguese → English category names |

**Two fields are synthetic, added for practice purposes only, and clearly documented:**
- `product_name` (in `products`) — Olist's real dataset never included actual product names, only a name-length count. Generated deterministically per `product_id` for readability.
- `estimated_unit_cost` (in `order_items`) — no real cost/COGS data exists in the source dataset. Generated as a category-consistent fraction of price, used only to practice profit-margin queries.

Full details: [`data/README_DATA_NOTES.md`](data/README_DATA_NOTES.md).

## Schema & Design Decisions

- Full DDL with explicit primary keys, foreign keys, and data types: [`schema&load_data.sql`](schema&load_data.sql)
- **Grain awareness:** `order_items` is line-item grain (one row per product per order); `orders` is order grain. Joining them directly is safe for descriptive attributes but unsafe for aggregation — the views handle this correctly by aggregating to matching grain before joining. See [`data/README_DATA_NOTES.md`](data/README_DATA_NOTES.md) for the full explanation.

## Indexing Strategy

Rather than indexing every column, each index was chosen based on the actual query pattern it serves:

| Pattern | Index type used |
|---|---|
| Point lookups / joins on IDs | Nonclustered rowstore |
| Range scans (date filters) | Nonclustered rowstore with `INCLUDE` (covering index) |
| Low-selectivity filters on a skewed column (e.g. `order_status`, 97% one value) | Filtered nonclustered index |
| Repeated `SUM`/`GROUP BY` across a large fact table | Nonclustered columnstore index |

Only `order_items` — the one table that is both large and the target of nearly every aggregation query — gets a columnstore index. Full table-by-table reasoning, including why each *other* index type was rejected per table: [`docs/indexing_strategy.md`](docs/Indexing_Strategy.md).

## Views

Ten views eliminate repeated joins and centralize aggregation logic so it's written correctly once instead of re-derived (and potentially miscalculated) in every query:

- `vw_order_items_enriched` — line-item grain, fully denormalized
- `vw_order_revenue_summary` — order-grain revenue (aggregated before joining, to avoid fan-out)
- `vw_order_payment_summary`, `vw_monthly_revenue`, `vw_seller_performance`, `vw_customer_summary`, `vw_review_summary`, `vw_product_category_english`, plus optional geo views

Definitions: [`views.sql`](views.sql)

## Queries

40 queries across 4 difficulty levels:

| Level | Focus |
|---|---|
| 1 — Basic | Filtering, sorting, simple aggregates |
| 2 — Intermediate | Multi-table joins, `GROUP BY`/`HAVING` |
| 3 — Advanced | Window functions (`RANK`, `LAG`, `SUM() OVER`), CTEs |
| 4 — Expert | RFM segmentation, cohort analysis, correlated subqueries, pivoting, market-basket pairing |

## Tech Stack

- **Database:** SQL Server
- **Data source:** Olist Brazilian E-Commerce (public dataset)
- **Tools:** SSMS for query execution and execution-plan analysis

## Key Technical Highlights

- Hybrid rowstore + columnstore indexing on the fact table, benchmarked with `SET STATISTICS TIME/IO` before and after
- Correctly resolved the `customer_id` vs. `customer_unique_id` distinction (per-order ID vs. actual person) — a common source of incorrect repeat-customer metrics
- Grain-aware view design preventing join fan-out between line-item and order-level tables
- Filtered indexing applied to a heavily skewed column instead of a blanket index

## Repository Structure

```

# E-Commerce SQL Analysis

ecommerce-sql-analysis/
│
├── data/
│   ├── olist_customers_dataset.csv
│   ├── olist_geolocation_dataset.csv
│   ├── olist_order_items_dataset.csv
│   ├── olist_order_payments_dataset.csv
│   ├── olist_order_reviews_dataset.csv
│   ├── olist_orders_dataset.csv
│   ├── olist_products_dataset.csv
│   ├── olist_sellers_dataset.csv
│   ├── product_category_name_translation.csv
│   └── README_DATA_NOTES.md
│
├── docs/
│   ├── Index_Justification.md
│   ├── Indexing_Strategy.md
│   ├── Olist_Project_Complete_ER_Diagram.png
│   ├── Olist_Project_ER_Diagram_GitHub.md
│   └── SQL_Practice_Questions.md
│
├── query/
│   └── [SQL query files]
│
├── Indexing.sql
├── README.md
├── schema&load_data.sql
├── Transfering.sql
└── Views.sql


## How to Run

1. Restore the CSVs in `data/` into a SQL Server database (`BULK INSERT` or SSMS Import Wizard).
2. Run `schema&load_data.sql` to create tables with keys and constraints.
3. Run `indexes.sql` to apply the indexing strategy.
4. Run `views.sql` to create the reusable views.
5. Run any query file in `queries/` against the resulting database.

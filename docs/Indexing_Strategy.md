# Indexing Strategy — Olist Dataset (SQL Server)

These four index types are SQL Server-specific terminology, so this guide assumes SQL Server as the target engine.

## Quick refresher

| Type | What it is | Best for |
|---|---|---|
| **Clustered index** | Physically sorts the table by this key. Only **one per table**. | Primary key, or the column most used for range scans/joins. |
| **Nonclustered rowstore** | A separate B-tree pointing back to the clustered index. Many allowed per table. | FK/join columns and filter columns that aren't the clustered key — classic OLTP workhorse. |
| **Nonclustered columnstore (NCCI)** | A column-oriented index layered *on top of* an existing rowstore table. | Tables that need both point lookups (OLTP) *and* heavy `SUM`/`GROUP BY` (analytics) — exactly the `order_items` case here. |
| **Clustered columnstore (CCI)** | Replaces the entire table storage with column-oriented storage. | Large fact tables in a pure data-warehouse setting; best compression, fastest full-table aggregation scans, weak at single-row lookups/updates. |

## Table-by-table recommendations

| Table | Clustered | Nonclustered (rowstore) | Columnstore? |
|---|---|---|---|
| `order_items` (fact table, 112,650 rows) | `(order_id, order_item_id)` — PK | `product_id`, `seller_id` for joins | **Yes** — nonclustered columnstore on `(product_id, seller_id, price, freight_value, estimated_unit_cost)`. This table is the target of nearly every SUM/GROUP BY revenue query — columnstore's batch-mode execution and column compression are dramatically faster for that pattern. |
| `orders` (99,441 rows) | `order_id` — PK | `customer_id` (joins), `order_purchase_timestamp` (date-range grouping), `order_status` (filters) | Not needed — no numeric measure columns to aggregate; mostly a join/filter table. |
| `customer` (99,441 rows) | `customer_id` — PK | `customer_unique_id` (critical — used constantly for repeat-customer grouping, and it's *not* the PK), `customer_state` | No |
| `order_product` (32,951 rows) | `product_id` — PK | `product_category_name` (heavy GROUP BY/join target) | No |
| `order_seller` (3,095 rows) | `seller_id` — PK | Optional: `seller_state` | No — small enough that SQL Server scans it efficiently regardless. |
| `order_payment` (103,886 rows) | `(order_id, payment_sequential)` — PK | `payment_type` (filters/GROUP BY) | No — moderate size, rowstore is fine. |
| `order_review` (99,224 rows) | `review_id` — PK | `order_id` (join target), `review_score` (filter/GROUP BY) | No |
| `order_gio` (1,000,163 rows, heavy duplicate zip prefixes) | `geolocation_zip_code_prefix` (no real PK exists — no unique row identifier) | — | No — pure lookup dimension, not aggregated. |
| `order_cat_name` (71 rows) | `product_category_name` — PK | none needed | No |

## Example syntax

**`order_items` — hybrid rowstore + columnstore (the interesting one for this project):**
```sql
-- Clustered rowstore for OLTP-style joins/lookups
ALTER TABLE order_items
ADD CONSTRAINT PK_order_items PRIMARY KEY CLUSTERED (order_id, order_item_id);

-- Nonclustered columnstore for fast aggregation
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_order_items_analytics
ON order_items (product_id, seller_id, price, freight_value, estimated_unit_cost);
```

**`geolocation` — needed because it has no natural PK and 1M rows:**
```sql
CREATE CLUSTERED INDEX CIX_geo_zip
ON order_gio (geolocation_zip_code_prefix);
```

**`customers` — the `customer_unique_id` index matters a lot here:**
```sql
CREATE NONCLUSTERED INDEX IX_customers_unique_id
ON customer (customer_unique_id);

CREATE NONCLUSTERED INDEX IX_customers_state
ON customer (customer_state);
```

**`orders` — supports MoM revenue / date-range queries:**
```sql
CREATE NONCLUSTERED INDEX IX_orders_purchase_date
ON orders (order_purchase_timestamp)
INCLUDE (customer_id, order_status);
```

## Why this is a good CV talking point

Adding the `order_items` nonclustered columnstore index and being able to say *"benchmarked query performance before/after adding a columnstore index on the fact table, reducing aggregation query time from X to Y"* is a genuinely strong, specific CV line — it shows understanding of OLTP vs. OLAP storage trade-offs, not just the ability to write a `CREATE INDEX` statement.

**Suggested next step:** run one of the Level 3 aggregation queries (e.g. the MoM revenue query) with `SET STATISTICS TIME ON` before and after adding the columnstore index, and record the actual before/after numbers as evidence for the CV claim.

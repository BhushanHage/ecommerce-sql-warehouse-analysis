# Why Each Index Choice — Detailed Justification

For every table below: what was chosen, why it fits this specific workload, and specifically why each *other* index type was rejected for it.

---

## 1. `order_items` (fact table, 112,650 rows)

**Chosen: Clustered rowstore PK on `(order_id, order_item_id)` + Nonclustered columnstore on `(product_id, seller_id, price, freight_value, estimated_unit_cost)`**

- **Why clustered rowstore, not clustered columnstore (CCI):** This table needs a genuine uniqueness constraint — `(order_id, order_item_id)` must enforce "no duplicate line items." A clustered columnstore index cannot enforce a primary key/uniqueness constraint on its own; you'd need a separate unique nonclustered rowstore index anyway, which defeats the simplicity. Since this table is also joined constantly (to `orders`, `products`, `sellers`) for row-level lookups, keeping a normal clustered rowstore B-tree as the "spine" preserves fast single-order lookups (`WHERE order_id = 'x'`), which a pure CCI is comparatively slow at.
- **Why nonclustered columnstore, not just nonclustered rowstore, on the analytics columns:** Every revenue/window-function question in this project (MoM growth, top products, category revenue, profit margin) does `SUM`/`GROUP BY`/`AVG` scanning large portions of `price`, `freight_value`, `estimated_unit_cost`. A rowstore B-tree index still has to read a full row (or do a lot of key lookups back to the clustered index) even if it only needs 3–4 columns. A columnstore index stores each column separately and highly compressed, so a `SUM(price)` query reads only the `price` column's compressed segments — orders of magnitude less I/O — and runs in **batch execution mode**, processing ~900 rows at a time instead of row-by-row. This is the single biggest performance lever in the whole schema, because this is the table every heavy query touches.
- **Why not skip columnstore entirely and just add more rowstore indexes:** You could add nonclustered rowstore indexes on `product_id` and `seller_id` for joins (and this guide does recommend that too), but no amount of rowstore B-tree indexing makes `SUM()` over 100k+ rows fast — B-trees are built for seeking specific rows, not scanning-and-aggregating columns. That's precisely the gap columnstore fills.
- **Why not clustered columnstore on the *whole table* (replacing the rowstore entirely):** Because `order_items` is also used for OLTP-style point operations (a single order's line items, joins during ETL/loading), and CCI has weaker performance for singleton row lookups/inserts one at a time, plus it can't natively hold the composite primary key constraint. The **hybrid approach (rowstore PK + nonclustered columnstore)** gets both: fast point lookups and fast aggregation, at the cost of some extra storage and slightly slower bulk inserts (acceptable for this static/historical dataset, which isn't being written to live).

---

## 2. `orders` (99,441 rows)

**Chosen: Clustered on `order_id` (PK) + Nonclustered rowstore on `customer_id`, `order_purchase_timestamp`, `order_status`**

- **Why clustered rowstore on `order_id`, not columnstore:** This table has very few numeric measure columns (no price/revenue figures at all — those live in `order_items`). Its main job is being *joined* and *filtered*, not aggregated. Columnstore's advantage (compressing and scanning numeric measure columns) doesn't apply here since there's nothing to sum. A clustered B-tree on the PK gives the fastest possible join path back from `order_items`/`payments`/`reviews`.
- **Why nonclustered rowstore (not columnstore) on `customer_id`, `order_purchase_timestamp`, `order_status`:** These are used for **filtering and grouping by month/status**, and for **joining to customers** — classic selective-lookup patterns (`WHERE order_status = 'delivered'`, `WHERE order_purchase_timestamp BETWEEN ...`). A rowstore B-tree is ideal here because it can seek directly to a date range or a specific status without scanning the whole table. Columnstore would actually be *worse* for this — it excels at full-column scans, not selective range seeks on a filter column.
- **Why not just rely on the clustered index alone (no extra nonclustered indexes):** Without a nonclustered index on `order_purchase_timestamp`, any "group by month" or date-range query would force a full table scan of 99k rows through the clustered index just to find the right rows, since the table is physically sorted by `order_id`, not by date. The `INCLUDE (customer_id, order_status)` on that index also lets SQL Server answer some queries directly from the index without touching the base table at all (a "covering index").

---

## 3. `customer` (99,441 rows)

**Chosen: Clustered on `customer_id` (PK) + Nonclustered rowstore on `customer_unique_id`, `customer_state`**

- **Why clustered on `customer_id`, not `customer_unique_id`:** `customer_id` is the actual primary key and is unique per row by definition — a clustered index requires (or strongly prefers) a unique key to avoid SQL Server silently adding a hidden 4-byte "uniquifier" to every duplicate. `customer_unique_id` is **intentionally not unique** here (that's the whole point — the same person can have several `customer_id`s but one `customer_unique_id`), so clustering on it would be both semantically wrong and technically inefficient.
- **Why nonclustered rowstore (not columnstore) on `customer_unique_id`:** This column is used constantly for **equality lookups and grouping** ("how many orders does this real person have," repeat-customer detection) — a classic B-tree use case. There's no numeric measure being aggregated across millions of rows here to justify columnstore; the table is under 100k rows and the query pattern is "find/group by this ID," not "scan and sum a column."
- **Why nonclustered rowstore on `customer_state`:** Same logic — it's a low-cardinality filter/group-by column (27 Brazilian states), ideal for a B-tree, and small enough that even without an index the optimizer could scan efficiently, but the index avoids that scan for state-level revenue/customer-count queries that join back to `order_items`.
- **Why not columnstore anywhere on this table:** No columns here get `SUM`/`AVG`'d directly — this is a pure dimension table. Columnstore only pays off when you're compressing and scanning numeric/repeating values at scale; there's nothing here that benefits.

---

## 4. `order_product` (32,951 rows)

**Chosen: Clustered on `product_id` (PK) + Nonclustered rowstore on `product_category_name`**

- **Why clustered rowstore on `product_id`:** It's the PK and the primary join target from `order_items`. Standard choice — no ambiguity here.
- **Why nonclustered rowstore on `product_category_name`, not columnstore:** This column is used to **join and group** ("revenue by category"), but the actual aggregation (SUM of price) happens over in `order_items`, not here — this table just supplies the category label. A B-tree index here speeds up the join/lookup step; there's no large numeric scan happening *within this table* to justify columnstore.
- **Why no columnstore on this table at all:** At 32,951 rows, it's small enough that even a full scan is fast, and its main role is as a lookup/dimension table joined into the fact table — columnstore's benefit scales with row count and aggregation volume, neither of which apply here.

---

## 5. `order_seller` (3,095 rows)

**Chosen: Clustered on `seller_id` (PK) only, optional nonclustered on `seller_state`**

- **Why just the clustered PK, and not more indexes:** At only 3,095 rows, SQL Server's query optimizer will almost always choose a full table/index scan over using an additional nonclustered index anyway, because scanning 3k rows is trivially fast — the overhead of maintaining an extra index would outweigh any lookup benefit. This is a case where **adding more indexes is actively unhelpful**: more indexes to maintain, negligible query speedup.
- **Why not columnstore:** Same reasoning, amplified — columnstore's compression and batch-mode benefits only materialize at much larger row counts (typically hundreds of thousands to millions of rows). On a 3k-row table it adds overhead for zero benefit.

---

## 6. `order_payment` (103,886 rows)

**Chosen: Clustered rowstore PK on `(order_id, payment_sequential)` + Nonclustered rowstore on `payment_type`**

- **Why clustered rowstore, not columnstore:** Like `orders`, this table is joined and filtered more than it's mass-aggregated. `payment_value` does get summed in some queries, but the aggregation grain is usually "per order" (a handful of rows per order_id), not a full-table scan-and-sum pattern the way `order_items` revenue queries are. Given the table is a moderate ~104k rows and the aggregation isn't the dominant workload, the added complexity of columnstore isn't justified — a well-chosen clustered PK is sufficient.
- **Why the composite clustered key `(order_id, payment_sequential)` rather than just `order_id`:** A single `order_id` isn't unique in this table (multi-payment orders create multiple rows per order), so the real natural key is the pair. Clustering on the full natural key keeps all of one order's payment rows physically adjacent, which speeds up the common `GROUP BY order_id, SUM(payment_value)` pattern even without an extra index.
- **Why nonclustered rowstore on `payment_type`:** It's a low-cardinality filter/group-by column ("how many boleto vs credit card payments") — ideal B-tree use case, and cheap to maintain given the moderate row count.

---

## 7. `order_review` (99,224 rows)

**Chosen: Clustered on `review_id` (PK) + Nonclustered rowstore on `order_id`, `review_score`**

- **Why clustered on `review_id`, not `order_id`:** `review_id` is the actual PK and guarantees uniqueness. `order_id` is used constantly for joins but isn't the natural clustering key of *this* table (its job here is a lookup/filter column, not the physical sort order).
- **Why nonclustered rowstore on `order_id`:** This is the join column back to `orders`/`order_items` — a classic FK-lookup index. Without it, every join from orders to reviews would require a scan of the reviews table.
- **Why nonclustered rowstore on `review_score`:** Used for filtering/grouping ("average score by category," "sellers below a review threshold") — low cardinality (1–5), ideal for a B-tree, cheap to maintain.
- **Why not columnstore:** No large-scale numeric aggregation happens across many columns of this table at once — `review_score` averaging is a single narrow aggregate on a ~99k row table, well within what a normal index/scan handles efficiently. Columnstore's overhead isn't repaid here.

---

## 8. `order_gio` (1,000,163 rows — the largest table)

**Chosen: Clustered rowstore on `geolocation_zip_code_prefix` only — no columnstore**

- **Why clustered on zip prefix despite this being the biggest table:** This table has **no natural unique primary key** — the same zip prefix appears many times with slightly different lat/long values (multiple locations sharing a postal prefix). Its only real use in this project is as a **lookup**: "given a zip prefix, get approximate coordinates for a map visual." Clustering on the zip prefix means all rows for a given prefix sit physically together, making that lookup fast.
- **Why not columnstore, even though it's the largest table by row count:** This is the key distinction — **columnstore helps when you're aggregating (SUM/AVG/COUNT) numeric measures across many rows**, not when you're doing simple point lookups. Nobody in this project is running `SUM(latitude)` — the table is queried as "give me the lat/long for this zip," a single-row seek. Row count alone doesn't justify columnstore; the *query pattern* does, and this table's pattern is point-lookup, not aggregation.
- **Why not multiple nonclustered indexes:** Since the only real filter/join column is the zip prefix, and that's already the clustered key, additional indexes wouldn't serve a different query pattern here.

---

## 9. `order_cat_name` (71 rows)

**Chosen: Clustered on `product_category_name` (PK) only**

- **Why no other index type is worth considering:** 71 rows is small enough to fit in memory and be scanned in microseconds regardless of indexing. This is purely a translation/lookup table joined once per query to convert a category name to English — any index type beyond the basic clustered PK would be pure overhead with no measurable benefit.

---

## General pattern across the whole schema

| Signal in the query | Index type it points to |
|---|---|
| Table is joined by a specific ID, or a single row is fetched by key | **Clustered / nonclustered rowstore** (B-tree seek) |
| Column is used to filter (`WHERE`) or group into a moderate number of buckets | **Nonclustered rowstore** |
| Column feeds a `SUM`/`AVG`/`COUNT` over a large fraction of a large table, repeatedly, across many query variations | **Columnstore** (rowstore, even indexed, can't beat compressed column scans + batch mode for this) |
| Table is small (a few thousand rows or fewer) | **Minimal indexing** — the optimizer's scan is already fast; extra indexes just add write/maintenance overhead for no read benefit |

This is why, out of nine tables, only **one** (`order_items`) gets a columnstore index: it's the only table that is both large *and* the target of repeated full-column numeric aggregation across nearly every advanced query in this project. Every other table's workload is dominated by point lookups, joins, or selective filters — exactly what rowstore B-tree indexes are built for.

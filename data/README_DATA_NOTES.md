# Dataset Notes — Olist Brazilian E-Commerce (Restored + Dummy Fields Added)

## What changed vs. your uploaded file

| File | Status | Notes |
|---|---|---|
| `order_items.csv` | **Restored (real data)** | Was truncated to 32,951 rows in your upload; full 112,650 rows restored. New column `estimated_unit_cost` added — **synthetic, not real**. |
| `order_product.csv` | **Restored + new column** | Real data, all 32,951 rows. New column `product_name` added — **synthetic, not real**. |
| `order_seller.csv` | **New (real data)** | Did not exist in your file at all. 3,095 real sellers with city/state. |
| `order_cat_name.csv` | **New (real data)** | Did not exist in your file. Maps Portuguese category → English category. |
| `order_gio.csv` | **New (real data)** | Did not exist in your file. Zip prefix → lat/long, for map visuals. |
| `customer.csv` | Unchanged, real | Same as your upload (99,441 rows). |
| `orders.csv` | Unchanged, real | Same as your upload (99,441 rows). |
| `order_payment.csv` | Unchanged, real | Only **one** copy included (your file had it duplicated). |
| `order_review.csv` | Unchanged, real | Same as your upload (99,224 rows). |

**Not included:** `Final_Data_Set_0` — per your instruction, since it's a derived/merged table you'll rebuild yourself.

## About the two synthetic (dummy) fields

These two fields **do not exist in the real Olist dataset** — Olist never collected or released them. They were added only because you asked for practice-friendly dummy values, generated to look plausible and stay internally consistent (same category → similar cost ratio, same product → same name). **Treat both as placeholder data for practicing joins/SQL/DAX — not as real business figures.**

1. **`product_name`** (in `order_product.csv`)
   Generated from the product's category name, e.g. `"Premium Health Beauty - 1E9E8E"`. Deterministic per `product_id` (same product always gets the same name), but has no connection to what was actually sold.

2. **`estimated_unit_cost`** (in `order_items.csv`)
   Generated as a category-consistent fraction of `price` (roughly 45%–75%, with small random noise), always less than `price`. Useful for practicing profit/margin calculations, but **not a real cost figure** — Olist's real data has no cost/COGS field at all.

## Known issues intentionally left untouched (you said you'd handle cleaning)

- `order_status` values (`delivered`, `shipped`, `canceled`, `unavailable`, `invoiced`, `processing`, `created`, `approved`) are not mapped to "Pending/Completed."
- 610 products still have a blank `product_category_name`.
- 2 products still have blank weight/dimension fields.
- Some orders still have blank `order_approved_at` / delivery dates (expected for canceled/processing orders).
- `customer_id` vs `customer_unique_id` — remember to use `customer_unique_id` for any unique-customer or repeat-purchase logic.
- `order_item_id` is per-order sequential, not a global ID — don't use it as a join key on its own.
- `payment_sequential` — a single `order_id` can have multiple payment rows if the customer split payment methods.

## Source of restored real data
Original public Olist Brazilian E-Commerce dataset (customer/order/product/seller/payment/review/geolocation tables span 2016–2018).

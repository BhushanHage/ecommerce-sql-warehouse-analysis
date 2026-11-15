# SQL Practice Question Bank — Olist E-Commerce Dataset

Tables available: `customer`, `orders`, `order_items`,
`order_payment`, `order_review`, `order_product`,
`order_seller`, `order_gio`, `order_cat_name`.

No answers here — just the question list, ordered basic → advanced, so you can work through them yourself and we can go over solutions later.

---

## Level 1 — Basics (SELECT, WHERE, ORDER BY, simple aggregates)

1. List all distinct order statuses that exist in `orders`.
2. Find all orders placed in a specific month/year (e.g., January 2018).
3. Get the top 10 most expensive items from `order_items` by `price`.
4. Count the total number of customers per `customer_state`.
5. Find all products belonging to a given `product_category_name`.
6. Get the average `price` and average `freight_value` across all order items.
7. List all sellers located in a specific state, sorted by city name.
8. Find the minimum and maximum `review_score` given in `order_review`.
9. Count how many orders have each `payment_type` (credit card, boleto, voucher, etc.).
10. Find all orders that were `canceled` or `unavailable`.

## Level 2 — Intermediate (JOINs, GROUP BY, HAVING)

11. For each order, calculate total order value (sum of item prices + freight) — join `orders` with `order_items`.
12. Find the top 10 best-selling products by total quantity sold (join `order_items` with `products`).
13. Calculate total revenue per product category (join `order_items` → `products`, translate category name via `order_cat_name`).
14. Find the number of orders and total revenue per customer state (join `orders` → `customers`).
15. Find sellers who have sold in more than 5 different product categories.
16. Find the average review score per product category.
17. Identify orders where the payment was split across more than one payment method (`payment_sequential` > 1).
18. Find customers who have placed more than one order — remember to use `customer_unique_id`, not `customer_id`.
19. List the top 10 sellers by total revenue generated, with seller city/state included.
20. Find categories with more than 100 orders but an average review score below 3.

## Level 3 — Advanced (Window functions, CTEs, subqueries)

21. Using a window function, rank products within each category by total revenue (`RANK()` or `DENSE_RANK()` partitioned by category).
22. Calculate month-over-month total revenue growth using `LAG()`.
23. Write a CTE that first computes each customer's total spend, then classifies customers into spend tiers (e.g., Low/Medium/High) using `CASE`.
24. Find the running (cumulative) total of revenue by month using `SUM() OVER (ORDER BY month)`.
25. For each seller, find their best-selling product using a window function (`ROW_NUMBER()` partitioned by seller, ordered by quantity sold).
26. Write a subquery to find customers whose total spend is above the overall average customer spend.
27. Find the percentage contribution of each product category to total revenue, using a window function for the grand total.
28. Identify the top 3 categories by revenue in each customer state (windowed ranking partitioned by state).
29. Calculate average delivery time (`order_delivered_customer_date` − `order_purchase_timestamp`) per state, excluding orders with null delivery dates.
30. Find the late-delivery rate: percentage of orders where `order_delivered_customer_date` is later than `order_estimated_delivery_date`.

## Level 4 — Expert (multi-step CTEs, correlated subqueries, cohort/RFM-style analysis)

31. Build an RFM (Recency, Frequency, Monetary) segmentation query: for each customer, calculate days since last order, total number of orders, and total spend, then bucket into segments.
32. Write a cohort analysis: group customers by the month of their first order, then track how many of each cohort placed a repeat order in subsequent months.
33. Find products that are "frequently bought together" — pairs of `product_id`s that commonly appear in the same `order_id` (self-join `order_items` to itself on `order_id`).
34. Using a correlated subquery, find sellers whose average review score is below the average review score of all sellers in the same state.
35. Calculate customer lifetime value (LTV) per customer and rank customers into percentiles using `NTILE()`.
36. Identify "at-risk" customers: those who ordered in the first half of the dataset's date range but have not ordered in the second half.
37. Build a query that pivots total revenue by month into columns (one column per month) using conditional aggregation (`SUM(CASE WHEN ...)`).
38. Find the average time gap between a customer's consecutive orders (needs `LAG()` on order date, partitioned by `customer_unique_id`).
39. Using `estimated_unit_cost` (synthetic column), calculate profit margin per category and rank categories by margin — clearly note this uses the practice/dummy cost field.
40. Create a view `vw_customer_summary` that consolidates order count, total spend, average review score, and preferred payment type per customer, then query it to find the top 20 highest-value customers.

---

### Suggested order to tackle these
Work through Level 1–2 first to get comfortable with joins across this schema (it has real gotchas: `customer_id` vs `customer_unique_id`, `order_item_id` being per-order not global, multi-row payments). Level 3–4 are the ones worth putting directly into your CV/GitHub repo as your "advanced queries" section.

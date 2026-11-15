# Olist Brazilian E-Commerce — Complete ER / Data-Flow Diagram

This diagram reflects the uploaded `schema&load_data.sql` script. It includes the seven final business tables and the two staging tables used during data preparation.

> **Schema accuracy note:** The script does not declare `PRIMARY KEY` or `FOREIGN KEY` constraints. The solid relationships below are logical joins inferred from matching columns, not database-enforced constraints. The script first creates a table named `orders` for line items, renames it to `order_items`, and then creates the order-header `orders` table.

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDERS : places
    ORDERS ||--o{ ORDER_ITEMS : contains
    PRODUCTS ||--o{ ORDER_ITEMS : included_in
    SELLERS ||--o{ ORDER_ITEMS : supplies
    ORDERS ||--o{ PAYMENTS : has
    ORDERS ||--o{ REVIEWS : receives

    CUSTOMER {
        varchar customer_id
        varchar customer_unique_id
        int zip_code_prefix
        varchar city
        char state_code
    }
    ORDERS {
        varchar order_id
        varchar customer_id
        varchar order_status
        varchar order_purchase_timestamp
        varchar order_approved_at
        varchar order_delivered_carrier_date
        varchar order_delivered_customer_date
        varchar order_estimated_delivery_date
    }
    ORDER_ITEMS {
        varchar order_id
        int order_item_id
        varchar product_id
        varchar seller_id
        varchar shipping_limit_date
        decimal price
        decimal freight_value
    }
    PRODUCTS {
        varchar product_id
        varchar product_name
        varchar product_category
    }
    SELLERS {
        varchar seller_id
        int zip_code_prefix
        varchar seller_city
        varchar seller_state
    }
    PAYMENTS {
        varchar order_id
        int payment_sequential
        varchar payment_type
        int installment_number
        decimal payment_value
    }
    REVIEWS {
        varchar review_id
        varchar order_id
        int socre
    }
```

## Staging data flow

- `product_draft` → `products`: the script loads the source product CSV into `product_draft`, then inserts the selected product columns into `products`.
- `reviews_draft` → `reviews`: the script loads and cleans review data in `reviews_draft`, then inserts `review_id`, `order_id`, and `socre` into `reviews`.

`product_draft` and `reviews_draft` are staging tables, not additional business entities in the final analytical model.

## Table roles

| Table | Role |
|---|---|
| `customer` | Customer attributes and location |
| `orders` | One order-header record per order (intended grain) |
| `order_items` | Product/seller line items, price and freight |
| `products` | Product attributes and category |
| `sellers` | Seller attributes and location |
| `payments` | Payment records; multiple sequences can belong to one order |
| `reviews` | Selected review identifiers, order IDs and scores |
| `product_draft` | Product import and cleaning stage |
| `reviews_draft` | Review import and cleaning stage |

## Important modeling notes

- `customer_id` links `customer` to `orders`; `customer_unique_id` represents the underlying person across order-level customer IDs.
- `order_items` is the line-item table and joins to `orders`, `products`, and `sellers`.
- `payments` and `reviews` join to `orders` using `order_id`.
- The uploaded script does not declare primary keys or foreign keys. Validate uniqueness and orphan records before adding constraints.
- Column spellings such as `product_catagory` and `socre` are preserved from the uploaded script.

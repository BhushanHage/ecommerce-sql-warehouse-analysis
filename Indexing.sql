-- Creating the Index on the Tables for the Easy operation on the Tables 


--===========================
--Orders table
--===========================

--1. cluster column store on PK
create clustered columnstore index
Pk_Index on orders

--2. non-cluster on the order_status
create index idx_order_status on orders (order_status)

--3 NON cluster index on the Customer for the Joins
create index idx_order_customer on orders(customer_id)

--4 index for the Purchase Date for the 
create index idx_order_purchase_date on orders(order_purchase_timestamp)

--=================================
-- Customer Table
--=================================
--1. cluster column store on PK
create clustered  index ix_pk_customer on customer(customer_id)

--2. Row store index on the Customer Unique id 
create index idx_customer_unique on customer(customer_unique_id)

--============================
-- Order Items 
--===========================
--1. clustered row stored index on order_items by (order_id,order_item_id)
create clustered index ixd_CRI_order_items_pk on order_items(order_id,order_item_id)

--2. for the ELT opration through the product ID 
create index idx_order_items_product_id on order_items(product_id)

--3. for the ELT opration through the Seller ID 
create index idx_order_items_seller on order_items(seller_id)


--4. For the Analytcial Opration on the table (group by ,Aggration )
create columnstore index idx_NCCI_order_items_analytics on order_items
	(product_id,seller_id, price, freight_value, estimated_unit_cost)


--====================================
--Product Table 
--====================================

--1. creating the index on PK clustered for the efficient opratation like join and OLTP 
create clustered index idx_product_pk on order_product(product_id)


--2. searching the product by the catogory aggragatation by catogary
create index idx_product_catogory on order_product(product_category_name)



--============================================
--Seller Table 
--===========================================
create clustered index PK_order_seller on order_seller(seller_id)

-- 2.for the city clustering but in other table 
create index idx_order_seller_city on order_seller(seller_city)


--=======================================================
--Payment table 
--=======================================================

--1. for the easy searcching of the payment by the orders 
create clustered index idx_payment_order_sequential on order_payment(order_id,payment_sequential)

--2. for the filtering the rows by the payment type 
create index idx_payment_type on order_payment(payment_type)



--========================================================
--Order Reviews
--========================================================
--1. searching the table 
create clustered index  idx_PK_review on order_review(review_id)

--2. for the filtering anfd joining of the table with other table 
create index idx_review_orders_scores on order_review(order_id,review_score)



--==========================================
--Geolocation Table 
--==========================================
--1. fort the searching of the Location no other operation is needed 
create clustered index idx_geo_zip_code_pk on order_gio(geolocation_zip_code_prefix)


--========================
--Order Catogary Name Table
--===========================

--NOTE:
--		Beacuse of this table is small so preffer to not create any index on it


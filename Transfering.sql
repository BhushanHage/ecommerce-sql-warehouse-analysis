

--============================================
--1.ORDERS
--======================================
alter table orders 
alter column order_purchase_timestamp  datetime
alter table orders 
alter column order_approved_at datetime
alter table orders 
alter column order_delivered_carrier_date datetime
alter table orders 
alter column order_delivered_customer_date datetime
alter table orders 
alter column order_estimated_delivery_date datetime

alter table orders
alter column order_id varchar(50)   not null 

alter table orders
add constraint PK_orders
primary key (order_id);


alter table orders
add constraint FK_orders_customers
foreign key (customer_id)
references customer(customer_id)

select * from orders where customer_id is null
select * from orders where order_status is null or  order_status =''
select * from orders where order_delivered_customer_date is null


--================================
--2.customers
--==========================

alter table customer
alter column customer_id varchar(50) not null


alter table customer 
add constraint PK_customer
Primary key(customer_id)



---========================================
--3.Products
--================================
select * from products


alter table products 
alter column product_id varchar(50) not null 

alter table products 
add constraint  PK_products
primary key (product_id)


-- replace the NULL in the Product Category Column with 'UNKNOWN'
update products
set product_category='UNKNOWN'
where product_category is null

select * from products where product_id is null
select * from products where product_category is null

--==========================================
--4.Seller
--===============================

select * from sellers where seller_city is null

alter table sellers
alter column seller_id varchar(50) not null


alter table  sellers
add constraint PK_sellers
primary key (seller_id)


--====================================
--5.order items
--=====================

--inspectin the table
select * from order_items where seller_id is null
select * from order_items where product_id is null

select * from order_items where price<=0 or freight_value<=0

alter table order_items
alter column shipping_limit_date datetime


alter table order_items
alter column order_id varchar(50) not null
alter table order_items
alter column order_item_id int not null

alter table order_items 
add constraint PK_order_items
primary key(order_id,order_item_id)

alter table order_items
add constraint FK_order_items_product
foreign key (product_id)
references products(product_id)

alter table order_items
add constraint FK_order_items_seller
foreign key (seller_id)
references sellers(seller_id)

--------------------------
-- checking the date is the convertable in to DATETIME tor not

SELECT 
    shipping_limit_date,
    TRY_CONVERT(
        datetime,
        LEFT(shipping_limit_date, 10) + ' ' +
        REPLACE(SUBSTRING(shipping_limit_date, 12, 5), '.', ':'),
        105
    ) AS converted_date
FROM  order_items



-- adding the new colum to the table shipping_date_time
alter table order_items
add  shipping_date_time datetime NULL

--inserteing the date time into the eshipping_date_time as DATETIME
update  order_items
set shipping_date_time=try_convert( datetime,left(shipping_limit_date,10)+' '+
replace(substring(shipping_limit_date,12,5),'.',':'),105)



 -- droping column 'shipping_limit_date' which is not useful now
alter table order_items
drop column shipping_limit_date


--=============================
--6.Payment
--========================

alter table payments
alter column order_id varchar(50) not null

alter table payments
alter column payment_sequential int not null

alter table payments
add constraint PK_payment
primary key(order_id,payment_sequential)

--====================================\
--7.Reviews
--==========
alter table reviews 
add constraint PK_review_id 
primary key( review_id,order_id)




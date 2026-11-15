create database Project_3
use project_3
--=========================================================
--Customers
--==========================================================
-- Creating the customer column 
create table customer (
customer_id varchar(50) ,
customer_unique_id varchar(50) not null,
zip_code_prefix int,
city varchar(50),
state_code char(10)
)


-- inserting the data in the customer table 
bulk insert customer from 
'....\data\olist_customers_dataset.csv'  -- actual path
with( format='csv',
 with (
format='CSV',
firstrow =2,
fieldterminator=',',
rowterminator='0x0a'
)
--======================================================
--Products
--======================================================
-- creating the product Draft table for the 
--extraing the only needed informatin in the product table
create table product_draft (

product_id varchar(50),
product_name varchar(100),
product_catagory varchar(100),
p_name_length int default null,
p_description_len int default null,
p_photo_qty int default null,
p_weight_g int default null,
p_length_cm int default null,
p_height_cm int default null,
p_width int  default null
)

-- drop constain related to the column type 

alter table product_draft
drop constraint DF__product_d__p_nam__5EBF139D



---alter the column d-type for the null Handling nulls as the part of the string 
alter table product_draft 
alter column p_name_length varchar(50);
alter table product_draft 
alter column p_photo_qty varchar(50);
alter table product_draft 
alter column p_weight_g varchar(50);
alter table product_draft 
alter column p_length_cm varchar(50);
alter table product_draft 
alter column p_height_cm varchar(50);
alter table product_draft 
alter column p_width varchar(50);
alter table product_draft 
alter column
p_description_len varchar(50)

-- inserting the data in to the Product Draft 
bulk insert product_draft from '....\data\olist_products_dataset.csv'   -- actual path
with( format='csv',
with
(
	format='csv'
	,firstrow=2
	,fieldterminator=',',
	rowterminator='0x0a'
)
--inspectin the culumd of the Product Draft
select * from sys.columns where OBJECT_ID=1573580644

create table products (
product_id varchar(50),
product_name varchar(100),
product_category varchar(50)
)
insert into products (
product_id,
product_name,
product_category
) select  
product_id,
product_name,
product_catagory from product_draft


select * from products


--==================================
--Order Items 
--==================================
--- Creating the orders table 
create table orders (
order_id varchar(50),
order_item_id int,
product_id varchar(50),
seller_id varchar(50),
shipping_limit_date date,
price decimal(10,2),
freight_value decimal(10,2)
)
alter table orders 
alter column shipping_limit_date varchar(50)


--inserting the data into orders
bulk insert  orders
from '...\data\olist_order_items_dataset.csv'   -- actual path
with( format='csv',
with(format='csv',
firstrow=2,
fieldterminator=',',
rowterminator='0x0a'
)

exec sys.sp_rename 'orders','order_items'

--=======================================
--Sellers
--==================================
create table sellers (

seller_id varchar(50),
zip_code_prefix int,
seller_city varchar(50),
seller_state varchar(50)


)

bulk insert sellers 
from '...\data\olist_sellers_dataset.csv' -- actual path
with( format='csv',
with (format='csv',
firstrow=2,
fieldterminator=',',
rowterminator='0x0a')


--==========================================================
--payments
--================================================
create table payments (
order_id varchar(50),
payment_sequential int,
payment_type varchar(20),
installment_number int,
payment_value decimal(10,2)
)


bulk insert payments 
from '...\data\olist_order_payments_dataset.csv' -- actual path
with( format='csv',
with(format='csv',
firstrow=2,
fieldterminator=',',
rowterminator='0x0a'
)

--=============================================
--Orders 
--=========================================

create table orders(
order_id varchar(50),
customer_id varchar(50),
order_status varchar(30),
order_purchase_timestamp varchar(50),
order_approved_at varchar(50),
order_delivered_carrier_date varchar(50),
order_delivered_customer_date varchar(50),
order_estimated_delivery_date varchar (50)

)


bulk insert orders 
from '...\data\olist_orders_dataset.csv' -- actual path
with( format='csv',
with(format='csv',
firstrow=2,
fieldterminator=',',
rowterminator='0x0a'
)

create table reviews_draft (review_id varchar(50) not null,
order_id varchar(50) not null
,socre int check (socre between 0  and 5) ,
review_comment_title varchar(50),
message VARCHAR(150),
review_creation_date varchar(50),
review_answer_timestamp varchar(50)


)
alter table reviews_draft 
alter column message varchar(300)  

bulk insert reviews_draft 
from '...\data\olist_order_reviews_dataset.csv' -- actual path
with( format='csv',
firstrow =2,
fieldterminator=',',
rowterminator='0x0a')

alter table reviews_draft
alter column review_creation_date datetime

alter table reviews_draft
alter column review_answer_timestamp datetime


create table reviews 
(review_id varchar(50) not null,
order_id varchar(50) not null
,socre int check (socre between 0  and 5) ,
)
insert  into reviews  ( review_id ,
order_id 
,socre ) 
select review_id ,
order_id 
,socre  from reviews_draft



--extract details of the tables 
select * from orders
select * from payments
select * from sellers
select * from order_items
select * from products
select * from customer
select * from reviews

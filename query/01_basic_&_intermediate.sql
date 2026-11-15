-- To get All info of the given tables 
 
select * from order_items
select * from sellers
select * from products
select * from orders;
select * from customer;
select * from payments
use project_3 


--===================================================================
--## Level 1 — Basics (SELECT, WHERE, ORDER BY, simple aggregates)
--===================================================================

--1. List all distinct order statuses that exist in `olist_orders_dataset`.
select  order_status ,count(*) cnt_statueses  from orders with (index (idx_order_status)) group by order_status  ;



--2. Find all orders placed in a specific month/year (e.g., January 2018).
select 
	order_id,
	datename(MM,order_purchase_timestamp)+ ' '+cast(year(order_purchase_timestamp) as varchar) Month_of_purchase

from orders 
order by order_purchase_timestamp


--3. Get the top 10 most expensive items from `olist_order_items_dataset` by `price
select p.* from products p
join (select distinct top 10 product_id ,price from order_items order by price) t
on t.product_id=p.product_id


--4. Count the total number of customers per `customer_state`
select 
	state_code
	,count(*) [No of Customers] 
	from customer 
	group by state_code
	order by count(*) desc


--5. Find all products belonging to a given `product_category_name`.
create procedure p1 @var varchar(100)
as 
begin
select product_name,product_category from products  where product_category=@var
end
exec p1 @var= 'relogios_presentes'



--7. List all sellers located in a specific state, sorted by city name.

create procedure seller_in_state @var varchar(100) =null as 
begin 
	select * from sellers where seller_state=@var order by seller_city asc
end
exec seller_in_state @var='GO'



--8. Find the minimum and maximum `review_score` given in `olist_order_reviews_dataset`.
select min(score) min_review,max(score) max_review from reviews 



--9. Count how many orders have each `payment_type` (credit card, boleto, voucher, etc.).
select payment_type,
count(*) [No of Payments] 
from payments
group by payment_type  
order by count(*)desc



--10. Find all orders that were `canceled` or `unavailable`.
select * from orders where order_status in('canceled', 'unavailable')



--================================================================================
--## Level 2 — Intermediate (JOINs, GROUP BY, HAVING)
--=================================================================================

--11. For each order, calculate total order value (sum of item prices + freight) — join `orders` with `order_items`.
select o.order_id,sum(price+freight_value) value  from orders o
join order_items oi
on o.order_id=oi.order_id
group by o.order_id


--12. Find the top 10 best-selling products by total quantity sold (join `order_items` with `products`).
select  
top 10
	product_name,
	count(p.product_id) Quantity_sold
from order_items oi
join 
products p
on oi.product_id=p.product_id
group by product_name
order by count(p.product_id) desc



--13. Calculate total revenue per product category 
--(join `order_items` → `products`, translate category name via `product_category_name_translation`).
select 
	p.product_category_name Catogory,
	sum(price)+sum(freight_value) Revenue
from order_items oi
join order_product p
on oi.product_id=p.product_id
group by p.product_category_name
order by sum(price)+sum(freight_value)  desc



--14. Find the number of orders and total revenue per customer state (join `orders` → `customers`).
select
	c.customer_unique_id,
	count(o.order_id) [No.of Orders],
	sum(p.payment_value) Revenue
from orders o
left join 
	customer c
	on o.customer_id=c.customer_id
left join 
	order_payment p
	on o.order_id=p.order_id
group by c.customer_unique_id
order by  sum(p.payment_value) desc


--15. Find sellers who have sold in more than 5 different product categories.
select   
 s.seller_id
 ,count(p.product_category_name) [Sold Product Category]
	from order_seller s
left join 
	order_items i 
	on s.seller_id=i.seller_id
left join 
	order_product p
	on i.product_id=p.product_id
group by s.seller_id
having count(p.product_category_name)>5
order by count(p.product_category_name) desc


--16. Find the average review score per product category.
select 
	p.product_name,
	avg(isnull(r.review_score,0)) AVG_Review_Score
from order_product p
left join order_items i
	on p.product_id=i.product_id
left join  order_review r
	on r.order_id=i.order_id
--where r.review_score is not NULL
group by p.product_name
order by avg(isnull(r.review_score,0)) desc



--17. Identify orders where the payment was split
--across more than one payment method (`payment_sequential` > 1).

select o.*  from orders o
inner join 
	(select distinct order_id
		from order_payment 
		where payment_sequential>1)p
on o.order_id=p.order_id

--18. Find customers who have placed more than one order 
-- remember to use `customer_unique_id`, not `customer_id`.

select 
	customer_unique_id,
	count(customer_id)  Placed_Orders
	from customer 

group by customer_unique_id
having count(customer_id)>1
order by count(customer_id)  desc


--19. List the top 10 sellers by total revenue generated, with seller city/state included.

select  top 10
	s.seller_id,
	SUM(PRICE)+sum(freight_value) [Revenue Generated]
from order_seller s
left join order_items i
	on i.seller_id=s.seller_id
group by s.seller_id
order by (SUM(PRICE)+sum(freight_value)) desc


--20. Find categories with more than 100 orders but an average review score below 4.

select p.product_category_name,count(i.order_id) [No of Orders],avg(r.review_score) AVG_Review from order_product p
join order_items i 
	on i.product_id=p.product_id
join order_review r
	on i.order_id=r.order_id
group by p.product_category_name
having count(i.order_id)>100 and avg(r.review_score)<4






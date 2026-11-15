select * from order_cat_name;
select * from order_review;
select * from order_items;
select * from order_seller;
select * from order_product;
select * from orders;
select * from customer;
select * from order_payment;
select * from order_gio;
select * from v_Revenue_Over_Order;
select * from v_Month_Over_Revenue;


--================================================================
--## Level 3 — Advanced (Window functions, CTEs, subqueries)
--================================================================

--21. Using a window function, rank products within each category by total revenue 
--(`RANK()` or `DENSE_RANK()` partitioned by category).

select p.product_category_name,sum(Revenue) Revenue,DENSE_RANK() over (order by sum(Revenue) desc) Rank  from order_product p
join (
select product_id,sum(price)+sum(freight_value) Revenue from order_items group by product_id
) t
on t.product_id=p.product_id
group by p.product_category_name


--22. Calculate month-over-month total revenue growth using `LAG()`.
	--Using the view *'dbo.v_Month_over_Revenue'*


select 
	format(dates,'MMMM yyyy') Month,
	Revenue,
	lag(Revenue) over (order by dates) Last_Month_Revenue,
	Round((Revenue-(lag(Revenue) over (order by dates)))/(lag(Revenue) over (order by dates))*100,2) MOM
	
	from v_Month_over_Revenue order by dates



--23. Write a CTE that first computes each customer's total spend, 
--then classifies customers into spend tiers (e.g., Low/Medium/High) using `CASE`.
	--Using the view *'dbo.v_Revenue_Over_Order'*

with customer_order_total as
(
	select customer_id,
		order_total 
	from orders o
	join v_Revenue_Over_Order ro   --View using 
	on o.order_id=ro.order_id
)
select customer_unique_id,
	sum( order_total) order_total,
	case 
		when sum(order_total)>300 then 'high'
		WHEN sum(order_total)>200 then 'Medium'
		else 'Low'
		end Customer_Spend
from customer c
join customer_order_total ot
	on c.customer_id=ot.customer_id
group by customer_unique_id


--24. Find the running (cumulative) total of revenue by month using `SUM() OVER (ORDER BY month)`.
	--Using the view *'dbo.v_Month_over_Revenue'*

select 
  format(dates,'MMMM yyyy') [Month Year],
  Revenue as Current_Month_Revenue,
  sum(revenue) over (order by dates Rows unbounded preceding) Total_Revenue

from dbo.v_Month_over_Revenue


--25. For each seller, find their best-selling product using a window function
--(`ROW_NUMBER()` partitioned by seller, ordered by quantity sold).

	--no of sold items by the each sellers 
	with sold_items as(
		select
			s.seller_id,
			oi.product_id,
			count(oi.product_id) Product_Sales ,
			row_number() over (partition by s.seller_id order by count(oi.product_id) desc ) Rank_items
		from order_seller s
		join order_items oi
			on s.seller_id=oi.seller_id
		group by s.seller_id,oi.product_id
	)
	--selling item and no of sales 
	select 
		seller_id,
			product_id,
			 Product_Sales from sold_items
	 where Rank_items=1


--26. Write a query to find customers
--whose total spend is above the overall average customer spend.
 

 select customer_unique_id,

  [Total Spend]
  
 from (
 select c.customer_unique_id,
 sum(order_total) [Total Spend], 
 avg(sum(order_total)) over () Avg_spend
 from customer c
 left join 
 orders o
 on c.customer_id=o.customer_id
 left join 
 v_Revenue_Over_Order  roo
 on roo.order_id=o.order_id
 group by c.customer_unique_id

 ) t
where Avg_spend>[Total Spend]

--27. Find the percentage contribution of each product category to total revenue, 
--using a window function for the grand total
		-- suing view 

select product_category_name,
Round(Sales*100.0/(sum(Sales) over() ),3)[Sales Preventage] 
from 
	(
	select isnull(p.product_category_name,'UNKNOWN') product_category_name,
		sum(price+freight_value) Sales
	from order_product p
	left join order_items i
		on p.product_id=i.product_id
	group by p.product_category_name)t


--28. Identify the top 3 categories by revenue in each customer state 
--(windowed ranking partitioned by state).

with details as(
select  o.customer_id,
	o.order_id,
	product_id,
	sales from orders o
	left join (
		select order_id,
			product_id,
			sum(price+freight_value) sales  
			from order_items ot
			group by order_id,
			product_id
	) t
	on o.order_id=t.order_id
),
product_catagory as(
	select product_id,
		ca.product_category_name_english
		from order_product p 
	join order_cat_name ca 
		on ca.product_category_name=p.product_category_name
),
sales_rk as(
	 select c.customer_state,
		 product_category_name_english,
		 sum(sales) Sales ,
		  DENSE_RANK() over (partition by Customer_state order by Sum(sales)desc ) rk
	 from customer c
	 left join details d
		on c.customer_id=d.customer_id
	 left join product_catagory pc
		on pc.product_id=d.product_id
	group by c.customer_state,product_category_name_english
 )
 select customer_state,
 product_category_name_english,
 Sales  from sales_rk
 where rk<4



--29. Calculate average delivery time (`order_delivered_customer_date` − `order_purchase_timestamp`) per state,
--excluding orders with null delivery dates.

select customer_state,
avg(datediff(day,order_purchase_timestamp,order_delivered_customer_date) ) Avg_Delivery_Days from customer c
join orders o
on o.customer_id=c.customer_id
where order_delivered_customer_date is not NULL
group by customer_state



--30. Find the late-delivery rate: percentage of orders where `order_delivered_customer_date`
--is later than `order_estimated_delivery_date`.

select 
	round(sum(
	case when order_delivered_customer_date<=order_estimated_delivery_date then 1
	end)*100.0/count(*) ,2) [Perctange orders on Time]
 from orders 


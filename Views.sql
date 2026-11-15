
--View Of the Month over sales 
create view v_Month_Over_Revenue as(

	select 
		DATETRUNC(month,order_purchase_timestamp) dates
		,sum(price + freight_value) Revenue
	from orders o
	join order_items i
		on o.order_id=i.order_id
	group by 
	 DATETRUNC(month,order_purchase_timestamp))



--Revenue Over
create view v_Revenue_Over_Order as(
select order_id,
		 sum(price+freight_value) order_total 
		 from order_items 
		 group by order_id
		 )
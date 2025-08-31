#Calculate total sales revenue and quantity sold by product category and customer_state.
select products.product_category, customers.customer_state,
round(sum(order_items.price),2) as sales_revenue,
sum(order_items.order_item_id) as quant_sold from 
order_items join orders on order_items.order_id =orders.order_id
join customers ON orders.customer_id = customers.customer_id
JOIN products ON order_items.product_id = products.product_id
GROUP BY products.product_category, customers.customer_state
ORDER BY sales_revenue DESC;

#Identify the top 5 products by total sales revenue across all Walmart regions.
with a as (SELECT p.product_id,
SUM(oi.price) AS total_sales_rev
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY 1)
select * from 
(select * ,dense_rank() over(order by total_sales_rev desc)
 rnk from a) b where rnk <=5;


#Find customers with the highest number of orders and total spend, 
#ranking them as Walmart’s most valuable customers.
SELECT  c.customer_id, c.customer_unique_id,
COUNT(distinct o.order_id) AS total_orders,
SUM(oi.price) AS total_spend FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_unique_id
ORDER BY total_spend desc,total_orders desc
LIMIT 10;

#Determine customer states with the highest average order value (AOV).
SELECT distinct customer_state, ROUND(AVG(order_value) 
over (PARTITION BY customer_state), 2) AS AOV from
( SELECT o.order_id, c.customer_state, 
SUM(oi.price) AS order_value
    from orders o
    join customers c on o.customer_id = c.customer_id
    join order_items oi on o.order_id = oi.order_id
    GROUP BY o.order_id, c.customer_state
) AS state_orders ORDER BY 2 desc
;

#Compute average delivery time (in days) by seller state, 
#calculated as the difference between order_purchase_timestamp and order_delivered_customer_date.
select s.seller_state,
avg(DATEDIFF(o.order_delivered_customer_date, 
o.order_purchase_timestamp)) as avg_del_days
from orders o
join order_items oi on o.order_id = oi.order_id
join sellers s on oi.seller_id = s.seller_id
where o.order_delivered_customer_date IS NOT NULL
AND o.order_purchase_timestamp IS NOT NULL
group by s.seller_state order by avg_del_days;

#List the top 5 sellers based on total revenue earned.
with a as (SELECT s.seller_id,s.seller_state,
round(SUM(oi.price),2) AS total_revenue
FROM sellers s JOIN 
order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id,s.seller_state)
select * from(
select *, dense_rank() over(order by total_revenue desc)
 rnk from a) b where rnk <=5;

#this one for same runs
select s.seller_id,s.seller_state,
round(SUM(oi.price),2) AS total_revenue
from sellers s
join order_items oi on s.seller_id = oi.seller_id
group by s.seller_id,s.seller_state
order by total_revenue desc
LIMIT 5;


#Analyze the monthly revenue trend over the last 12 months to track Walmart’s growth.
select 
date_format(o.order_purchase_timestamp, '%Y/%m') as months,
round(sum(oi.price),2) as monthly_revenue from orders o
join order_items oi on o.order_id = oi.order_id
where o.order_purchase_timestamp >= date_sub(
(select max(order_purchase_timestamp) from orders),
interval 12 month)
group by months order by months;


#Calculate the number of new unique customers acquired each month, based on customer_unique_id.
select 
date_format(first_buy_date, '%Y/%m') as months,
count(*) as new_customers from 
(select c.customer_unique_id, 
min(o.order_purchase_timestamp) as first_buy_date
from customers c
join orders o on c.customer_id = o.customer_id
group by c.customer_unique_id) as first_orders
group by 1 order by 1;



#Rank customers by lifetime spend within each customer state using SQL window functions.
select *,
rank() over (partition by customer_state 
order by total_spend desc) as rnk from (
select c.customer_state, c.customer_unique_id, 
SUM(oi.price) as total_spend from customers c
join orders o on c.customer_id = o.customer_id
join order_items oi on o.order_id = oi.order_id
group by c.customer_state, c.customer_unique_id)
as b;


#Compute the rolling 3-month average revenue trend, to visualize sales momentum.
select month, rev, ROUND(avg(rev) 
over (order by month rows between 2 preceding and current row), 2)
 as rolling_3_mon_avg from (
select DATE_FORMAT(o.order_purchase_timestamp, '%Y/%m') as month,
round(SUM(oi.price),2) as rev from orders o
join order_items oi on o.order_id = oi.order_id
group by month) AS monthly_revenue order by month;









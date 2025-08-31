#1
select stores.store_name, sum(order_items.quantity) quantity_sold
from stores join orders on stores.store_id = orders.store_id
join order_items on orders.order_id = order_items.order_id
group by  stores.store_name; 

#2
select products.product_name, orders.order_date, sum(order_items.quantity)
over(partition by products.product_name order by orders.order_date) total_quantity
from products join order_items on products.product_id = order_items.product_id
join orders on orders.order_id = order_items.order_id;

#3
with a as(select categories.category_name, products.product_name,
sum(order_items.quantity * order_items.list_price) sales 
from categories join products
on categories.category_id = products.category_id join order_items
on products.product_id = order_items.product_id 
group by categories.category_name, products.product_name) 
select category_name, product_name, sales from (select *, dense_rank() 
over (partition by category_name order by sales desc) 
rnk from a) b where rnk =1 ;

#4
with d as(select customers.customer_id,concat(customers.first_name, " ",customers.last_name)customer_name,
sum((order_items.quantity*order_items.list_price)-
(order_items.quantity*order_items.list_price)*((order_items.discount)/100)) amount_spent
from customers join orders on customers.customer_id = orders.customer_id
join order_items on order_items.order_id = orders.order_id
group by customers.customer_id )
select customer_name, amount_spent 
from(select *, rank() over(order by amount_spent desc)rnk from d) e where rnk =1;

#5
with x as(select categories.category_name, products.product_name, products.list_price from
products join categories on products.category_id = categories.category_id )
select * from
(select *, dense_rank() over(partition by categories.category_name order by list_price desc) rnk from x)
y where rnk =1 ;

#6
select distinct customers.customer_id,stores.store_name, count(orders.order_id)
from customers join orders on customers.customer_id = orders.customer_id
join stores on stores.store_id = orders.store_id
group by stores.store_name, customers.customer_id ;        

#7
select concat(staffs.first_name," ",staffs.last_name) staff_name from staffs
where staff_id not in (select staff_id from orders) ;

#8
with a as(select products.product_name, sum(order_items.quantity) quan from 
products join order_items on products.product_id =order_items.product_id
group by products.product_name)
select * from
(select * ,dense_rank() over(order by quan desc) rnk from a) b where rnk <=3 ;

#9
with a as(select list_price,row_number() over(order by list_price) pos, 
count(*)over() n from order_items)
select 
case
    when n % 2=0 then (select (avg(list_price)) from a
    where pos in ((n/2),(n/2)+1))
	else (select list_price from a where pos = ((n+1)/2))
    end as median from a limit 1 ;

#10
select products.product_name from products where not exists 
(select 1 from order_items where order_items.product_id = products.product_id) ;

#11
with a as(select staffs.first_name, coalesce(sum(order_items.quantity*order_items.list_price), 0) sales
from staffs left join orders on staffs.staff_id = orders.staff_id 
left join order_items on orders.order_id = order_items.order_id
group by staffs.first_name)

select * from a where sales > (select avg(sales) from a) ;

#12
select customers.customer_id, customers.first_name, count(order_items.product_id) tot_pdt
from customers join orders on customers.customer_id = orders.customer_id
join order_items on orders.order_id = order_items.order_id
join products on order_items.product_id = products.product_id
group by customers.customer_id, customers.first_name 
having count(distinct(category_id)) = (select count(category_id) from categories) 

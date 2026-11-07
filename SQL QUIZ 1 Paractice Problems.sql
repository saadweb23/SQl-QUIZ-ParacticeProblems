-------------------- Quiz NO 1-------------------------

--Q1. (LIKE, IN, ORDER BY with multiple columns) Return the first_name,
--last_name and city of customers who live in the state NY or CA, whose
--email ends in .com and whose last_name starts with the letter M. Sort
--by city ascending, then last_name ascending.

select 
first_name,
last_name,
city
from sales.customers
where state in ('NY' , 'CA') and
email like '%.com' and last_name like 'M%'
order by city , last_name;
--------------------------------------------------------------------------
--------------------------------------------------------------------------

--Q2. (Aliases, calculated column, ORDER BY, pagination) Show product_name,
--list_price and a calculated column called discounted_price (10% off)
--for products with a list_price above 500. Skip the 10 most expensive products
--and return the next 10 (the 11th to 20th most expensive).

select
product_name,
list_price,
list_price * 0.1 as Discounted_price
from production.products
where list_price > 500
order by list_price desc
offset 10 rows fetch next 10 rows only;

--------------------------------------------------------------------
--------------------------------------------------------------------

--Q3. (NULL, BETWEEN, AND/OR precedence) Find all orders that are either 
--Pending or Processing, have not shipped yet, and were placed between
--2018-01-01 and 2018-06-30. Return order_id, order_date, required_date and
--order_status. Your AND/OR logic must be explicitly grouped.

select
order_id ,
order_date,
required_date,
order_status,
shipped_date
from sales.orders
where shipped_date is Null and order_date between '2018-01-01' and 
'2018-06-30';

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--Q4. (Multi-table INNER JOIN, 5 tables) For all Completed orders placed
--in 2018, return the customer's full name, order_id, order_date,
--store_name, product_name and quantity. Sort by order_date, newest first.

select
c.first_name + ' ' + c.last_name as Customer_Name,
o.order_id,
o.order_date,
s.store_name,
p.product_name,
oi.quantity,
p.model_year
from sales.customers as c
inner join sales.orders as o
on c.customer_id = o.order_id
inner join sales.stores as s
on o.store_id = s.store_id
inner join sales.order_items as oi
on o.order_id = oi.order_id
inner join production.products as p
on oi.product_id = p.product_id
where p.model_year = 2018 order by o.order_date;


------------------------------------------------------------------------
------------------------------------------------------------------------

--Q5. (LEFT JOIN + NULL check, 4 tables) List every product that has never
--been sold, showing product_name, category_name and brand_name.

select
p.product_name,
c.category_name,
b.brand_name
from sales.order_items as oi
left join production.products as p
on oi.product_id = p.product_id
left join production.categories as c
on c.category_id = p.category_id
left join production.brands as b
on b.brand_id = p.brand_id
where oi.order_id is null;

--------------------------------------------------------------------
--------------------------------------------------------------------

--Q6. (Self join + extra join) Show every staff member's full name, their
--manager's full name (NULL for the top-level person) and the name of the
--store they work in.

select
E.first_name + ' ' + E.last_name as Employee_Name,
M.first_name + ' ' + M.last_name as Manager_Name,
s.store_name
from sales.staffs as E
Left join sales.staffs as M
on E.manager_id = M.staff_id
inner join sales.stores as s
on s.store_id = E.store_id;

---------------------------------------------------------------------
---------------------------------------------------------------------
--(a) Create a view sales.vw_order_details that joins orders, customers, 
--order_items and products and exposes: order_id, order_date, order_status,
--customer_id, first_name, last_name, product_name, quantity and a calculated 
--line_total (quantity × list_price × (1 − discount)).
create view sales.vw_orders
as
select 
o.order_id,
o.order_date,
o.order_status,
c.customer_id,
c.first_name,
c.last_name,
p.product_name,
oi.quantity,
oi.quantity * p.list_price * (1 - oi.discount) as line_Total 
from sales.customers as c
inner join sales.orders as o
on o.customer_id = c.customer_id
inner join sales.order_items as oi
on o.order_id = oi.order_id
inner join production.products as p
on oi.product_id = p.product_id;

---- Executing View

select * from sales.vw_orders;

------------------------------------------------------------------------
------------------------------------------------------------------------

--(b) Using only that view, return each customer's total spend on Completed
--orders, and keep only customers who spent more than 10,000. Sort by total
--spend, highest first.

select * from sales.vw_orders
where line_Total > 10000
order by line_Total desc;


--------------------------------------------------------------------------
--------------------------------------------------------------------------

--Q8. (GROUP BY on multiple columns, HAVING, COUNT DISTINCT, joins, top N)
--For each combination of category_name and brand_name, return the number 
--of distinct orders and the total revenue. Keep only combinations that appear
--in at least 20 distinct orders, and return the top 5 by revenue.

select Top 5
c.category_name,
b.brand_name,
count(distinct oi.order_id) as unique_order_IDs,
sum(oi.quantity * p.list_price * (1 - oi.discount)) as Total_Revenue
from production.products as p
inner join production.categories as c
on c.category_id = p.category_id
inner join production.brands as b
on b.brand_id = p.brand_id
inner join sales.order_items as oi
on oi.product_id = p.product_id
group by c.category_name , b.brand_name
having count(distinct oi.order_id) > 20
order by Total_Revenue; 

--------------------------------------------------------------------
--------------------------------------------------------------------

--Q9. (Aggregation across joins, YEAR(), COUNT DISTINCT) For each store and 
--each order year, return store_name, order_year, the number of distinct
--orders and total revenue. Sort by store_name, then order_year.

select
s.store_name,
year(o.order_date) as order_year,
count(distinct o.order_id) as Distinct_order,
sum (oi.quantity * oi.list_price * (1 - oi.discount)) as total_Revenue
from sales.orders as o
left join sales.stores as s
on o.store_id = s.store_id
left join sales.order_items as oi
on oi.order_id = o.order_id
group by store_name , o.order_date
order by store_name , order_year;


----------------------------------------------------------------------
----------------------------------------------------------------------

--Q10. (Nested subqueries, 4 levels of IN, no joins) Return the first
--and last names of customers who have ordered at least one product
--from the brand 'Electra'. Use only nested IN subqueries.

select
first_name,
last_name
from sales.customers as c
where customer_id IN 
(select customer_id from sales.orders as o where 
c.customer_id = o.customer_id  
(select 1 from production.brands where brand_name in ('Electra'));

----------------------------------------------------------------
----------------------------------------------------------------

--Q11. (NOT IN, NULL-safe) Find customers who have never placed an order.
--Make the query safe against NULL values in the subquery.

select
customer_id,
first_name,
last_name
from sales.customers as c
where exists 
(select 1 from sales.orders as o
where c.customer_id = o.customer_id);

-------------------------------------------------------------------------
-------------------------------------------------------------------------

--Q12. (Joins + derived table + scalar subquery) Return the categories
--whose total revenue is above the average total revenue across
--all categories. Show category_name and total_revenue, highest first.
select
avg(d.Total_Revenue) as Avg_Revenue
from 
(select
category_name,
sum(list_price) as Total_Revenue
from production.products as p
inner join production.categories as c
on c.category_id = p.category_id
group by category_name ) as d








































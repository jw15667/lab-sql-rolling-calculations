use sakila;

-- Get number of monthly active customers.
drop view customers_per_month;
create view customers_per_month as
select customer_id, inventory_id, rental_id, convert(rental_date, date) as customer_date, date_format(convert(rental_date, date), '%M') as rental_month,
date_format(convert(rental_date, date), '%m') as rental_month_num, date_format(convert(rental_date, date), '%Y') as rental_year
from rental;
select * from customers_per_month;

drop view monthly_active_customers;
create view monthly_active_customers as
select rental_month, rental_month_num, rental_year, customer_id, count(distinct customer_id) as total_monthly
from customers_per_month
group by rental_month, rental_year
order by rental_year, rental_month_num;

-- Active users in the previous month.

with cte_view as (select 
   total_monthly,
   rental_month_num,
   rental_year,
   lag(total_monthly,1) over (order by rental_month_num, rental_year) as Last_month_trans
from monthly_active_customers)
select rental_month_num, rental_year, total_monthly, Last_month_trans from cte_view;

select * from cte_view;




-- Percentage change in the number of active customers.


with cte_view as (select 
   total_monthly,
   rental_month_num,
   rental_year,
   lag(total_monthly,1) over (order by rental_year, rental_month_num) as Last_month_trans
from monthly_active_customers)
select rental_month_num, rental_year, CONCAT(round((((total_monthly - Last_month_trans) / total_monthly) *100), 2),'%') as Percent_Diff from cte_view
ORDER BY rental_year, rental_month_num;


-- Retained customers every month.

select 
   r1.rental_year,
   r1.rental_month_num,
   r1.customer_id,
   count(distinct r1.customer_id) as retained_customers
   from monthly_active_customers as r1
join monthly_active_customers as r2
on r1.customer_id = r2.customer_id 
and r1.rental_month_num = r2.rental_month_num + 1 
group by r1.rental_year, r1.rental_month_num
order by r1.rental_year, r1.rental_month_num;



with user_activity as (
  select account_id, convert(date, date) as Activity_date,
  date_format(convert(date,date), '%M') as Activity_Month,
  date_format(convert(date,date), '%Y') as Activity_year,
  convert(date_format(convert(date,date), '%m'),UNSIGNED) as month_number
  from bank.trans
),
distinct_users as (
  select distinct account_id, Activity_month, Activity_year, month_number
  from user_activity
)
select d1.account_id, d2.account_id, d1.Activity_month, d1.Activity_year
from distinct_users d1
left join distinct_users d2 on d1.account_id = d2.account_id and d1.month_number = d2.month_number + 1
where d1.Activity_month = 'December' and d1.Activity_year = 1998 and d2.account_id is null;
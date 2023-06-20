<!-- omit in toc -->
# Advanced SQL

<!-- omit in toc -->
## Description

Collection of advanced SQL from different exercises for reference.

<!-- omit in toc -->
## TOC
<!-- toc here -->
- [1. SQL Window Function Part 1](#1-sql-window-function-part-1)
	- [1.1. Fundamentals, the Over Clause and Partition By](#11-fundamentals-the-over-clause-and-partition-by)
	- [1.2. Other examples and Row Number and Order By (inside Over Clause)](#12-other-examples-and-row-number-and-order-by-inside-over-clause)
	- [1.3. Window Functions: Rank, Dense Rank](#13-window-functions-rank-dense-rank)
	- [1.4. Window Functions: Lead and Lag](#14-window-functions-lead-and-lag)
- [2. SQL Window Function Part 2](#2-sql-window-function-part-2)
	- [2.1. First and Last Value](#21-first-and-last-value)
	- [2.2. Frame Clause](#22-frame-clause)
	- [2.3. Windows Clause](#23-windows-clause)
	- [2.4. N-th Value](#24-n-th-value)
	- [2.5. Ntile](#25-ntile)
	- [2.6. Cumulative Distribution Cume_Dist](#26-cumulative-distribution-cume_dist)
	- [2.7. Percent Rank](#27-percent-rank)
- [3. SQL With Clause and CTE (Common Table Expression) or Sub-Query Factoring](#3-sql-with-clause-and-cte-common-table-expression-or-sub-query-factoring)
- [4. Practice Complex SQL Queries](#4-practice-complex-sql-queries)
	- [4.1. Exercise 1](#41-exercise-1)
	- [4.2. Exercise 2](#42-exercise-2)
	- [4.3. Exercise 3](#43-exercise-3)
	- [4.4. Exercise 4](#44-exercise-4)
	- [4.5. Exercise 5](#45-exercise-5)
	- [4.6. Exercise 6](#46-exercise-6)
	- [4.7. Exercise 7](#47-exercise-7)
	- [4.8. Exercise 9](#48-exercise-9)
- [5. Misc Notes](#5-misc-notes)
	- [5.1. Misc Notes from Revision](#51-misc-notes-from-revision)
	- [5.2. General Syntax:](#52-general-syntax)
- [6. Solutions to Codility Exercise](#6-solutions-to-codility-exercise)

# 1. SQL Window Function Part 1

## 1.1. Fundamentals, the Over Clause and Partition By
From [SQL Window Function](https://www.youtube.com/watch?v=Ww71knvhQ-s). [Documentation on Window Function](https://www.postgresql.org/docs/current/tutorial-window.html). [Documentation on Window Functions](https://www.postgresql.org/docs/8.4/functions-window.html).

A window function performs a calculation across a set of (table) rows that are somehow related to the current row. This is comparable to the type of calculation that can be done with an aggregate function. However, window functions do not cause rows to become grouped into a single output row like non-window aggregate calls would. Instead, the rows retain their separate identities. For example these queries:

```sql
select max(salary) as max_salary
from employee
```

```sql
select dept_name, max(salary) as max_salary_per_department
from employee
group by dept_name
```
Become these:

```sql
select e.*, max(salary) over() as max_salary
from employee as e
-- the over clause with no parameter produces a window of the whole table
```

```sql
select e.*, max(salary) over( partition by dept_name ) as max_salary_per_dept
from employee as e
-- shows max salary per deparment in addition to employee data
```

Note that the  rows considered by a window function are those of the “*virtual table*” produced by the query's `FROM` clause (as filtered by its `WHERE`, `GROUP BY`, and `HAVING` clauses if any). For example, a row removed because it does not meet the `WHERE` condition is **not** seen by any window function.

## 1.2. Other examples and Row Number and Order By (inside Over Clause)

```sql
select e.*, row_number() over() as rn
from employee e
-- gives each record a unique identifier; to use it, we can pass the query as a subquery
```

```sql
select e.*, row_number() over( partition by dept_name ) over() as rn
from employee e
-- gives each record per department an identifier
```

Note that You can also control the order in which rows are processed by window functions using ORDER BY within OVER. (The window ORDER BY does not even have to match the order in which the rows are returned). For example: 

```sql
SELECT depname, empno, salary, rank() OVER (PARTITION BY depname ORDER BY salary DESC)
FROM empsalary
```

From our previous example

```sql
select e.*, row_number() over(partition by dept_name order by emp_id) as rn
from employee e
-- We make the assumption that emp_id reflects when the employee joined the company
```

We use this query as a subquery to fetch the first 2 employees from each department to join the company

```sql
select *
from
  (select e.*, row_number() over(partition by dept_name order by emp_id) as rn from employee e) sq
where sq.rn < 3
```

## 1.3. Window Functions: Rank, Dense Rank

```sql
select e.*, rank() over(partition by dept_name order by salary desc) as rnk
from employee e
```

We use this subquery to determine the employees with the top 3 salaries per department

```sql
select *
from (select e.*, rank() over(partition by dept_name order by salary desc) as rnk
from employee e) sq
where sq.rnk < 4
```

```sql
select e.*, rank() over(partition by dept_name order by salary desc) as rnk, dense_rank() over(partition by dept_name order by salary desc) as dense_rnk
from employee e
```

Alternative:

```sql
select e.*, rank() over w as rnk, dense_rank() over w as dense_rnk
from employee e
window w as (partition by dept_name order by salary desc)
```

Note that when a query involves multiple window functions, it is possible to write out each one with a separate `OVER` clause, but this is duplicative and error-prone if the same windowing behavior is wanted for several functions. Instead, each windowing behavior can be named in a `WINDOW` clause and then referenced in `OVER`. For example:

```sql
SELECT sum(salary) OVER w, avg(salary) OVER w
  FROM empsalary
  WINDOW w AS (PARTITION BY depname ORDER BY salary DESC);
```

## 1.4. Window Functions: Lead and Lag

Task: Fetch a query to display if the salary of an employee is higher, lower or equal to the previous employee. **Preparation**:

```sql
select e.*, lag(salary) over (partition by dept_name order by emp_id) as prev_emp_salary
from employee e
```

We can pass some other arguments with the lag function (see [Documentation](https://www.postgresql.org/docs/8.4/functions-window.html)).

```sql
select e.*, lag(salary,2,0) over (partition by dept_name order by emp_id) as prev_emp_salary
from employee e
```

Lead gives us the rows that are following the current row.

```sql
select e.*, lead(salary) over (partition by dept_name order by emp_id) as next_emp_salary
from employee e
```

**Solution**:

```sql
select
  e.*,
  lag(salary) over w as prev_emp_salary,
  case
    when e.salary > lag(salary) over w then 'Higher than previous employee'
    when e.salary < lag(salary) over w then 'Lower than previous employee'
    when e.salary = lag(salary) over w then 'Same as previous employee'
  end sal_range
from employee e
window w as (partition by dept_name order by emp_id)
```

Another example from our database:

```sql
select
    p.payment_id,
    p.amount as current_amount,
    lag(amount) over w as prev_amount,
    case
        when amount > lag(amount) over w then 'Higher than previous amount'
        when amount < lag(amount) over w then 'Lower than previous amount'
        when lag(amount) over w is null then 'No info'
        else 'The same as previous amount'
    end as amount_range
from
    payment p window w as (
        partition by customer_id
        order by
            payment_date
    )
```

# 2. SQL Window Function Part 2

## 2.1. First and Last Value

From [SQL Window Function Part 2](https://www.youtube.com/watch?v=zAmJPdZu8Rg). [Documentation on Window Functions](https://www.postgresql.org/docs/8.4/functions-window.html). Task: Write a query to display the most expensive product under each category (corresponding ot each record).

```sql
select p.*, first_value(product_name) over(partition by product_category order by price desc) as most_exp_per_category
from product p
```

Task: Write a query to display the least expensive product under each category (corresponding to each record)

```sql
select *, last_value(product_name) over(partition by product_category order by price desc) as least_exp_product
from product
```

This delivers the wrong result! The reason is the default **frame clause**.

Note: Ideally we would use the `rank()` window function to accomplish this task. For example: 

```sql
with rk as 
(
	select
	payment_id, customer_id, amount, 
	rank() over (partition by customer_id order by amount asc) from payment
)

select * 
from rk
where rank = 1
order by customer_id
```


## 2.2. Frame Clause

Note that `first_value`, `last_value`, and `nth_value` consider only the rows within the "*window frame*", which by default contains the rows from the start of the partition through the last peer of the current row. This is likely to give unhelpful results for last_value and sometimes also nth_value. You can redefine the frame by adding a suitable frame specification (`RANGE` or `ROWS`) to the `OVER` clause. See Section 4.2.8 for more information about frame specifications. The default frame clause is:

```sql
select
  p.*,
  last_value(product_name) over(
    partition by product_category
    order by price desc
    range between unbounded preceding and current row
  )
from product p
```

To use the `last_value` window function, we need to adjust the frame clause:

```sql
select
  p.*,
  last_value(product_name) over(
    partition by product_category
    order by price desc
    range between unbounded preceding and unbounded following
  )
from product p
```

An alternative frame is the following:

To use the `last_value` window function, we need to adjust the frame clause:

```sql
select
  p.*,
  last_value(product_name) over(
    partition by product_category
    order by price desc
    rows between unbounded preceding and unbounded following
  )
from product p
```

This alternative becomes relevant when we have duplicates. `rows` considers the exact current row while `range` considers the last row of all duplicate values. `range` allows the current row to see ahead of itself into the last row with a duplicate value. We can also specify the number of rows:

```sql
select
  p.*,
  last_value(product_name) over(
    partition by product_category
    order by price desc
    rows between 2 preceding and 2 following
  )
from product p
```

An example from our database:

```sql
-- fetch lowest amount per customer
-- default frame: range between unbounded preceding and current row
select
	p.*,
	-- first_value(payment_id) over(partition by customer_id order by amount desc) as highest_payment,
	last_value(amount) over(
		partition by customer_id
		order by amount desc
		range between unbounded preceding and unbounded following
	) as lowest_payment
from payment p
-- order by amount
```

## 2.3. Windows Clause

```sql
select
  *,
  first_value(product_name) over w as most_exp_product,
  last_value(product_name) over w as least_exp_product
from product
window w as (partition by product_category order by price desc range between unbounded preceding and unbounded following)
-- order by
```

## 2.4. N-th Value

Fetch a value from any particular position. Task: Write a query to display the second most expensive product under each category. Note that `dense_rank()` is a better option here. 

```sql
select
  *,
  nth_value(product_name, 2) over(partition by product_category order by price desc) as second_most_expensive
from product
```

If the number of records is less that the parameter, the `nth_value` function will return `null`. This query won't display correctly for the first record (see `frame` clause above). We can fix this:

```sql
select
  *,
  nth_value(product_name, 2) over w as second_most_expensive
from product
window w as (partition by product_category order by price desc range between unbounded preceding and unbounded following)
```
## 2.5. Ntile

Task: Write a query to segregate all the expensive phones, mid range and the cheaper phones.

```sql
with phone_bucket as (
  select
    *,
    ntile(3) over (order by price desc) as bucket
  from product
  where product_category = 'Phone'
)

select
  product_name,
  case
    when bucket = 1 then 'Expensive Phone'
    when bucket = 2 then 'Mid Phone'
    when bucket = 3 then 'Cheaper Phone'
  end
from phone_bucket
```
## 2.6. Cumulative Distribution Cume_Dist

`cume_dist = sum (# of rows with the same value as the current row / # of rows)`

Task: Write a query to fetch all products which are constituting the first 30% of the data in products table based on price -> write a query to fetch the top 30% products based on price.

```sql
select
  *,
  cume_dist() over (order by price desc) as cume_dist_by_price
from product
-- cast cume_dist() to numeric to use round function
```

We can clean up the table:

```sql
select
  *,
  round(cume_dist() over (order by price desc)::numeric*100,2) as cume_dist_by_price
from product
-- cast cume_dist() to numeric to use round function
```

We can then use this query as a subquery and filter our data:

```sql
with cume_dist_t as (
  select
    *,
    round(cume_dist() over (order by price desc)::numeric*100,2) as cume_dist_by_price
from product
)

select product_name, (cume_dist_by_price || '%') as cume_dist_pct
from cume_dist_t
where cume_dist_by_price <= 30
```

## 2.7. Percent Rank

Similar to `cume_list`. Relative rank of the current row. `percent_rank = (# of current row - 1) / (# of rows -1)`

Task: Write a query to identify how much percentage more expensive is the phone "Galaxy Z Fold 3" when compared to all products

```sql
select
  *,
  round(percent_rank() over(order by price)::numeric*100,2) as pct_rank
from product
```

We use this as our subquery:

```sql
with pct_rank as (
  select
  *,
  round(percent_rank() over(order by price)::numeric*100,2) as pct_rank
  from product
)

select product_name, pct_rank
from pct_rank
where product_name = 'Galaxy Z Fold 3'
```

# 3. SQL With Clause and CTE (Common Table Expression) or Sub-Query Factoring

From [SQL WITH Clause](https://www.youtube.com/watch?v=QNfnuK-1YYY&).

Task: Find employees with a salary higher than the average.

```sql
with average_salary as (
  select avg(salary)::int
  from employee
)

select *
from employee, average_salary
where salary > average_salary
```

Task: Find stores with sales higher than the average across all stores.

```sql
-- find sales per store
select store_id, sum(cost) as sales_per_store
from sales
group by store_id

-- compute average revenue across all stores
select round(avg(sales_per_store)::numeric, 2) as avg_sales
from (
  select store_id, sum(cost) as sales_per_store
  from sales
  group by store_id
)

-- filter by the comparisson average revenue < store revenue
select *
from (
  select store_id, sum(cost) as sales_per_store
  from sales
  group by store_id
) sales_per_store
join (
  select round(avg(sales_per_store)::numeric, 2) as avg_sales
  from (
    select store_id, sum(cost) as sales_per_store
    from sales
    group by store_id
  ) sales_per_store
) avg_sales
on sales_per_store.sales_per_store > avg_sales.avg_sales
```

This query becomes:

```sql
with sales_per_store (store_id, sales_per_store) as (
  select store_id, sum(cost) as sales_per_store
  from sales
  group by store_id
), avg_sales (avg_sales) as (
  select round(avg(sales_per_store)::numeric, 2) as avg_sales
  from sales_per_store
)

select *
where sales_per_store > avg_sales
```

Example from our database:

```sql
with revenue (customer_id, revenue) as (
  select customer_id, rental_id * amount as revenue
  from payment
), revenue_per_store (customer_id, revenue_per_store) as (
  select customer_id, sum(revenue) as revenue_per_store
  from revenue
  group by customer_id
  order by customer_id
), avg_revenue (avg_revenue) as (
  select round(avg(revenue_per_store) :: numeric, 2) as avg_revenue
  from revenue_per_store
)

select customer_id, revenue_per_store
from revenue_per_store, avg_revenue
where revenue_per_store > avg_revenue
```

# 4. Practice Complex SQL Queries

From [Practice Complex SQL Queries](https://www.youtube.com/watch?v=FNYdBLwZ6cE).

## 4.1. Exercise 1

```sql
-- Query 1:
 -- Write a SQL query to fetch all the duplicate records from a table.
 --Tables Structure:

create table users (user_id int primary key, user_name varchar(30) not null, email varchar(50));

insert into users
values (1, 'Sumit', 'sumit@gmail.com'),
       (2, 'Reshma', 'reshma@gmail.com'),
       (3, 'Farhana', 'farhana@gmail.com'),
       (4, 'Robin', 'robin@gmail.com'),
       (5, 'Robin', 'robin@gmail.com'),
       (4, 'Robin', 'another_robin@gmail.com');


select *
from users;
```

Solutions:

```sql
select max(user_id), user_name, email
from users
group by user_name, email
having count(user_name) > 1 and count(email) > 1
```

Solution from video: Use a window function with `row_number()`.

```sql
with rn_dups as (
  select *, row_number() over(partition by user_name, email order by user_id) as rn
  from users
  order by user_id
)

select user_name, email, max(rn) as nr_of_dups
from rn_dups
where rn > 1
group by user_name, email
```

## 4.2. Exercise 2

```sql
-- Query 2:
-- Write a SQL query to fetch the second record from a employee table.

--Tables Structure:
-- drop table employee;
create table employee
( emp_ID int primary key
, emp_NAME varchar(50) not null
, DEPT_NAME varchar(50)
, SALARY int);

insert into employee values(101, 'Mohan', 'Admin', 4000);
insert into employee values(102, 'Rajkumar', 'HR', 3000);
insert into employee values(103, 'Akbar', 'IT', 4000);
insert into employee values(104, 'Dorvin', 'Finance', 6500);
insert into employee values(105, 'Rohit', 'HR', 3000);
insert into employee values(106, 'Rajesh',  'Finance', 5000);
insert into employee values(107, 'Preet', 'HR', 7000);
insert into employee values(108, 'Maryam', 'Admin', 4000);
insert into employee values(109, 'Sanjay', 'IT', 6500);
insert into employee values(110, 'Vasudha', 'IT', 7000);
insert into employee values(111, 'Melinda', 'IT', 8000);
insert into employee values(112, 'Komal', 'IT', 10000);
insert into employee values(113, 'Gautham', 'Admin', 2000);
insert into employee values(114, 'Manisha', 'HR', 3000);
insert into employee values(115, 'Chandni', 'IT', 4500);
insert into employee values(116, 'Satya', 'Finance', 6500);
insert into employee values(117, 'Adarsh', 'HR', 3500);
insert into employee values(118, 'Tejaswi', 'Finance', 5500);
insert into employee values(119, 'Cory', 'HR', 8000);
insert into employee values(120, 'Monica', 'Admin', 5000);
insert into employee values(121, 'Rosalin', 'IT', 6000);
insert into employee values(122, 'Ibrahim', 'IT', 8000);
insert into employee values(123, 'Vikram', 'IT', 8000);
insert into employee values(124, 'Dheeraj', 'IT', 11000);

select * from employee;
```

Solution:

```sql
with rn as (
	select *, row_number() over(order by emp_id) as rn
	from employee
)

select *
from rn
where rn = 2
```

## 4.3. Exercise 3

```sql
-- Query 3:

-- Write a SQL query to display only the details of employees who either earn the highest salary or the lowest salary in each department from the employee table.

--Tables Structure:

drop table employee;
create table employee
( emp_ID int primary key
, emp_NAME varchar(50) not null
, DEPT_NAME varchar(50)
, SALARY int);

insert into employee values(101, 'Mohan', 'Admin', 4000);
insert into employee values(102, 'Rajkumar', 'HR', 3000);
insert into employee values(103, 'Akbar', 'IT', 4000);
insert into employee values(104, 'Dorvin', 'Finance', 6500);
insert into employee values(105, 'Rohit', 'HR', 3000);
insert into employee values(106, 'Rajesh',  'Finance', 5000);
insert into employee values(107, 'Preet', 'HR', 7000);
insert into employee values(108, 'Maryam', 'Admin', 4000);
insert into employee values(109, 'Sanjay', 'IT', 6500);
insert into employee values(110, 'Vasudha', 'IT', 7000);
insert into employee values(111, 'Melinda', 'IT', 8000);
insert into employee values(112, 'Komal', 'IT', 10000);
insert into employee values(113, 'Gautham', 'Admin', 2000);
insert into employee values(114, 'Manisha', 'HR', 3000);
insert into employee values(115, 'Chandni', 'IT', 4500);
insert into employee values(116, 'Satya', 'Finance', 6500);
insert into employee values(117, 'Adarsh', 'HR', 3500);
insert into employee values(118, 'Tejaswi', 'Finance', 5500);
insert into employee values(119, 'Cory', 'HR', 8000);
insert into employee values(120, 'Monica', 'Admin', 5000);
insert into employee values(121, 'Rosalin', 'IT', 6000);
insert into employee values(122, 'Ibrahim', 'IT', 8000);
insert into employee values(123, 'Vikram', 'IT', 8000);
insert into employee values(124, 'Dheeraj', 'IT', 11000);

select * from employee;
```

Solution:

```sql
with max_salary as (
	select dept_name, max(salary)
	from employee
	group by dept_name
), min_salary as (
	select dept_name, min(salary)
	from employee
	group by dept_name
)

select
	e.emp_id, e.emp_name, e.dept_name, e.salary,
	case
		when e.salary = mas.max then 'Highest Salary'
		else 'Lowest Salary'
	end as description
from employee e, max_salary mas, min_salary mis
where
	e.dept_name = mas.dept_name and e.salary = mas.max or
	e.dept_name = mis.dept_name and e.salary = mis.min
order by e.dept_name, salary desc
```

Alternative with categorical column and delta: 

```sql
with lh as 
(select 
	*, 
	rank() over(partition by dept_name order by salary asc) as ls, 
	rank() over(partition by dept_name order by salary desc) as hs
from employee)

select 
	*, 
	case
		when ls = 1 then 'Lowest Salary in Dept'
		else 'Highest Salary in Dept'
	end as low_high, 
	first_value(salary) over(partition by dept_name order by salary desc) - 
	first_value(salary) over(partition by dept_name order by salary asc)
	as delta
from lh
where ls = 1 or hs = 1 
```

## 4.4. Exercise 4

```sql
-- Query 4:

-- From the doctors table, fetch the details of doctors who work in the same hospital but in different speciality.

--Table Structure:

-- drop table doctors;
create table doctors
(
id int primary key,
name varchar(50) not null,
speciality varchar(100),
hospital varchar(50),
city varchar(50),
consultation_fee int
);

insert into doctors values
(1, 'Dr. Shashank', 'Ayurveda', 'Apollo Hospital', 'Bangalore', 2500),
(2, 'Dr. Abdul', 'Homeopathy', 'Fortis Hospital', 'Bangalore', 2000),
(3, 'Dr. Shwetha', 'Homeopathy', 'KMC Hospital', 'Manipal', 1000),
(4, 'Dr. Murphy', 'Dermatology', 'KMC Hospital', 'Manipal', 1500),
(5, 'Dr. Farhana', 'Physician', 'Gleneagles Hospital', 'Bangalore', 1700),
(6, 'Dr. Maryam', 'Physician', 'Gleneagles Hospital', 'Bangalore', 1500);
```

Solution:

```sql
select l.* 
from doctors l join doctors r on 
	l.hospital = r.hospital and
	l.speciality != r.speciality
```

## 4.5. Exercise 5

```sql
-- Query 5:

-- From the login_details table, fetch the users who logged in consecutively 3 or more times.

--Table Structure:

-- drop table if exists login_details;
create table login_details(
login_id int primary key,
user_name varchar(50) not null,
login_date date);

delete from login_details;
insert into login_details values
(101, 'Michael', current_date),
(102, 'James', current_date),
(103, 'Stewart', current_date+1),
(104, 'Stewart', current_date+1),
(105, 'Stewart', current_date+1),
(106, 'Jimmy', current_date+2),
(107, 'Michael', current_date+2),
(108, 'Stewart', current_date+3),
(109, 'Stewart', current_date+3),
(110, 'James', current_date+4),
(111, 'James', current_date+4),
(112, 'James', current_date+5),
(113, 'James', current_date+6);
```

Solution:

```sql
with l as (
	select *, lag(user_name) over w as prev_user1, lag(user_name,2) over w as prev_user2
	from login_details
	window w as (order by login_date, login_id)
)

select *
from l
where user_name = prev_user1 and prev_user1 = prev_user2
```

Alternative solution:

```sql
with rep as (
	select
		*,
		case
			when lag(user_name) over (order by login_date) = user_name then 'repeat'
			else 'not repeat'
		end as rep
	from login_details
), cume_rep as (
	select
		*,
		case
			when rep = 'repeat' and lag(rep) over (order by login_date) = rep then 1
			else 0
		end as cume_rep
	from rep
)

select *
from cume_rep
where cume_rep = 1
```

Better alternative solution. This solution also counts the number of consecutive logins by the user.

```sql
with rep as (
	select
		*,
		case
			when lag(user_name) over(order by login_date) = user_name then 1
			else 0
		end as rep
	from login_details
), island_head as (
	select
		*,
		case
			when
				rep = 0 and lead(rep) over(order by login_date) = 1 then login_id
		end as island_head
	from rep
), island_id as(
	select
		*,
		case
			when rep = 1 then max(island_head) over(order by login_date)
			when rep = 0 then island_head
		end as island_id
	from island_head
)

select
	*,
	count(island_id) over(partition by island_id order by login_date rows between unbounded preceding and unbounded following)
from island_id
order by login_date, island_head
```

To make the result set more compact:

```sql
with rep as (
	select
		*,
		case
			when lag(user_name) over(order by login_date) = user_name then 1
			else 0
		end as rep
	from login_details
), island_head as (
	select
		*,
		case
			when
				rep = 0 and lead(rep) over(order by login_date) = 1 then login_id
		end as island_head
	from rep
), island_id as(
	select
		*,
		case
			when rep = 1 then max(island_head) over(order by login_date)
			when rep = 0 then island_head
		end as island_id
	from island_head
), island as(
	select
		*,
		count(island_id) over(partition by island_id order by login_date rows between unbounded preceding and unbounded following) as consecutive_logins
	from island_id
)

select  island_id, consecutive_logins, user_name
from island
where consecutive_logins != 0
group by island_id, consecutive_logins, user_name
order by island_id
```

## 4.6. Exercise 6

```sql
-- Query 6:
-- From the students table, write a SQL query to interchange the adjacent student names.
-- Note: If there are no adjacent student then the student name should stay the same.
--Table Structure:

-- drop table if exists students;
create table students
(
id int primary key,
student_name varchar(50) not null
);
insert into students values
(1, 'James'),
(2, 'Michael'),
(3, 'George'),
(4, 'Stewart'),
(5, 'Robin');

-- select * from students;
```

Solution:

```sql
select
	*,
	case
		when id % 2 = 1 then lead(student_name,1,student_name) over()
		when id % 2 = 0 then lag(student_name,1,student_name) over()
	end as new_student_name
from students
```

## 4.7. Exercise 7

```sql
-- Query 7:
-- From the weather table, fetch all the records when London had extremely cold temperature for 3 consecutive days or more.
-- Note: Weather is considered to be extremely cold then its temperature is less than zero.

--Table Structure:
-- drop table if exists weather;
create table weather
(
id int,
city varchar(50),
temperature int,
day date
);
delete from weather;
insert into weather values
(1, 'London', -1, to_date('2021-01-01','yyyy-mm-dd')),
(2, 'London', -2, to_date('2021-01-02','yyyy-mm-dd')),
(3, 'London', 4, to_date('2021-01-03','yyyy-mm-dd')),
(4, 'London', 1, to_date('2021-01-04','yyyy-mm-dd')),
(5, 'London', -2, to_date('2021-01-05','yyyy-mm-dd')),
(6, 'London', -5, to_date('2021-01-06','yyyy-mm-dd')),
(7, 'London', -7, to_date('2021-01-07','yyyy-mm-dd')),
(8, 'London', 5, to_date('2021-01-08','yyyy-mm-dd'));

-- select * from weather;
```

Solution:

```sql
with
streak as (
  select 
	*,
	case
		when temperature < 0 and lag(temperature) over (order by id) >= 0 then id
		when temperature < 0 then 1 --handles the last record
	end as streak
from weather),
island_id as (
	select
		*,
		case
			when streak is not null then max(streak) over(order by id)
		end as island_id
		from streak),
island_size as (
	select
		*,
		count(island_id) over(partition by island_id order by id rows between unbounded preceding and unbounded following) as island_size
	from island_id
)

select id, city, temperature, day, island_size
from island_size
where island_size >= 3
order by id
```

## 4.8. Exercise 9

We skipped exercise 9 because the task was not clear.

```sql
-- Query 9:
-- Find the top 2 accounts with the maximum number of unique patients on a monthly basis.
-- Note: Prefer the account if with the least value in case of same number of unique patients

--Table Structure:

-- drop table if exists patient_logs;
create table patient_logs
(
  account_id int,
  date date,
  patient_id int
);

insert into patient_logs values (1, to_date('02-01-2020','dd-mm-yyyy'), 100);
insert into patient_logs values (1, to_date('27-01-2020','dd-mm-yyyy'), 200);
insert into patient_logs values (2, to_date('01-01-2020','dd-mm-yyyy'), 300);
insert into patient_logs values (2, to_date('21-01-2020','dd-mm-yyyy'), 400);
insert into patient_logs values (2, to_date('21-01-2020','dd-mm-yyyy'), 300);
insert into patient_logs values (2, to_date('01-01-2020','dd-mm-yyyy'), 500);
insert into patient_logs values (3, to_date('20-01-2020','dd-mm-yyyy'), 400);
insert into patient_logs values (1, to_date('04-03-2020','dd-mm-yyyy'), 500);
insert into patient_logs values (3, to_date('20-01-2020','dd-mm-yyyy'), 450);

select * from patient_logs;
```

Solution:

```sql
with dp as
  (select distinct to_char(date, 'month') as month,
                   account_id,
                   patient_id
   from patient_logs
   order by month),
     c as
  (select month,
          account_id,
          count(account_id) as c
   from dp
   group by month, account_id),
     r as
  (select *,
          rank() over(partition by month order by c desc, account_id) as rnk
   from c)
select *
from r
where rnk < 3
order by month, rnk
```

# 5. Misc Notes

- [SQL Cheat Sheet](https://www.sqltutorial.org/wp-content/uploads/2016/04/SQL-cheat-sheet.pdf):
  - `limit` n `offset` m: skip m row and return the next n rows.
- Use column names `create_date` (date) and `last_update` (timestamp without timezone).
- A **database** is a collection of tables. **Tables** contain rows and columns, where the rows are known as records and the columns are known as fields. A **column** is a set of data values of a particular type, one value for each row of the database. A **row** represents a single data item in a table, and every row in the table has the same structure.
- [Single vs Double Quotes](https://stackoverflow.com/questions/41396195/what-is-the-difference-between-single-quotes-and-double-quotes-in-postgresql): **Double quotes** are for names of **tables** or **fields**. Sometimes You can omit them. The **single quotes** are for **string constants**. This is the SQL standard. In the verbose form, your query looks like this:

```sql
select * from "table1" where "column1"='name1';
```

- SQL `COUNT` function is the simplest function and very useful in counting the number of records, which are expected to be returned by a SELECT statement.
- [SQL SELECT with DISTINCT on multiple columns](https://www.w3resource.com/sql/select-statement/queries-with-distinct-multiple-columns.php)
- Additional PgSQL keywords and functions:
  - length()
  - offset
- [PgSQL Pattern Matching](https://www.postgresql.org/docs/13/functions-matching.html): Be wary of accepting regular-expression search patterns from hostile sources. If you must do so, it is advisable to impose a statement timeout.
Searches using `SIMILAR TO` patterns have the same security hazards, since `SIMILAR TO` provides many of the same capabilities as POSIX-style regular expressions.
`LIKE` searches, being much simpler than the other two options, are safer to use with possibly-hostile pattern sources.
- [W3 SQL Tutorial](https://www.w3schools.com/sql/default.asp)
- [Full Text Search PostgreSQL](https://www.youtube.com/watch?v=szfUbzsKvtE)
- [Learn PostgreSQL Tutorial - Full Course for Beginners](https://www.youtube.com/watch?v=qw--VYLpxG4)
- [Official Tutorials and Other Resources](https://www.postgresql.org/docs/online-resources/)
- [EDB Offer](https://www.enterprisedb.com/training/free-postgres-training)
- [Tutorials point](https://www.tutorialspoint.com/postgresql/)
- [Show all tables](https://www.postgresqltutorial.com/postgresql-show-tables/):

```sql
SELECT * FROM pg_catalog.pg_tables
WHERE schemaname != 'pg_catalog' AND
      schemaname != 'information_schema';
```

- [A Visual Explanation of SQL Joins](https://blog.codinghorror.com/a-visual-explanation-of-sql-joins/)
- [Join (SQL) Wiki](https://en.wikipedia.org/wiki/Join_(SQL))
- [Table Covert Online](https://tableconvert.com/)
- [Math Symbols List](https://www.rapidtables.com/math/symbols/Basic_Math_Symbols.html)
- [Casting columns to date](https://stackoverflow.com/questions/5875712/postgresql-select-something-where-date-01-01-11)
- [Transpose Results](https://stackoverflow.com/questions/23060256/postgres-transpose-rows-to-columns)
- [Dollar Quoting](https://stackoverflow.com/questions/12144284/what-are-used-for-in-pl-pgsql)
- [Delete duplicate records](https://stackoverflow.com/questions/6583916/delete-duplicate-rows-from-small-table)
- [Creating multiple tables with sqlite3](https://gist.github.com/iampramodyadav/793ec2b0ea71c3bcbfd6deea636907e2)

## 5.1. Misc Notes from Revision

- `not` keyword appears before the condition
- `order by`-columns also appears in `select`-column
- if we `group by` -> `select`-columns appear in:
  - `group by`-statement OR
  - are in an aggregate function
- column in `select` -> column in `group by`
- aggregate function appear in:
  - `select` OR
  - `having`

## 5.2. General Syntax: 

```sql 
select
	count distinct
from 
where
	=<> 
	is null
	in ()
	between x and y 
	like 
	ilike
group by 
having 
order by 
limit 
offset
```


# 6. Solutions to Codility Exercise

```sql
select distinct(event_type), nth_value(delta, 1) over(partition by event_type) as value
from
	(select e.*, lag(value) over( partition by event_type order by time desc) - value as delta
	from events e
	order by event_type) delta
where delta is not null
order by event_type
```

Alternative (since we remove the null values with the `where` clause and parameter of nth_value is 1):

```sql
select distinct(event_type), first_value(delta) over(partition by event_type) as value
from
	(select e.*, lag(value) over( partition by event_type order by time desc) - value as delta
	from events e
	order by event_type) delta
where delta is not null
order by event_type
```

Alternative with `with` as syntactic convenience to make the query more readable.

```sql
with delta as (
  select e.*, lag(value) over( partition by event_type order by time desc) - value as delta
  from events e
	order by event_type
)

select distinct(event_type), first_value(delta) over(partition by event_type) as value
from delta
where delta is not null
order by event_type
```

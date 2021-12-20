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
- [5. Solutions to Codility Exercise](#5-solutions-to-codility-exercise)

# 1. SQL Window Function Part 1

## 1.1. Fundamentals, the Over Clause and Partition By
From [SQL Window Function](https://www.youtube.com/watch?v=Ww71knvhQ-s). [Documentation on Window Function](https://www.postgresql.org/docs/current/tutorial-window.html). [Documentation on Window Functions](https://www.postgresql.org/docs/8.4/functions-window.html).

A window function performs a calculation across a set of table rows that are somehow related to the current row. This is comparable to the type of calculation that can be done with an aggregate function. However, window functions do not cause rows to become grouped into a single output row like non-window aggregate calls would. Instead, the rows retain their separate identities. For example these queries:

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

Notes that the  rows considered by a window function are those of the “*virtual table*” produced by the query's `FROM` clause (as filtered by its `WHERE`, `GROUP BY`, and `HAVING` clauses if any). For example, a row removed because it does not meet the WHERE condition is not seen by any window function.

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

Note that You can also control the order in which rows are processed by window functions using ORDER BY within OVER. (The window ORDER BY does not even have to match the order in which the rows are output.) Here is an example:

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
where hq.rn < 3
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
window w as over(partition by dept_name order by salary desc)
```

Note that when a query involves multiple window functions, it is possible to write out each one with a separate OVER clause, but this is duplicative and error-prone if the same windowing behavior is wanted for several functions. Instead, each windowing behavior can be named in a WINDOW clause and then referenced in OVER. For example:

```sql
SELECT sum(salary) OVER w, avg(salary) OVER w
  FROM empsalary
  WINDOW w AS (PARTITION BY depname ORDER BY salary DESC);
```

## 1.4. Window Functions: Lead and Lag

Task: Fetch a query to display if the salary of an employee is higher, lower or equal to the previous employee. **Preparation**:

```sql
select e.*, lag(salary) over (partition over dept_name order by emp_id) as prev_emp_salary
from employee e
```

We can pass some other arguments with the lag function (see [Documentation](https://www.postgresql.org/docs/8.4/functions-window.html)).

```sql
select e.*, lag(salary,2,0) over (partition over dept_name order by emp_id) as prev_emp_salary
from employee e
```

Lead gives us the rows that are following the current row.

```sql
select e.*, lead(salary) over (partition over dept_name order by emp_id) as next_emp_salary
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
window w as (partition over dept_name order by emp_id)
```

Another example from our database:

```sql
select
	p.*,
	lag(amount) over w1 as prev_amount,
	case
		when amount > lag(amount) over w2 then 'Higher than previous amount'
		when amount < lag(amount) over w2 then 'Lower than previous amount'
		when lag(amount) over w2  is null then 'No info'
		else 'The same as previous amount'
	end as amount_range
from payment p
window w1 as (partition by customer_id order by payment_date), w2 as (partition by customer_id order by payment_date)
-- note that w1 and w2 are identical
```

The same example more concise:

```sql
select
	p.*,
	lag(amount) over w as prev_amount,
	case
		when amount > lag(amount) over w then 'Higher than previous amount'
		when amount < lag(amount) over w then 'Lower than previous amount'
		when lag(amount) over w  is null then 'No info'
		else 'The same as previous amount'
	end as amount_range
from payment p
window w as (partition by customer_id order by payment_date)
```

# 2. SQL Window Function Part 2

## 2.1. First and Last Value

From [SQL Window Function Part 2](https://www.youtube.com/watch?v=zAmJPdZu8Rg). [Documentation on Window Functions](https://www.postgresql.org/docs/8.4/functions-window.html). Task: Write a query to display the most expensive product under each category (corresponding ot each record).

```sql
select p.*, first_value(product_name) over(partition by product_category order by price desc) as most_exp_per_category
from product p
```

Example from DVD rental data:

```sql
select distinct(customer_id), first_value(payment_id) over(partition by customer_id order by amount desc) as most_exp_payment
from payment p
order by customer_id
```

This window function does the same as the following `group by` and aggregate function.

```sql
select customer_id, payment_id
from payment p
group by customer_id, payment_id
having amount = max(amount)
order by customer_id
```

Task: Write a query to display the least expensive product under each category (corresponding to each record)

```sql
select *, last_value(product_name) over(partition by product_category order by price desc) as least_exp_product
from product
```

This delivers the wrong result! The reason is the default **frame clause**.

## 2.2. Frame Clause

Note that `first_value`, `last_value`, and `nth_value` consider only the rows within the "*window frame*", which by default contains the rows from the start of the partition through the last peer of the current row. This is likely to give unhelpful results for last_value and sometimes also nth_value. You can redefine the frame by adding a suitable frame specification (RANGE or ROWS) to the OVER clause. See Section 4.2.8 for more information about frame specifications. The default frame clause is:

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

This alternative becomes relevant when we have duplicates. `rows` considers the current row while `range` considers the last row of all duplicate values. We can also specify the number of rows:

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

Fetch a value from any particular position. Task: Write a query to display the second most expensive product under each category.

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
    ntile(3) over w as bucket
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
select d1.id, d1.name, d1.speciality, d1.hospital, d1.city, d1.consultation_fee
from doctors d1 join doctors d2 on d1.hospital = d2.hospital and d1.speciality != d2.speciality
```

## 4.5. Exercise 5

```sql
-- Query 5:

-- From the login_details table, fetch the users who logged in consecutively 3 or more times.

--Table Structure:

-- drop table login_details;
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

# 5. Solutions to Codility Exercise

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
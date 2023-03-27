CREATE SCHEMA foodie_fi; # CREATE DB FOODIE- PIE
USE FOODIE_FI;

#CREATE TABLE FOR PLANS
CREATE TABLE plans (
  plan_id INTEGER,
  plan_name VARCHAR(13),
  price DECIMAL(5,2)
);

#INSERT VALUES IN PLANS TABLES
INSERT INTO plans
  (plan_id, plan_name, price)
VALUES
  ('0', 'trial', '0'),
  ('1', 'basic monthly', '9.90'),
  ('2', 'pro monthly', '19.90'),
  ('3', 'pro annual', '199'),
  ('4', 'churn', null);
  
  
  #CREATE TABLE FOR SUBS
CREATE TABLE subscriptions (
  customer_id INTEGER,
  plan_id INTEGER,
  start_date DATE
);
  
  #PICK SOME SAMPLE CX DATA IN SUBS
  INSERT INTO subscriptions
  (customer_id, plan_id, start_date)
VALUES
('1','0','2020-08-01'),
('1','1','2020-08-08'),
('2','0','2020-09-20'),
('2','3','2020-09-27'),
('11','0','2020-11-19'),
('11','4','2020-11-26'),
('13','0','2020-12-15'),
('13','1','2020-12-22'),
('13','2','2021-03-29'),
('15','0','2020-03-17'),
('15','2','2020-03-24'),
('15','4','2020-04-29'),
('16','0','2020-05-31'),
('16','1','2020-06-07'),
('16','3','2020-10-21'),
('18','0','2020-07-06'),
('18','2','2020-07-13'),
('19','0','2020-06-22'),
('19','2','2020-06-29'),
('19','3','2020-08-29');

-- ___________________<><><><><><><><><><><><><><><><><><><><><><><><><><>><<>><><<>><<>--

USE foodie_fi;

-- A Customer Jounery
SELECT
  s.customer_id,
  f.plan_id, 
  f.plan_name,  
  s.start_date
FROM foodie_fi.plans AS f
JOIN foodie_fi.subscriptions AS s
  ON f.plan_id = s.plan_id;
  -- <><><><><><><><><><><><><><><><><><><><><><><><><><><><>

-- B > DATA ANALYSIS <
#1 [][][][][][[][][][][][][][][][][][][][][][][][][][]
SELECT COUNT(DISTINCT customer_id) AS RANDOMLY_CX
FROM foodie_fi.subscriptions;

-- Foodie-Fi has 8 Unique Customers.

#2][][][][][][[][][][][][][][][][][][][][][][][][][][]
SELECT MONTH (start_date) AS months, count(customer_id) AS no_of_CX
from subscriptions 
group by months
ORDER BY months;

-- The monthly Distribution of trial plans

#3 [][][][][][[][][][][][][][][][][][][][][][][][][][]
SELECT 
    p.plan_id, p.plan_name, COUNT(*) AS events
FROM
    foodie_fi.subscriptions s
        JOIN
    foodie_fi.plans p ON s.plan_id = p.plan_id
WHERE
    s.start_date >= '2021-01-01'
GROUP BY p.plan_id , p.plan_name
ORDER BY p.plan_id;
-- The count of events after the year 2020 was found to be 1 for plan “pro monthly”, there were no other plans found.

#4[][][][][][[][][][][][][][][][][][][][][][][][][][]
SELECT 
  COUNT(*) AS churn_cx_count,
  ROUND(100*COUNT(*)/ (
    SELECT COUNT(DISTINCT customer_id) 
    FROM subscriptions),1) AS churn_percentage
FROM subscriptions s
JOIN plans p
  ON s.plan_id = p.plan_id
WHERE s.plan_id = 4;

#5 [][][][][][[][][][][][][][][][][][][][][][][][][][]
WITH next_plan_cte AS
  (SELECT *,
          lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan
   FROM subscriptions),
     churners AS
  (SELECT *
   FROM next_plan_cte
   WHERE next_plan=4
     AND plan_id=0)
SELECT count(customer_id) AS 'churn after trial count',
       round(100 *count(customer_id)/
               (SELECT count(DISTINCT customer_id) AS 'distinct customers'
                FROM subscriptions), 1) AS 'churn percentage'
FROM churners;


#6 [][][][][][[][][][][][][][][][][][][][][][][][][][]
WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) as next_plan
FROM foodie_fi.subscriptions)

SELECT 
  next_plan, 
  COUNT(*) AS conversions,
  ROUND(100 * COUNT(*) / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),1) AS conversion_percentage
FROM next_plan_cte
WHERE next_plan IS NOT NULL 
  AND plan_id = 0
GROUP BY next_plan
ORDER BY next_plan;

#7 [][][][][][[][][][][][][][][][][][][][][][][][][][]
WITH next_plan AS(
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(start_date, 1) OVER(PARTITION BY customer_id ORDER BY start_date) as next_date
FROM foodie_fi.subscriptions
WHERE start_date <= '2020-12-31'),
-- To find breakdown of customers with existing plans on or after 31 Dec 2020
customer_breakdown AS (
  SELECT plan_id, COUNT(DISTINCT customer_id) AS customers
    FROM next_plan
    WHERE (next_date IS NOT NULL AND (start_date < '2020-12-31' AND next_date > '2020-12-31'))
      OR (next_date IS NULL AND start_date < '2020-12-31')
    GROUP BY plan_id)

SELECT plan_id, customers, 
  ROUND(100 * customers / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.subscriptions),1) AS percentage
FROM customer_breakdown
GROUP BY plan_id, customers
ORDER BY plan_id;

#8 [][][][][][[][][][][][][][][][][][][][][][][][][][]
SELECT 
  COUNT(DISTINCT customer_id) AS unique_customer
FROM foodie_fi.subscriptions
WHERE plan_id = 3
  AND start_date <= '2020-12-31';
  
#9 [][][][][][[][][][][][][][][][][][][][][][][][][][]
WITH trial_plan AS 
(SELECT 
  customer_id, 
  start_date AS trial_date
FROM foodie_fi.subscriptions
WHERE plan_id = 0
),
-- Filter results to customers at pro annual plan = 3
annual_plan AS
(SELECT 
  customer_id, 
  start_date AS annual_date
FROM foodie_fi.subscriptions
WHERE plan_id = 3
)

SELECT 
  ROUND(AVG(annual_date - trial_date),0) AS avg_days_to_upgrade
FROM trial_plan tp
JOIN annual_plan ap
  ON tp.customer_id = ap.customer_id;
  
#10 [][][][][][[][][][][][][][][][][][][][][][][][][][]
CREATE TABLE interval1(
   month_interval int,
   breakdown_period varchar(15));
INSERT INTO interval1(month_interval, breakdown_period)
VALUES
(1, '0 - 30 days'),
(2, '30 - 60 days'),	
(3, '60 - 90 days'),	
(4, '90 - 120 days'),
(5, '120 - 150 days'),	
(6, '150 - 180 days'),	
(7, '180 - 210 days'),	
(8, '210 - 240 days'),	
(9, '240 - 270 days'),	
(10, '270 - 300 days'),	
(11, '300 - 330 days'),	
(12, '330 - 360 days');

with base as (
select 
  customer_id, 
  plan_id, 
  start_date, 
  (lead(start_date) over(partition by customer_id order by start_date asc)) as lead_start_date
from foodie_fi.subscriptions
where plan_id in(0,3)),

tb as (select *, (lead_start_date - start_date) as diff from base where lead_start_date is not null),

tb1 as (select 
  (case 
  when diff < 30 then 1
  when diff < 60 then 2
  when diff <90  then 3
  when diff <120 then 4
  when diff <150 then 5
  when diff <180 then 6
  when diff <210 then 7
  when diff <240 then 8
  when diff <270 then 9
  when diff <300 then 10
  when diff <330 then 11
  when diff <360 then 12
  else diff
  end) as month_interval,
  count(*) as customers
from tb 
group by month_interval
order by month_interval)

select breakdown_period, customers
from tb1
join interval1
on tb1.month_interval = interval1.month_interval;

#11 [][][][][][[][][][][][][][][][][][][][][][][][][][]
WITH next_plan_cte AS (
SELECT 
  customer_id, 
  plan_id, 
  start_date,
  LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) as next_plan
FROM foodie_fi.subscriptions)

SELECT 
  COUNT(*) AS downgraded
FROM next_plan_cte
WHERE start_date <= '2020-12-31'
  AND plan_id = 2 
  AND next_plan = 1;
  
############################################################################################################################
  ## CC PAYMENT TABLE CREATING 
 -- XXXXXXX NO ANSWER XXXXXXXXXX
 
 
 
 
 
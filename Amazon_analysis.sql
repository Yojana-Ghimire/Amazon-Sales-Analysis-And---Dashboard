describe amazon;
SELECT COUNT(*) null_values FROM amazon
WHERE NULL;

-- Feature Engineering
ALTER TABLE amazon
add time_of_day varchar(15) not null;
UPDATE amazon SET time_of_day =
CASE 
   WHEN hour(time) between 06 and 11 then 'Morning'
   WHEN hour(time) BETWEEN 12 AND 17 THEN 'Afternoon'
   ELSE 'Evening'
END;

ALTER TABLE amazon 
ADD day_name VARCHAR(10) NOT NULL;

UPDATE amazon SET day_name = 
(SELECT dayname(date));

ALTER TABLE amazon
ADD month_name varchar(10) NOT NULL;

UPDATE amazon SET month_name=
(SELECT monthname(date));   

SELECT `invoice id`, date,time ,time_of_day,day_name, month_name  FROM amazon
LIMIT 5;

-- EDA
create table amazon_sales
(invoice_id varchar(30) primary key not null,
branch varchar(5) not null,
city varchar(30) not null,
customer_type varchar(30) not null,
gender varchar(10) not null,
product_line varchar(100) not null,
unit_price decimal(10,2) not null,
quantity int not null,
vat float not null,
total decimal(12,2) not null,
date date not null,
time time not null,
payment_method varchar(20) not null,
cogs decimal(10,2) not null,
gross_margin_percentage float not null,
gross_income decimal(12,2) not null,
rating decimal(3,1) not null,
time_of_day varchar(15) not null,
day_name varchar(10) not null,
month_name varchar(10) not null);

INSERT IGNORE INTO amazon_sales (
    invoice_id, branch, city, customer_type, gender, product_line,
    unit_price, quantity, vat, total, date, time, payment_method,
    cogs, gross_margin_percentage, gross_income, rating, time_of_day,
    day_name, month_name
)
SELECT * FROM amazon;
SELECT COUNT(*) FROM amazon_sales;

-- Total columns
SELECT COUNT(*) AS total_columns FROM information_schema.columns
WHERE table_name = 'amazon_sales';

-- Total rows
SELECT * FROM amazon_sales;

-- Check null values
SELECT COUNT(*) AS null_values FROM amazon_sales WHERE NULL;

-- 1 What is the count of distinct cities in the dataset?
SELECT COUNT(DISTINCT(city)) FROM amazon_sales;

-- 2. for each branch, what is corresponding city?
SELECT DISTINCT CITY, branch FROM amazon_sales;

-- 3. What is the count of distinct product lines in the dataset?
SELECT COUNT(DISTINCT(product_line)) FROM amazon_sales;

-- 4. Which payment method occurs most frequently?
SELECT payment_method, COUNT(payment_method) AS occurence FROM amazon_sales
GROUP BY payment_method
ORDER BY payment_method DESC;

-- 5. Which product line has the highest Sales?
SELECT product_line, SUM(quantity) AS total_sales FROM amazon_sales
GROUP BY product_line
ORDER BY 2 DESC;

-- 6. How much revenue is generated each months?
SELECT  month_name, SUM(total) FROM amazon_sales
GROUP BY month_name
ORDER BY 2 DESC;

-- 7. Which productline generated highest revenue?
SELECT product_line, SUM(total) highest_revenue FROM amazon_sales
GROUP BY product_line
ORDER BY 2 DESC
;

-- 8. In which month cost of goods sold reach its peak?
SELECT month_name, SUM(cogs) FROM amazon_sales
GROUP BY month_name
ORDER BY 2 DESC;

-- 9. Which city has the highest revenue recorded?
SELECT CITY, SUM(total) highest_reveue_city FROM amazon_sales
GROUP BY CITY
ORDER BY 2 DESC;

-- 10. Which product line incurred the highest value added tax?
SELECT product_line, MAX(vat) highest_tax FROM  amazon_sales
GROUP BY product_line
ORDER BY 2 DESC;

-- 11. Which customer type occurs most frequently?
SELECT customer_type, COUNT(*) FROM amazon_sales
GROUP BY 1
ORDER BY 2 DESC;

-- 12 For each product_line, add a column indicating "Good" if sales are above average , else "Bad"
SELECT product_line, SUM(total) AS revenue,
  CASE
     WHEN SUM(total) > (SELECT SUM(total)/COUNT(DISTINCT(product_line)) FROM amazon_sales ) THEN "Good"
     ELSE "Bad"
     end sales_quality
 FROM amazon_sales a
 GROUP BY product_line;

-- 13 Which branch exceeded the average number of product sold?
SELECT branch, SUM(quantity) AS product_sold FROM amazon_sales
GROUP BY branch
HAVING product_sold /(SELECT SUM(quantity)/COUNT(DISTINCT branch) AS avg_quantity FROM amazon_sales);

-- 14 Which product line is most frequently associated with each gender?
WITH NEW AS
(SELECT gender, product_line,count(*) AS count FROM amazon_sales
GROUP BY 1,2),
Max_count AS
(SELECT MAX(COUNT) FROM NEW GROUP BY gender)

SELECT * FROM NEW
WHERE COUNT IN (SELECT * FROM Max_count) LIMIT 2;

-- 15 What is the count of distinct customer types in dataset?
SELECT COUNT(DISTINCT(customer_type)) FROM amazon_sales;

-- 16. Calculate the average rating for each product line
SELECT product_line, AVG(rating) FROM amazon_sales
GROUP BY product_line;

-- 17. Identify the customer type contributing the highest revenue
SELECT customer_type, SUM(total) AS revenue FROM amazon_sales
GROUP BY customer_type
ORDER BY 2 DESC;

-- 18. Count the sales occurences for each time of day on every weekday
SELECT time_of_day, day_name, COUNT(*) sales FROM amazon_sales
GROUP BY 1,2
ORDER BY field(day_name, 'Sunday', 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'),
Field(time_of_day,'Morning','Afternoon','Evening');

-- 19. Determine city with highest VAT percentage.
SELECT city, MAX(Vat) as vat_percent FROM amazon_sales
GROUP BY 1
ORDER BY 2 DESC;

-- 20. Identify the customer type with highest VAT payments
SELECT customer_type, MAX(Vat) AS Vat_percent FROM amazon_sales
GROUP BY 1
ORDER BY 2 DESC;

-- 21. What is the count of distinct payment methods in the dataset?
SELECT COUNT(DISTINCT(payment_method)) FROM amazon_sales;

-- 22. Examine distribution of gender within each branch
SELECT branch, gender, COUNT(gender) FROM amazon_sales
GROUP BY 1,2
ORDER BY 1,2;

-- 23. Determine predominant gender among customer
SELECT  gender, count(*) as count FROM amazon_sales
GROUP BY 1;

-- 24. Identify the day of the week with the highest average ratings.
SELECT day_name, AVG(rating) FROM amazon_sales
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 25. Identify the time of day when customer provides most rating
SELECT time_of_day, COUNT(rating) FROM amazon_sales
GROUP BY 1
ORDER BY 2 DESC;

-- 26. Determine the time of day with the highest customer ratings for each branch

SELECT 
    branch, 
    time_of_day, 
    highest_rating
FROM (
    SELECT 
        branch, 
        time_of_day, 
        MAX(rating) AS highest_rating,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY MAX(rating) DESC) AS r
    FROM 
        amazon_sales
    GROUP BY 
        branch, time_of_day
) AS ranked_ratings
WHERE 
    r = 1
ORDER BY 
    branch;
    
-- 27 Determine the day of the week with the highest average ratings for each branch
SELECT branch,day_name, avg_rating
FROM
(SELECT branch, day_name, avg(rating) AS avg_rating,
ROW_NUMBER() OVER(PARTITION BY branch ORDER BY avg(rating) DESC) AS r
 FROM amazon_sales
GROUP BY branch, day_name ) AS Ranked_ratings
WHERE r= 1
ORDER BY 1;    

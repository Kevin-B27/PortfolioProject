CREATE DATABASE  walmartSales;

CREATE TABLE sales(
invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
branch VARCHAR(30) NOT NULL,
city VARCHAR(30) NOT NULL,
customer_type VARCHAR(30) NOT NULL,
gender VARCHAR(10) NOT NULL,
product_line VARCHAR(100) NOT NULL,
unit_price_ DECIMAL (10,2) NOT NULL,
quantity INT NOT NULL,
VAT DECIMAL(6,4) NOT NULL,
total DECIMAL(12, 4),
date DATETIME NOT NULL,
time TIME NOT NULL,
payment_method VARCHAR(15) NOT NULL,

cogs DECIMAL(10) NOT NULL,
gross_margin_pct FLOAT(53),
gross_income DECIMAL(10) NOT NULL,
rating DECIMAL(2,1)

);

-- ------------------------------------------------------------------------------------------------------
-- -------------------------------Feature Engineering----------------------------------------------- 
-- Time of day
SELECT time, 
(CASE 
	WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
    WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
    ELSE "Evening"
END
)AS time_of_date
FROM sales;

ALTER TABLE sales ADD COLUMN time_of_date VARCHAR(20);

UPDATE sales
SET time_of_date = (
	CASE 
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
		WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
		ELSE "Evening"
	END
	);

SELECT * 
FROM sales;
-- --------------------------------------------------------------------------------------
-- day_name

SELECT date, DAYNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN day_name VARCHAR(50)
;

UPDATE sales
SET day_name = DAYNAME(date);

-- Month_name
SELECT date, monthname(date)
FROM sales;
ALTER TABLE sales ADD COLUMN month_name VARCHAR(30);

UPDATE sales
SET month_name = monthname(date);
-- --------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------
-- -----------------------------------------Generic---------------------------------------------
-- How many unique cities does the data have
SELECT DISTINCT city
FROM sales;

-- In wich city is each branch?
SELECT DISTINCT branch
FROM sales;

SELECT DISTINCT city, branch
FROM sales;

-- --------------------------------------------------------------------------------------
-- --------------------------------------Product------------------------------------------------
-- How many unique product lines does the data have?
SELECT COUNT(DISTINCT product_line)
FROM sales;
-- --------------------------------------------------------------------------------------
-- What is the most common payment method?
SELECT DISTINCT payment_method, COUNT(payment_method) AS count_pey
FROM sales
GROUP BY payment_method
ORDER BY count_pey DESC
;
-- --------------------------------------------------------------------------------------
-- What is the most selling product line?
SELECT DISTINCT product_line, COUNT(product_line) AS count_line
FROM sales
GROUP BY product_line
ORDER BY count_line DESC;

-- --------------------------------------------------------------------------------------
-- What is the total revenue by month?
SELECT month_name AS month, SUM(total) AS total_revenue
FROM sales
GROUP BY month_name
ORDER BY total_revenue DESC
;

-- --------------------------------------------------------------------------------------
-- What month is had the largest COGS?
SELECT month_name AS month, SUM(cogs) AS total_cogs
FROM sales
GROUP BY month_name
ORDER BY total_cogs DESC
;

-- --------------------------------------------------------------------------------------
-- What product line had the largest revenue?
SELECT product_line, SUM(total) AS total_revenue
FROM sales
GROUP BY product_line
ORDER BY total_revenue DESC
;

-- What is city with largest revenue?
SELECT city, branch, SUM(total) AS total_revenue
FROM sales
GROUP BY city, branch
ORDER BY total_revenue DESC
;
-- --------------------------------------------------------------------------------------
-- What product line had the largest VAT?
SELECT product_line, AVG(VAT) AS avg_tax
FROM sales
GROUP BY product_line
ORDER BY avg_tax DESC
;

-- --------------------------------------------------------------------------------------
-- Fetch each product line and add a column to those product line showing "Good ", "Bad". Good if its greather than average sales
WITH avg_global
AS
(
SELECT AVG(total) AS avgtot
FROM sales
)SELECT product_line, total,
CASE 
WHEN total > (SELECT avgtot FROM avg_global) THEN "G"
ELSE "B"
END AS clasification

FROM sales;


-- Fetch each product line and add a column to those product line showing "Good ", "Bad". Good if its greather than average sales, group by
WITH avg_global
AS
(
SELECT AVG(total) AS avgtot
FROM sales
), avg_product AS
(
SELECT  product_line,AVG(total) AS avg_total_product
FROM sales
GROUP BY product_line
ORDER BY avg_total_product DESC
)
SELECT product_line, avg_total_product,
CASE 
WHEN avg_total_product > (SELECT avgtot FROM avg_global) THEN "G"
ELSE "B"
END AS clasification

FROM avg_product;
-- --------------------------------------------------------------------------------------
-- Which branch sold more products than average product sold?
SELECT branch, SUM(quantity) AS qty
FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales);

-- --------------------------------------------------------------------------------------
-- What is the most common product line by gender?
SELECT gender, product_line,  COUNT(gender) AS total_cnt
FROM sales
GROUP BY gender, product_line
ORDER BY total_cnt DESC
;
-- --------------------------------------------------------------------------------------
-- What iis the average rating of each product line?
SELECT  product_line, ROUND(AVG(rating),2) AS avg_rating
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC
;

-- --------------------------------------------------------------------------------------
-- -------------------------------------SALES---------------------------------------------

-- Number of sales made in each time of the day per week
SELECT time_of_date, COUNT(*) total_sales
FROM sales
WHERE day_name = "Monday"
GROUP BY time_of_date
ORDER BY total_sales DESC
;

-- Wich of the customer types bring the most revenue?
SELECT customer_type, SUM(total) AS total_revenue
FROM sales
GROUP BY customer_type
ORDER BY total_revenue DESC
;

-- Wich city has the largest tax percent/VAT (Value Added Tax)?
SELECT city, AVG(VAT) as tax_city
FROM sales
GROUP BY city
ORDER BY tax_city DESC;

-- Wich customer type pays the most in VAT ?
SELECT customer_type, AVG(VAT) AS total_tax
FROM sales
GROUP BY customer_type
ORDER BY total_tax DESC;

-- --------------------------------------------------------------------------------------
-- -------------------------------------CUSTOMER---------------------------------------------

-- How many unique customer types does the data have?
SELECT distinct customer_type
FROM sales;

-- How many payment methods types does the data have?
SELECT distinct payment_method
FROM sales;

-- What is the most commmon customer type?
SELECT customer_type, COUNT(*) AS type_customer
FROM sales
GROUP BY customer_type;

-- What customer type buy the most?
SELECT customer_type, COUNT(invoice_id) AS most_buy_customer
FROM sales
GROUP BY customer_type;

-- What is the gender of the most customer 
SELECT gender, COUNT(customer_type) AS gender_count
FROM sales
GROUP BY gender;


-- What is gender distribution per branch
SELECT gender, count(*) AS gender_cnt
FROM sales
WHERE branch = 'A'
GROUP BY gender
ORDER BY gender_cnt DESC;

-- What time of the day do customers give most ratings?
SELECT time_of_date, AVG(rating) AS avg_per_day
FROM sales
GROUP BY time_of_date
ORDER BY avg_per_day DESC;

-- What time of the day do customers give the most ratings per branch?
SELECT time_of_date, AVG(rating) AS avg_per_branch
FROM sales
WHERE branch = "B"
GROUP BY time_of_date
ORDER BY avg_per_branch DESC;

-- Wich day for the week has the best avg reatings?
SELECT day_name, AVG(rating) AS avg_rating
FROM sales
GROUP BY day_name
ORDER BY avg_rating DESC;

-- Wich day of the week has the best avg per branch?
SELECT day_name, AVG(rating) AS avg_rating
FROM sales
WHERE branch = "C"
GROUP BY day_name
ORDER BY avg_rating DESC;




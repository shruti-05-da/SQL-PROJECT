Use analysis;


-- 1 . Basic Delivery Performance Report 
-- Problem: Find the percentage of orders delivered late vs. on time. 
-- Goal: Help logistics team fix delivery issues.

with cte1 as (Select count(*) as num from orders where order_delivered_customer_date < order_estimated_delivery_date),
cte2 as (Select count(*) as nub from orders where order_delivered_customer_date > order_estimated_delivery_date)

Select concat(round(cte1.num *100 / (Select count(*) from orders),2),"%") as "On time",
concat(round(cte2.nub *100 / (Select count(*) from orders),2),"%") as "Late" from cte1,cte2;

-- 2. Customer Review Analysis 
-- Problem: Find the average customer rating for each product category. 
-- Goal: Identify which categories customers love or hate.

with cus_ana as (Select p.product_category_name , avg(r.review_score) as 'Average_customer_ratings'
from review r join order_items oi on r.order_id = oi.order_id 
join product p on oi.product_id = p.product_id
group by 1)

Select *, case when Average_customer_ratings>=3.5 then 'Love' else 'Hate' end as 'Rating_status'
from cus_ana;

-- 3. Top Selling Products and Categories 
-- Problem: Find the top 10 best-selling product categories. 
-- Goal: Help the marketing team promote the best products.

SELECT 
    p.product_category_name,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS 'Total_sales'
FROM
    order_items oi
        JOIN
    product p ON oi.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- 4. Payment Types and Trends 
-- Problem: Find out which payment method customers use the most (credit card, boleto, etc.). 
-- Goal: Plan for payment system improvements datasets. 

SELECT 
    payment_type, COUNT(*) AS 'Total_used_times'
FROM
    payment
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- Identify regions with most late deliveries. 

with late as (Select *  from orders o where order_delivered_customer_date > order_estimated_delivery_date)

Select customer_state, count(*) as 'Total_late_deliveries' from late join customers c on late.customer_id = c.customer_id 
group by 1 
order by 2 desc;

-- Identify categories with most 5-star and 1-star reviews. 

with rev_ana as (Select order_id,review_score from review where review_score = 1 or review_score = 5)

Select product_category_name,
sum(case when review_score = 5 then 1 else 0 end) as '5star_review',
sum(case when review_score = 1 then 1 else 0 end) as '1star_review'
from rev_ana join order_items oi on oi.order_id = rev_ana.order_id join product p on oi.product_id = p.product_id
group by 1
order by 2 desc ,3 desc;

-- Analyze the average payment value per order only for delivered order.

SELECT 
    ROUND(SUM(payment_value) / COUNT(DISTINCT p.order_id),
            2) AS 'Avg_pay_per_order'
FROM
    payment p
        JOIN
    orders o ON p.order_id = o.order_id
WHERE
    order_status = 'delivered';

-- How many orders does an average customer place?

SELECT 
    COUNT(*) / COUNT(DISTINCT customer_id)
FROM
    orders
WHERE
    order_status != 'canceled';

-- Which cities have the most active customers?

SELECT 
    customer_state,
    COUNT(DISTINCT c.customer_id) AS 'Total_Active_Customers'
FROM
    orders o
        JOIN
    customers c ON o.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC;

-- Distribution of review scores. 

SELECT 
    review_score AS 'ratings', COUNT(*) AS Total_count
FROM
    review
GROUP BY 1
ORDER BY 2 DESC;

-- Relation between delivery time and review score. 

SELECT 
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On time'
        ELSE 'Late'
    END AS 'Deliver_status',
    SUM(CASE
        WHEN review_score = 5 THEN 1
        ELSE 0
    END) AS '5star',
    SUM(CASE
        WHEN review_score = 4 THEN 1
        ELSE 0
    END) AS '4star',
    SUM(CASE
        WHEN review_score = 3 THEN 1
        ELSE 0
    END) AS '3star',
    SUM(CASE
        WHEN review_score = 2 THEN 1
        ELSE 0
    END) AS '2star',
    SUM(CASE
        WHEN review_score = 1 THEN 1
        ELSE 0
    END) AS '1star',
    COUNT(review_score) AS Total_ratings,
    ROUND(AVG(review_score), 2) AS Avg_rating
FROM
    orders o
        JOIN
    review r ON o.order_id = r.order_id
GROUP BY 1;

-- Average delay days (delivered date vs estimated date). 

SELECT 
    AVG(DATEDIFF(order_delivered_customer_date,
            order_estimated_delivery_date))
FROM
    orders;
SELECT 
    AVG(DATEDIFF(order_delivered_customer_date,
            order_estimated_delivery_date)) AS 'Avg_delay_days'
FROM
    orders
WHERE
    order_delivered_customer_date >= order_estimated_delivery_date;

-- Categories with most orders. 

SELECT 
    product_category_name, COUNT(*) AS Total_orders
FROM
    order_items oi
        JOIN
    product p ON oi.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- -- through window function
with cte as (Select product_category_name, count(*) as Total_orders from order_items oi join product p on oi.product_id = p.product_id group by 1),
rank_cte AS (Select *, rank() over (order by total_orders desc) as rnk from cte)
Select product_category_name, Total_orders from rank_cte where rnk = 1;

-- Which 3 product categories have the best customer ratings?

SELECT 
    p.product_category_name,
    ROUND(AVG(r.review_score), 2) AS 'Average_customer_ratings'
FROM
    review r
        JOIN
    order_items oi ON r.order_id = oi.order_id
        JOIN
    product p ON oi.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- Name 3 cities where most deliveries happen. 

SELECT 
    customer_state, COUNT(*) AS 'Total_Deliveries'
FROM
    orders o
        JOIN
    customers c ON o.customer_id = c.customer_id
WHERE
    order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- Calculate the average delivery delay (in days) for each state. 

SELECT 
    customer_state,
    AVG(DATEDIFF(order_delivered_customer_date,
            order_estimated_delivery_date)) AS 'Avg_delay_days'
FROM
    orders o
        JOIN
    customers c ON c.customer_id = o.customer_id
WHERE
    order_delivered_customer_date > order_estimated_delivery_date
GROUP BY 1;

-- Find the top 5 product categories with the highest number of late deliveries. 

SELECT 
    product_category_name,
    COUNT(DISTINCT oi.order_id) AS 'Total_late_deliveries'
FROM
    orders o
        JOIN
    order_items oi ON oi.order_id = o.order_id
        JOIN
    product p ON p.product_id = oi.product_id
WHERE
    order_delivered_customer_date > order_estimated_delivery_date
        AND order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

-- List the top 10 cities with the highest number of unique customers. 

SELECT 
    customer_city,
    COUNT(DISTINCT customer_id) AS 'total_unique_customers'
FROM
    customers
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- Find the most common review score for each product category. 

with cte as (Select product_category_name,review_score,count(*) as Total_count from review r 
join order_items oi on r.order_id = oi.order_id join product p on p.product_id = oi.product_id group by 1,2),
cte2 as (Select * , rank() over (partition by product_category_name order by Total_count desc) as rank_ from cte)

Select product_category_name, review_score,Total_count from cte2 where rank_ =1 order by 3 desc;

-- Identify the top 5 products that received the most 1-star reviews. 

SELECT 
    oi.product_id, COUNT(*) AS '1star ratings'
FROM
    review r
        JOIN
    order_items oi ON r.order_id = oi.order_id
WHERE
    review_score = 1
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- OR
with cte as (Select oi.product_id, count(*) as '1star_ratings', dense_rank() over (order by count(review_score) desc) as rank_
from review r join order_items oi on r.order_id = oi.order_id where review_score = 1 group by 1)
Select product_id, 1star_ratings from cte where rank_<6;

-- Calculate the total revenue generated by each payment type. 

SELECT 
    payment_type, ROUND(SUM(payment_value), 2)
FROM
    payment
GROUP BY 1;

-- For each product category, calculate the average review score and total number of orders. 

SELECT 
    product_category_name,
    ROUND(AVG(review_score), 2) AS Avg_rating,
    COUNT(*) AS Total_count
FROM
    review r
        JOIN
    order_items oi ON r.order_id = oi.order_id
        JOIN
    product p ON p.product_id = oi.product_id
GROUP BY 1;

-- Find the top 5 customers who placed the most orders and their total spending. 

SELECT 
    customer_id,
    COUNT(DISTINCT oi.order_id) AS Total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS 'Total_spending'
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
WHERE
    o.order_status != 'canceled'
GROUP BY 1
ORDER BY 2 DESC , 3 DESC
LIMIT 5;

-- Determine the number of orders per month and the average delivery time (in days) for each month. 

SELECT 
    months, Avg_deliver_time
FROM
    (SELECT 
        MONTHNAME(order_purchase_timestamp) AS months,
            MONTH(order_purchase_timestamp) AS monthsn,
            ROUND(AVG(DATEDIFF(order_estimated_delivery_date, order_purchase_timestamp)), 2) AS 'Avg_deliver_time'
    FROM
        orders
    WHERE
        order_status != 'canceled'
    GROUP BY 1 , 2
    ORDER BY 2) r;

-- Identify categories where the majority of reviews are 5-star.

select 
	product_category_name, count(product_category_name)
    FROM
    review r
        JOIN
    order_items oi ON r.order_id = oi.order_id
        JOIN
    product p ON p.product_id = oi.product_id
where review_score = 5
group by 1 order by 2 desc;

SELECT 
    product_category_name,
    SUM(CASE
        WHEN review_score = 5 THEN 1
        ELSE 0
    END) AS '5star_rating',
    COUNT(*) AS Total_review
FROM
    review r
        JOIN
    order_items oi ON r.order_id = oi.order_id
        JOIN
    product p ON p.product_id = oi.product_id
GROUP BY 1
HAVING SUM(CASE
    WHEN review_score = 5 THEN 1
    ELSE 0
END) > COUNT(*) / 2;
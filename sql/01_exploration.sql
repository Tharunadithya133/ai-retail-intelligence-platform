
--CUSTOMER TABLE EXPLORATION


--Count total customers
SELECT COUNT(*)
FROM olist_customers_dataset;

-- Customers from São Paulo (SP)
SELECT *
FROM olist_customers_dataset
WHERE customer_state = 'SP';

-- Customers from Rio de Janeiro
SELECT customer_id,
       customer_city,
       customer_state
FROM olist_customers_dataset
WHERE customer_city = 'rio de janeiro';

-- Top 10 cities by customer count
SELECT customer_city,
       COUNT(*) AS total_customers
FROM olist_customers_dataset
GROUP BY customer_city
ORDER BY total_customers DESC
LIMIT 10;

-- Customers grouped by state
SELECT customer_state,
       COUNT(*) AS total_customers
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY total_customers DESC;

-- Count unique states
SELECT COUNT(DISTINCT customer_state)
FROM olist_customers_dataset;

-- States with more than 5000 customers
SELECT customer_state,
       COUNT(*) AS total_customers
FROM olist_customers_dataset
GROUP BY customer_state
HAVING COUNT(*) > 5000
ORDER BY total_customers DESC;

-- CUSTOMERS AND ORDERS

-- Customer city and order details
SELECT o.order_id,
       c.customer_city,
       c.customer_state
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
ON c.customer_id = o.customer_id;

-- Top 10 cities by number of orders
SELECT c.customer_city,
       COUNT(o.order_id) AS total_orders
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
ON c.customer_id = o.customer_id
GROUP BY c.customer_city
ORDER BY total_orders DESC
LIMIT 10;

-- Customers with the highest number of orders
SELECT c.customer_unique_id,
       COUNT(o.order_id) AS total_orders
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_orders DESC
LIMIT 10;

-- Orders by state
SELECT c.customer_state,
       COUNT(o.order_id) AS total_orders
FROM olist_customers_dataset c
INNER JOIN olist_orders_dataset o
ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;


 ORDER ANALYSIS


-- Percentage of delivered orders
SELECT
    COUNT(
        CASE
            WHEN order_status = 'delivered'
            THEN 1
        END
    ) * 100.0 / COUNT(*) AS delivered_percentage
FROM olist_orders_dataset;

-- Items worth more than 500
select count(price)
from olist_order_items_dataset
where price > 500.00;

-- Total revenue
SELECT ROUND(SUM(price)::numeric, 2) AS total_revenue
FROM olist_order_items_dataset;

-- Average product price
SELECT ROUND(AVG(price)::numeric, 2) AS avg_revenue
FROM olist_order_items_dataset;

-- Average shipping cost
SELECT ROUND(AVG(freight_value)::numeric, 2) AS avg_shipping_cost
FROM olist_order_items_dataset;

-- Most expensive products
SELECT product_id,
       price
FROM olist_order_items_dataset
ORDER BY price DESC
LIMIT 10;

-- Top sellers
SELECT seller_id,
       COUNT(*) AS total_sales
FROM olist_order_items_dataset
GROUP BY seller_id
ORDER BY total_sales DESC
LIMIT 10;

-- Highest shipping charges
SELECT order_id,
       freight_value
FROM olist_order_items_dataset
ORDER BY freight_value DESC
LIMIT 10;
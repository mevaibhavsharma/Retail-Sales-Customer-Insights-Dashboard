SELECT * FROM retail_data.customers;

-- Total number of customers
SELECT COUNT(*) AS total_customers FROM customers;

-- Top 5 products by total sales amount
SELECT 
    p.product_name,
    ROUND(SUM(t.sales_amount), 2) AS total_sales
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sales DESC
LIMIT 5;


SELECT COUNT(*) FROM transactions WHERE product_id IS NULL;

SELECT COUNT(*) FROM products WHERE product_id IS NULL;

SELECT COUNT(*) 
FROM transactions t
JOIN products p 
ON t.product_id = p.product_id;


SELECT * FROM transactions LIMIT 10;

SELECT 
    p.product_name,
    SUM(t.sales_amount) AS total_sales
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sales DESC;



SELECT product_id, sales_amount, quantity, selling_price FROM transactions LIMIT 10;

SELECT * FROM products;

SELECT p.category, 
       COUNT(t.transaction_id) AS total_transactions,
       SUM(t.sales_amount) AS total_sales
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY total_sales DESC
LIMIT 10;


SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM transactions;


-- Top 10 Products by Total Sales Volume by quantity sold
SELECT 
    product_id, 
    SUM(quantity) AS total_quantity_sold
FROM transactions
GROUP BY product_id
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- Top 10 Products by Total Sales Volume by revenue
SELECT 
    product_id, 
    SUM(sales_amount) AS total_revenue
FROM transactions
GROUP BY product_id
ORDER BY total_revenue DESC
LIMIT 10;



-- Sales by Category
SELECT 
    p.category,
    SUM(t.sales_amount) AS total_sales
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY total_sales DESC;



-- Total Sales Overall
SELECT SUM(sales_amount) AS total_sales FROM transactions;




-- Total Transactions Count
SELECT COUNT(*) AS total_transactions FROM transactions;






-- Calculate Recency, Frequency, Monetary for each customer

WITH customer_rfm AS (
    SELECT
        customer_id,
        DATEDIFF(CURRENT_DATE, MAX(date)) AS recency,               -- Days since last purchase
        COUNT(transaction_id) AS frequency,                         -- Total transactions
        SUM(sales_amount) AS monetary                               -- Total money spent
    FROM transactions
    GROUP BY customer_id
)
SELECT * FROM customer_rfm ORDER BY recency;




-- Repeat vs New Customers in a given period

WITH first_purchase AS (
    SELECT customer_id, MIN(date) AS first_date
    FROM transactions
    GROUP BY customer_id
)
SELECT
    COUNT(CASE WHEN first_date >= '2024-01-01' THEN 1 END) AS new_customers_2024,
    COUNT(CASE WHEN first_date < '2024-01-01' THEN 1 END) AS repeat_customers_2024
FROM first_purchase;




-- Average Order Value (AOV) and Basket Size
SELECT
    AVG(sales_amount) AS avg_order_value,
    AVG(quantity) AS avg_basket_size
FROM transactions;





-- Sales Contribution by Brand
SELECT 
    p.brand,
    SUM(t.sales_amount) AS total_sales
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.brand
ORDER BY total_sales DESC;




-- Monthly Sales Growth Rate
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(date, '%Y-%m') AS month,
        SUM(sales_amount) AS sales
    FROM transactions
    GROUP BY month
)
SELECT 
    month,
    sales,
    LAG(sales) OVER (ORDER BY month) AS previous_month_sales,
    ROUND(((sales - LAG(sales) OVER (ORDER BY month)) / LAG(sales) OVER (ORDER BY month)) * 100, 2) AS growth_rate_percentage
FROM monthly_sales;




-- Customer Lifetime Value (CLV) Calculation
SELECT 
    customer_id,
    COUNT(transaction_id) AS total_transactions,
    SUM(sales_amount) AS total_revenue,
    AVG(sales_amount) AS avg_revenue_per_transaction
FROM transactions
GROUP BY customer_id
ORDER BY total_revenue DESC
LIMIT 10;




-- Cohort Analysis: Customer Retention by Month of First Purchase

WITH first_purchase_month AS (
    SELECT
        customer_id,
        DATE_FORMAT(MIN(date), '%Y-%m') AS cohort_month
    FROM transactions
    GROUP BY customer_id
),
transactions_by_month AS (
    SELECT
        customer_id,
        DATE_FORMAT(date, '%Y-%m') AS transaction_month
    FROM transactions
)
SELECT
    f.cohort_month,
    t.transaction_month,
    COUNT(DISTINCT t.customer_id) AS active_customers
FROM first_purchase_month f
JOIN transactions_by_month t ON f.customer_id = t.customer_id
GROUP BY f.cohort_month, t.transaction_month
ORDER BY f.cohort_month, t.transaction_month;






-- Identify Top 3 Selling Products per Category

WITH product_sales AS (
    SELECT
        p.category,
        p.product_id,
        SUM(t.selling_price) AS total_sales
    FROM products p
    JOIN transactions t ON p.product_id = t.product_id
    GROUP BY p.category, p.product_id
)
SELECT
    category,
    product_id,
    selling_price
FROM (
    SELECT
        category,
        product_id,
        selling_price,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY selling_price DESC) AS rank1
    FROM product_sales
) ranked
WHERE rank1 <= 3
ORDER BY category, selling_price DESC;



-- Running Total (Cumulative Sales) Over Time
SELECT
    date,
    SUM(sales_amount) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM transactions
GROUP BY date
ORDER BY date;

select * from transactions;




-- Average Days Between Purchases per Customer

WITH ordered_transactions AS (
    SELECT
        customer_id,
        date,
        LAG(date) OVER (PARTITION BY customer_id ORDER BY date) AS previous_transaction_date
    FROM transactions
),
differences AS (
    SELECT
        customer_id,
        DATEDIFF(date, previous_transaction_date) AS days_between
    FROM ordered_transactions
    WHERE previous_transaction_date IS NOT NULL
)
SELECT
    customer_id,
    AVG(days_between) AS avg_days_between_purchases
FROM differences
GROUP BY customer_id
ORDER BY avg_days_between_purchases;



-- Detect Inactive Customers (No purchases in last 90 days)

SELECT 
    customer_id
FROM (
    SELECT 
        customer_id, 
        MAX(date) AS last_purchase_date
    FROM transactions
    GROUP BY customer_id
) last_purchases
WHERE last_purchase_date < DATE_SUB(CURRENT_DATE, INTERVAL 90 DAY);




-- Products with Highest Price Variance
SELECT
    product_id,
    STDDEV_SAMP(sales_amount) AS price_std_dev
FROM transactions
GROUP BY product_id
ORDER BY price_std_dev DESC
LIMIT 10;




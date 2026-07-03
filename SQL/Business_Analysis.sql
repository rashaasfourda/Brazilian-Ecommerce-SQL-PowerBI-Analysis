/*
=========================================================
Project: Brazilian E-Commerce Sales Analysis
Dataset: Olist Brazilian E-Commerce Public Dataset
Database: SQLite
Author: Rasha
Tools: SQL, Excel, Power BI
=========================================================
*/
-- =====================================================
-- BUSINESS QUESTIONS
-- =====================================================
-- =====================================================
-- Question 1
-- Top customers by total spending
-- =====================================================

SELECT 
    c.customer_unique_id,
    SUM(p.payment_value) AS total_spent
FROM customers c
INNER JOIN orders o 
    ON c.customer_id = o.customer_id
INNER JOIN payments p 
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC;



-- =====================================================
-- Question 2
-- Average spending per customer
-- =====================================================

SELECT ROUND(AVG(total_spent), 4) AS average_spent
FROM (
    SELECT 
        c.customer_unique_id,
        SUM(p.payment_value) AS total_spent
    FROM customers c
    INNER JOIN orders o 
        ON c.customer_id = o.customer_id
    INNER JOIN payments p 
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS customer_spending;
;

-- =====================================================
-- Question 3
-- Do repeat customers spend more?
-- =====================================================

SELECT 
    customer_type,
    ROUND(AVG(total_spent), 2) AS avg_spending
FROM (
    SELECT 
        customer_unique_id,
        total_spent,
        CASE 
            WHEN order_count > 1 THEN 'Repeat Customer'
            ELSE 'One-time Customer'
        END AS customer_type
    FROM (
        SELECT 
            c.customer_unique_id,
            SUM(p.payment_value) AS total_spent,
            COUNT(DISTINCT o.order_id) AS order_count
        FROM customers c
        INNER JOIN orders o 
            ON c.customer_id = o.customer_id
        INNER JOIN payments p 
            ON o.order_id = p.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY c.customer_unique_id
    ) AS customer_spending
) AS customer_segments
GROUP BY customer_type;


-- =====================================================
-- Question 4
-- Top cities and states by number of orders
-- =====================================================

SELECT 
    c.customer_city AS city,
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
INNER JOIN orders o 
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY 
    c.customer_city,
    c.customer_state
ORDER BY total_orders DESC;


-- =====================================================
-- Question 5
-- Percentage of repeat customers
-- =====================================================

SELECT
    COUNT(*) AS total_orders
FROM ordersSELECT 
    ROUND(repeat_customers * 100.0 / total_customers, 2) 
    AS repeat_customer_percentage
FROM (
    SELECT  
        SUM(CASE 
                WHEN order_count > 1 THEN 1 
                ELSE 0 
            END) AS repeat_customers,
        COUNT(*) AS total_customers
    FROM (
        SELECT 
            c.customer_unique_id,
            COUNT(DISTINCT o.order_id) AS order_count
        FROM customers c
        INNER JOIN orders o 
            ON c.customer_id = o.customer_id
        INNER JOIN payments p 
            ON o.order_id = p.order_id
        WHERE o.order_status = 'delivered'
        GROUP BY c.customer_unique_id
    ) AS customer_orders
) AS customer_summary;


-- =====================================================
-- Question 6
-- Total revenue generated
-- =====================================================

SELECT 
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM orders o
INNER JOIN payments p 
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
;

-- =====================================================
-- Question 7
-- Monthly sales trend
-- =====================================================

SELECT  
    strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM orders o
INNER JOIN payments p 
    ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY strftime('%Y-%m', o.order_purchase_timestamp)
ORDER BY order_month;
;

-- =====================================================
-- Question 8
-- Top product categories by revenue
-- =====================================================

SELECT  
    p.product_category_name AS category,
    ROUND(SUM(i.price), 2) AS total_revenue
FROM orders o
INNER JOIN order_items i
    ON o.order_id = i.order_id
INNER JOIN products p 
    ON i.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
;

-- =====================================================
-- Question 9
-- Average order value
-- =====================================================

WITH order_values AS (
    SELECT  
        o.order_id,
        ROUND(SUM(p.payment_value), 2) AS order_value
    FROM orders o
    INNER JOIN payments p 
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id
)

SELECT 
    ROUND(AVG(order_value), 2) AS average_order_value
FROM order_values;
;

-- =====================================================
-- Question 10
-- Best-selling products
-- =====================================================

SELECT  
    i.product_id,
    COUNT(*) AS total_sales
FROM orders o
INNER JOIN order_items i
    ON o.order_id = i.order_id
WHERE o.order_status = 'delivered'
GROUP BY i.product_id
ORDER BY total_sales DESC;


-- =====================================================
-- Question 11
-- Average delivery time
-- =====================================================

SELECT  
    ROUND(AVG(delivery_days), 2) AS avg_delivery_time
FROM (
    SELECT 
        julianday(o.order_delivered_customer_date) 
        - julianday(o.order_purchase_timestamp) AS delivery_days
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
) AS delivery_times;


-- =====================================================
-- Question 12
-- Percentage of delayed deliveries
-- =====================================================

SELECT  
    ROUND(late_deliveries * 100.0 / total_deliveries, 2) 
    AS delayed_delivery_percentage
FROM (
    SELECT 
        SUM(
            CASE 
                WHEN order_delivered_customer_date > order_estimated_delivery_date 
                THEN 1
                ELSE 0
            END
        ) AS late_deliveries,
        
        COUNT(*) AS total_deliveries
     
    FROM orders o
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
) AS delivery_summary;


-- =====================================================
-- Question 13
-- Does delivery delay affect customer reviews?
-- =====================================================


WITH delivery_reviews AS (
    SELECT 
        r.review_score,
        
        CASE 
            WHEN o.order_delivered_customer_date 
                 > o.order_estimated_delivery_date 
            THEN 'Delayed'
            ELSE 'On-Time'
        END AS delivery_status

    FROM orders o
    INNER JOIN reviews r 
        ON r.order_id = o.order_id
        
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)

SELECT 
    delivery_status,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM delivery_reviews
GROUP BY delivery_status;


-- =====================================================
-- Question 14
-- Most common order statuses
-- =====================================================


   SELECT 
    order_status,
    COUNT(*) AS total_orders,
    
    ROUND(
        COUNT(*) * 100.0 
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- =====================================================
-- Question 15
-- Relationship between freight cost and product price
-- =====================================================

WITH price_stats AS (
    SELECT 
        MIN(price) AS min_price,
        MAX(price) AS max_price
    FROM order_items
)

SELECT 
    CASE
        WHEN price < min_price + ((max_price - min_price) / 3.0)
            THEN 'Cheap'
            
        WHEN price < min_price + (2 * ((max_price - min_price) / 3.0))
            THEN 'Medium'
            
        ELSE 'Expensive'
    END AS price_category,

    ROUND(AVG(freight_value), 2) AS avg_freight_cost

FROM order_items
CROSS JOIN price_stats

GROUP BY price_category
ORDER BY avg_freight_cost DESC;


-- =====================================================
-- Question 16
-- Do expensive products receive better reviews?
-- =====================================================

WITH price_stats AS (
    SELECT 
        MIN(price) AS min_price,
        MAX(price) AS max_price
    FROM order_items
)

SELECT 
    CASE
        WHEN price < min_price + ((max_price - min_price) / 3.0)
            THEN 'Cheap'
            
        WHEN price < min_price + (2 * ((max_price - min_price) / 3.0))
            THEN 'Medium'
            
        ELSE 'Expensive'
    END AS price_category,

    ROUND(AVG(r.review_score), 2) AS avg_review_score

FROM order_items i

CROSS JOIN price_stats

INNER JOIN reviews r 
    ON i.order_id = r.order_id

GROUP BY price_category

ORDER BY avg_review_score DESC;


-- =====================================================
-- Question 17
-- Product categories with highest freight cost
-- =====================================================

SELECT 
    p.product_category_name AS category,

    ROUND(AVG(i.freight_value), 2) AS avg_freight_cost

FROM products p 

INNER JOIN order_items i 
    ON p.product_id = i.product_id

GROUP BY p.product_category_name

ORDER BY avg_freight_cost DESC;


-- =====================================================
-- Question 18
-- Most profitable months
-- =====================================================

SELECT  
    strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,

    ROUND(SUM(p.payment_value), 2) AS total_revenue

FROM orders o

INNER JOIN payments p 
    ON o.order_id = p.order_id

WHERE o.order_status = 'delivered'

GROUP BY order_month

ORDER BY total_revenue DESC;


-- =====================================================
-- Question 19
-- Customer segmentation based on spending
-- =====================================================

WITH customer_spending AS (
    SELECT 
        c.customer_unique_id,
        SUM(p.payment_value) AS total_spent
    FROM customers c
    
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
        
    INNER JOIN payments p
        ON o.order_id = p.order_id
        
    WHERE o.order_status = 'delivered'
    
    GROUP BY c.customer_unique_id
),

spending_stats AS (
    SELECT
        MIN(total_spent) AS min_spending,
        MAX(total_spent) AS max_spending
    FROM customer_spending
)

SELECT
    customer_unique_id,

    ROUND(total_spent, 2) AS total_spent,

    CASE
        WHEN total_spent 
             < min_spending + ((max_spending - min_spending) / 3.0)
            THEN 'Low Value'

        WHEN total_spent 
             < min_spending + (2 * ((max_spending - min_spending) / 3.0))
            THEN 'Medium Value'

        ELSE 'High Value'
    END AS customer_segment

FROM customer_spending

CROSS JOIN spending_stats

ORDER BY total_spent DESC;

-- =====================================================
-- Question 20
-- Seasonal purchasing behavior
-- =====================================================

SELECT  
    strftime('%m', o.order_purchase_timestamp) AS order_month,

    COUNT(DISTINCT o.order_id) AS total_orders

FROM orders o

WHERE o.order_status = 'delivered'

GROUP BY order_month

ORDER BY total_orders DESC;


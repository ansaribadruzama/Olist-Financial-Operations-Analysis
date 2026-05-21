-- 1) Quick overview -- how big is this business?
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.customer_id) AS total_customers,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value
FROM orders o
JOIN order_payments p 
	ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';


-- 2) How has revenue trended month over month?
-- useful to spot seasonal patterns or growth dips
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS orders_placed,
    ROUND(SUM(p.payment_value), 2) AS revenue
FROM orders o
JOIN order_payments p 
	ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month ASC;


-- 3) Which product categories are driving the most revenue?
-- joining translation table to get english names
SELECT
    t.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_selling_price
FROM order_items oi
JOIN products pr 
	ON oi.product_id = pr.product_id
JOIN product_category_translation t 
	ON pr.product_category_name = t.product_category_name
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;


-- 4) Churn check -- how many customers never came back?
-- single purchase = churned for this analysis
SELECT
    churn_status,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM (
    SELECT
        customer_id,
        CASE
	        WHEN COUNT(order_id) = 1 THEN 'One-time buyer'
            ELSE 'Repeat buyer'
        END AS churn_status
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY customer_id
) base
GROUP BY churn_status;


-- 5) Payment methods -- what do customers prefer?
SELECT
    payment_type,
    COUNT(*) AS transactions,
    ROUND(SUM(payment_value), 2) AS total_revenue,
    ROUND(AVG(payment_value), 2) AS avg_transaction_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_revenue DESC;


-- 6) Which states are our biggest markets?
SELECT
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM orders o
JOIN customers c 
	ON o.customer_id = c.customer_id
JOIN order_payments p 
	ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY state
ORDER BY total_revenue DESC
LIMIT 10;


-- 7) Seller performance -- which states have the strongest sellers?
SELECT
    s.seller_state,
    COUNT(DISTINCT oi.seller_id) AS no_of_sellers,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM order_items oi
JOIN sellers s 
	ON oi.seller_id = s.seller_id
GROUP BY s.seller_state
ORDER BY total_revenue DESC
LIMIT 10;


-- 8) Are we delivering on time?
-- comparing actual vs estimated delivery date
SELECT
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
        THEN 'On Time'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;


-- 9) Customer satisfaction -- top rated categories
-- good indicator of product quality per category
SELECT
    t.product_category_name_english AS category,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(r.review_id) AS total_reviews
FROM order_reviews r
JOIN order_items oi 
	ON r.order_id = oi.order_id
JOIN products pr 
	ON oi.product_id = pr.product_id
JOIN product_category_translation t
    ON pr.product_category_name = t.product_category_name
GROUP BY category
ORDER BY avg_rating DESC
LIMIT 10;

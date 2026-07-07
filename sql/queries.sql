-- Головний датасет: позиції доставлених замовлень з контекстом
SELECT 
	o.order_id,
    o.order_purchase_t,
    strftime('%Y-%m', o.order_purchase_t) AS ym,
    cu.customer_state,
    t.product_category_1 AS category_en,
    oi.price,
    oi.freight_value,
    op.payment_type AS payment_method,
    r.review_score
FROM olist_order_items_dataset oi
Join olist_orders_dataset o USING (order_id)
JOIN olist_customers_dataset cu USING (customer_id)
JOIN olist_products_dataset p USING (product_id)
LEFT JOIN product_category_name_translation t USING (product_category)
LEFT JOIN olist_order_payments_dataset op USING (order_id)
LEFT JOIN olist_order_reviews_dataset r USING (order_id)
WHERE o.order_status = 'delivered';

-- Місячний виторг і кількість замовлень
SELECT
	strftime('%Y-%m', o.order_purchase_t) AS ym,
    ROUND(SUM(oi.price), 2) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi USING (order_id)
WHERE o.order_status = 'delivered'
GROUP BY ym
ORDER BY ym;

-- -----------------------------------------------------------------

-- Розвідувальні запити
-- топ-10 категорій за виторгом
SELECT
	t.product_category_1 AS category_en,
    ROUND(SUM(oi.price), 2) AS revenue
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o USING (order_id)
JOIN olist_products_dataset p USING (product_id)
LEFT JOIN product_category_name_translation t USING (product_category)
WHERE o.order_status = 'delivered'
GROUP BY category_en
ORDER BY revenue DESC
LIMIT 10;

-- виторг за штатами (для карти в Tableau)
SELECT
	cu.customer_state,
    ROUND(SUM(oi.price), 2) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o USING (order_id)
JOIN olist_customers_dataset cu USING (customer_id)
WHERE o.order_status = 'delivered'
GROUP BY cu.customer_state
ORDER BY revenue DESC;

-- середня оцінка (review_score) за категоріями
SELECT
	t.product_category_1 AS category_en,
    ROUND(AVG(r.review_score), 2) AS avg_score,
    COUNT(*) AS reviews
FROM olist_order_reviews_dataset r
JOIN olist_order_items_dataset oi USING (order_id)
JOIN olist_products_dataset p USING (product_id)
LEFT JOIN product_category_name_translation t USING (product_category)
GROUP BY category_en
HAVING reviews > 50
ORDER BY avg_score DESC;

-- середній час доставки (різниця між датою купівлі і датою доставки)
SELECT
	ROUND(AVG(julianday(order_delivered_6) - julianday(order_purchase_t)), 1) AS avg_delivery_days
FROM olist_orders_dataset
WHERE order_status = 'delivered' AND order_delivered_6 IS NOT NULL;

-- розподіл способів оплати
SELECT
	payment_type,
    COUNT(*) AS n,
    ROUND(SUM(payment_value), 2) AS total_value
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY n DESC;

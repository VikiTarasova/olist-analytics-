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
-- Дані охоплюють період з вересня 2016 року по серпень 2018 року: загальний виторг становить 13 221 498,11, 
-- загальна кількість замовлень — 96 478; місячний виторг варіюється від 10,90 до 977 544,69, а кількість замовлень — від 1 до 7 289.
	
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
-- топ-10 категорій за виторгом: 
| Category (EN)          | Revenue     |
|------------------------|------------:|
| health_beauty          | 1,233,131.72 |
| watches_gifts          | 1,166,176.98 |
| bed_bath_table         | 1,023,434.76 |
| sports_leisure         |   954,852.55 |
| computers_accessories  |   888,724.61 |
| furniture_decor        |   711,927.69 |
| housewares             |   615,628.69 |
| cool_stuff             |   610,204.10 |
| auto                   |   578,966.65 |
| toys                   |   471,286.48 |

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
-- | Customer State | Revenue      |
-- |---------------|-------------:|
-- | SP            | 5,067,633.16 |
-- | RJ            | 1,759,651.13 |
-- | MG            | 1,552,481.83 |
-- | RS            |   728,897.47 |

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
-- Середня оцінка (review_score) за категоріями товарів знаходиться в діапазоні від 3,49 до 4,45 бала: 
-- найвищий рейтинг має категорія books_general_interest (4,45), а найнижчий — office_furniture (3,49).

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
-- avg_delivery_days 12.6
SELECT
	ROUND(AVG(julianday(order_delivered_6) - julianday(order_purchase_t)), 1) AS avg_delivery_days
FROM olist_orders_dataset
WHERE order_status = 'delivered' AND order_delivered_6 IS NOT NULL;

-- розподіл способів оплати
-- | Payment Type | Number of Payments | Total Value |
-- |--------------|-------------------:|------------:|
-- | credit_card  | 76,795 | 12,542,084.19 |
-- | boleto       | 19,784 | 2,869,361.27 |
-- | voucher      | 5,775  |   379,436.87 |
-- | debit_card   | 1,529  |   217,989.79 |
-- | not_defined  | 3      |         0.00 |

SELECT
	payment_type,
    COUNT(*) AS n,
    ROUND(SUM(payment_value), 2) AS total_value
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY n DESC;

----------------------------------
-- CASE STUDY #1: DANNY'S DINER --
----------------------------------

-- Author: Damian Anthony Wong
-- Date: 04/10/2024

--------------------------
-- CASE STUDY QUESTIONS --
--------------------------

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	sales.customer_id,
	SUM(menu.price) AS total_sales
FROM
	dannys_diner.sales
INNER JOIN
	dannys_diner.menu
	ON sales.product_id = menu.product_id
GROUP BY 
	sales.customer_id
ORDER BY
	sales.customer_id ASC;

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id,
	COUNT(DISTINCT order_date) AS visit_count
FROM 
	dannys_diner.sales
GROUP BY 
	customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH ordered_sales AS (
	SELECT
		sales.customer_id,
		sales.order_date,
		menu.product_name,
		DENSE_RANK() OVER (
			PARTITION BY sales.customer_id
			ORDER BY sales.order_date
		) AS rank
	FROM
		dannys_diner.sales
	INNER JOIN
		dannys_diner.menu
		ON sales.product_id = menu.product_id
)

SELECT
	customer_id,
	product_name
FROM
	ordered_sales
WHERE
	rank = 1;
	
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    menu.product_name, 
    COUNT(sales.product_id) AS purchase_count
FROM 
    dannys_diner.sales
JOIN 
    dannys_diner.menu 
    ON sales.product_id = menu.product_id
GROUP BY 
    menu.product_name
ORDER BY 
    purchase_count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH most_popular_orders AS (
	SELECT
		sales.customer_id,
		menu.product_name,
		COUNT(sales.product_id) AS purchase_count,
		DENSE_RANK() OVER (
			PARTITION BY sales.customer_id
			ORDER BY COUNT(sales.customer_id) DESC
		) AS rank
	FROM
		dannys_diner.sales
	INNER JOIN
		dannys_diner.menu
		ON sales.product_id = menu.product_id
	GROUP BY
		sales.customer_id,
		menu.product_name
)

SELECT
	customer_id,
	product_name,
	purchase_count
FROM
	most_popular_orders
WHERE
	rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH purchases_after_membership AS (
	SELECT
		sales.customer_id,
		sales.order_date,
		menu.product_name,
		members.join_date,
		ROW_NUMBER() OVER (
			PARTITION BY sales.customer_id
			ORDER BY sales.order_date
		) AS rank
	FROM
		dannys_diner.sales
	INNER JOIN dannys_diner.menu
		ON sales.product_id = menu.product_id
	INNER JOIN dannys_diner.members
		ON sales.customer_id = members.customer_id
	WHERE
		sales.order_date > members.join_date
)
SELECT
	customer_id,
	product_name
FROM
	purchases_after_membership
WHERE
	rank = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH purchases_before_membership AS (
	SELECT
		sales.customer_id,
		sales.order_date,
		menu.product_name,
		members.join_date,
		ROW_NUMBER() OVER (
			PARTITION BY sales.customer_id
			ORDER BY sales.order_date DESC
		) AS rank
	FROM
		dannys_diner.sales
	INNER JOIN dannys_diner.menu
		ON sales.product_id = menu.product_id
	INNER JOIN dannys_diner.members
		ON sales.customer_id = members.customer_id
	WHERE
		sales.order_date < members.join_date
)

SELECT
	customer_id,
	product_name
FROM
	purchases_before_membership
WHERE
	rank = 1;
	
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
	sales.customer_id,
	COUNT(sales.product_id) as total_product,
	SUM(menu.price) as total_sales
FROM
	dannys_diner.sales
INNER JOIN dannys_diner.members
	ON sales.customer_id = members.customer_id
	AND sales.order_date < members.join_date
INNER JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
GROUP BY
	sales.customer_id
ORDER BY
	sales.customer_id;
	
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_calc AS (
	SELECT
		menu.product_id,
		CASE
			WHEN product_id = 1 THEN price * 20
			ELSE price * 10 END AS points
	FROM
		dannys_diner.menu
)

SELECT
	sales.customer_id,
	SUM(points_calc.points) AS total_points
FROM
	dannys_diner.sales
INNER JOIN points_calc
  ON sales.product_id = points_calc.product_id
GROUP BY
	sales.customer_id
ORDER BY
	sales.customer_id;
	
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH dates_calc AS (
	SELECT
		customer_id,
		join_date,
		join_date + INTERVAL '6 days' AS valid_date,
		'2021-01-31'::DATE AS last_date
	FROM
		dannys_diner.members
)

SELECT
	sales.customer_id,
	SUM(CASE
	   	WHEN menu.product_name = 'sushi' THEN 2 * 10 * menu.price
	   	WHEN sales.order_date BETWEEN dates_calc.join_date AND dates_calc.valid_date THEN 2 * 10 * menu.price
	   	ELSE 10 * menu.price
	END) AS points
FROM
	dannys_diner.sales
INNER JOIN dates_calc
	ON sales.customer_id = dates_calc.customer_id
	AND sales.order_date BETWEEN dates_calc.join_date AND dates_calc.last_date
INNER JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
GROUP BY
	sales.customer_id
ORDER BY
	sales.customer_id;
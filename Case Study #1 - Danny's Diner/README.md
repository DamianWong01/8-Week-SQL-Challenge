# Case Study #1 - Danny's Diner

## Problem Statement
Danny wants to analyze customer data to understand their visiting patterns, spending habits, and favorite menu items to enhance customer experience and personalize loyalty programs. He has provided a sample dataset due to privacy concerns, and the analysis will be based on a database schema that includes relevant tables and relationships.

## Data Structure
![image](https://github.com/user-attachments/assets/5a22cefd-8acd-4c75-a29e-ed94e65c9fb9)


## Case Study Questions
1. What is the total amount each customer spent at the restaurant?

To find out how much each customer spent, we need to sum the price of all items they purchased, and then grouping by `customer_id`.
```sql
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
```
| customer_id | total_sales |
|-------------|-------------|
| A           | 76          |
| B           | 74          |
| C           | 36          |

2. How many days has each customer visited the restaurant?

To determine the number of days each customer visited the restaurant, we need to count the distinct order dates for each customer.
```sql
SELECT
	customer_id,
	COUNT(DISTINCT order_date) AS visit_count
FROM 
	dannys_diner.sales
GROUP BY 
	customer_id;
```
| customer_id | visit_count |
|-------------|-------------|
| A           | 4           |
| B           | 6           |
| C           | 2           |

3. What was the first item from the menu purchased by each customer?

To find the first item purchased by each customer, we need to tank the purchases by order date and select the top-ranked item for each customer.
```sql
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
```
| customer_id | product_name |
|-------------|--------------|
| A           | curry        |
| A           | sushi        |
| B           | curry        |
| C           | ramen        |
| C           | ramen        |

4. What is the most purchased item on the menu and how many times was it purchased by all customers?

To identify the most purchased item, we nede to count the occurrences of each product and order the results in descending order, limiting the output to the top result.
```sql
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
```
| product_name | purchase_count |
|--------------|----------------|
| ramen        | 8              |

5. Which item was the most popular for each customer?

To find the most popular item for each customer, we need to count the purchases of each product by each customer and rank them, selecting the top-ranked items.
```sql
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
```
| customer_id | product_name | purchase_count |
|-------------|--------------|----------------|
| A           | ramen        | 3              |
| B           | sushi        | 2              |
| B           | curry        | 2              |
| B           | ramen        | 2              |
| C           | ramen        | 3              |

6. Which item was purchased first by the customer after they became a member?

To find the first item purchased by each customer after they became a member, we need to filter the sales after the join date and rank the purchases by order date, selecting the top-ranked item.
```sql
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
```
| customer_id | product_name |
|-------------|--------------|
| A           | ramen        |
| B           | sushi        |

7. Which item was purchased just before the customer became a member?

To find the item purchased just before the customer became a member, we need to filter the sales before the join date and rank the purchases by order date in descending order, selecting the top-ranked item.
```sql
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
```
| customer_id | product_name |
|-------------|--------------|
| A           | sushi        |
| B           | sushi        |

8. What is the total items and amount spent for each member before they became a member?

To find the total items and amount spent for each member before they became a member, we need to filter the sales before the join date and sum the prices of the items.
```sql
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
```
| customer_id | total_product | total_sales |
|-------------|---------------|-------------|
| A           | 2             | 25          |
| B           | 3             | 40          |

9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

To calculate the points for each customer, we need to apply the points multiplier for sushi and sum the points for all items.
```sql
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
```
| customer_id | total_points |
|-------------|--------------|
| A           | 860          |
| B           | 940          |
| C           | 360          |

10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

To calculate the points for customers A and B at the end of January, considering the 2x points for the first week after joining, we need to apply the points multiplier based on the join date and order date.
```sql
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
```

| customer_id | points |
|-------------|--------|
| A           | 1020   |
| B           | 320    |

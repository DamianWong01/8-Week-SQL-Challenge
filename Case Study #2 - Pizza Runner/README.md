# Case Study #2 - Pizza Runner

## Problem 

## Data Cleaning and Transformation


## Solutions
### A. Pizza Metrics
1. How many pizzas were ordered?

```sql
SELECT
	COUNT(*) AS ordered_pizza_count
FROM
	customer_orders_temp;
```
2. How many unique customer orders were made?

```sql
SELECT
	COUNT(DISTINCT(order_id))
FROM
	customer_orders_temp;
```
3. How many successful orders were delivered by each runner?

```sql
SELECT
	runner_id,
	COUNT(order_id) AS successful_orders
FROM
	runner_orders_temp
WHERE
	distance IS NOT NULL
GROUP BY
	runner_id
ORDER BY
	runner_id;
```
4. How many of each type of pizza was delivered?

```sql
SELECT
	pizza_name,
	COUNT(customer_orders_temp.pizza_id) AS pizzas_delivered
FROM
	customer_orders_temp
INNER JOIN runner_orders_temp
	ON customer_orders_temp.order_id = runner_orders_temp.order_id
INNER JOIN pizza_names
	ON customer_orders_temp.pizza_id = pizza_names.pizza_id
WHERE
	distance IS NOT NULL
GROUP BY
	pizza_name
```
5. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT
	c.customer_id,
	p.pizza_name,
	COUNT(c.order_id) AS order_count
FROM
	customer_orders_temp AS c
INNER JOIN pizza_names AS p
	ON c.pizza_id = p.pizza_id
GROUP BY
	c.customer_id,
	p.pizza_name
ORDER BY
	customer_id;
```
6. What was the maximum number of pizzas delivered in a single order?

```sql
WITH pizza_rank AS (
	SELECT
		c.order_id,
		COUNT(c.order_id) AS pizza_count,
		RANK() OVER(
			ORDER BY COUNT(c.order_id) DESC)
	FROM
		customer_orders_temp AS c
	INNER JOIN runner_orders_temp AS r
		ON c.order_id = r.order_id
	GROUP BY
		c.order_id
)
SELECT
	order_id,
	pizza_count
FROM
	pizza_rank
WHERE
	rank = 1;
```
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```sql
SELECT
	c.customer_id,
	SUM(
		CASE WHEN c.exclusions <> '' OR c.extras <> '' THEN 1
		ELSE 0
		END) AS at_least_one_change,
	SUM(
		CASE WHEN c.exclusions = '' OR c.extras = '' THEN 1
		ELSE 0
		END) AS no_change
FROM
	customer_orders_temp AS c
INNER JOIN runner_orders_temp AS r
	ON c.order_id = r.order_id
WHERE
	distance IS NOT NULL
GROUP BY
	customer_id
ORDER BY
	customer_id;
```
8. How many pizzas were delivered that had both exclusions and extras?

```sql
SELECT
	SUM(
		CASE WHEN c.exclusions <> '' AND c.extras <> '' THEN 1
		ELSE 0
		END) AS both_changes
FROM
	customer_orders_temp AS c
INNER JOIN runner_orders_temp AS r
	ON c.order_id = r.order_id
WHERE
	distance IS NOT NULL
```
9. What was the total volume of pizzas ordered for each hour of the day?

```sql
SELECT
	EXTRACT(HOUR FROM order_time) AS order_hour,
	COUNT(pizza_id) AS pizza_count
FROM
	customer_orders_temp
GROUP BY
	order_hour
ORDER BY
	order_hour;
```
10. What was the volume of orders for each day of the week?

```sql
SELECT
	TO_CHAR(order_time, 'day') AS day_of_week,
	COUNT(pizza_id) AS pizza_count
FROM
	customer_orders_temp
GROUP BY
	day_of_week
ORDER BY
	day_of_week;
```

### B. Runner and Customer Experience
1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
4. What was the average distance travelled for each customer?
5. What was the difference between the longest and shortest delivery times for all orders?
6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
7. What is the successful delivery percentage for each runner?

### C. Ingredient Optimisation
1. What are the standard ingredients for each pizza?
2. What was the most commonly added extra?
3. What was the most common exclusion?
4. Generate an order item for each record in the customers_orders table in the format of one of the following: Meat Lovers, Meat Lovers - Exclude Beef, Meat Lovers - Extra Bacon, Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients. For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

### D. Pricing and Ratings
1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
2. What if there was an additional $1 charge for any pizza extras?Add cheese is $1 extra
3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries? customer_id, order_id, runner_id, rating, order_time, pickup_time, Time between order and pickup, Delivery duration, Average speed, Total number of pizzas
5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

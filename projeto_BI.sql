# criar dimensão payment adicionando o campo payment_type
# 0 - debit card, 1 - credit card, 2 - cash, else pix
CREATE TABLE d_payment (
	payment_id varchar(10), 
    payment_date datetime,
    amount numeric(16,2),
    payment_type varchar(30)
);

INSERT INTO d_payment(
SELECT 
	payment_id,
	payment_date,
	amount,
	CASE
		WHEN round(RAND() * 3) = 0 THEN "debit card"
		WHEN round(RAND() * 3) = 1 THEN "credit card"
		WHEN round(RAND() * 3) = 2 THEN "cash"
		ELSE "pix"
	END payment_type
FROM payment
);

# criar dimensão category
CREATE TABLE d_category (
	category_id varchar(10),
    name varchar(30)
);

INSERT INTO d_category(
SELECT
	category_id,
	name
FROM category
);

# criar dimensão film
CREATE TABLE d_film (
	film_id varchar(10),
    title varchar(30),
    description varchar(200),
    rental_duration int,
    rental_rate numeric(16,2),
    rating varchar(10)
);

INSERT INTO d_film( 
SELECT 
	film_id, 
    title,
    description,
    rental_duration,
    rental_rate,
    rating
FROM film
);
    
# criar dimensão customer
CREATE TABLE d_customer(
    customer_id varchar(10),
    first_name varchar(50), 
    last_name varchar(50),
    email varchar(100),
    address varchar(60),
    district varchar(30),
    postal_code varchar(10),
    city varchar(50),
    country varchar(50)
);

INSERT INTO d_customer(
SELECT
	a.customer_id,
    a.first_name, 
    a.last_name,
    a.email,
    b.address,
    b.district,
    b.postal_code,
    c.city,
    d.country
FROM customer a
INNER JOIN address b ON a.address_id = b.address_id
INNER JOIN city c ON b.city_id = c.city_id
INNER JOIN country d ON c.country_id = d.country_id
);

# criar dimensão store
CREATE TABLE d_store(
    store_id varchar(10),
    address varchar(60),
    district varchar(30),
    city varchar(50),
    country varchar(50)
);

INSERT INTO d_store(
SELECT
	a.store_id,
    b.address,
    b.district,
    c.city,
    d.country
FROM store a
INNER JOIN address b ON a.address_id = b.address_id
INNER JOIN city c ON b.city_id = c.city_id
INNER JOIN country d ON c.country_id = d.country_id
);

# tabela fato de aluguel de filmes
# trazer category_id, film_id, store_id, payment_id
# INNER JOIN para trazer apenas itens que tenham todas as informações (estejam presentes em todas as tabelas)
CREATE TABLE f_rental (
	rental_id varchar(10),
    rental_date datetime,
    customer_id varchar(10),
    film_id varchar(10),
    store_id varchar(10),
    category_id varchar(10), 
    payment_id varchar(10)
);

INSERT INTO f_rental(
SELECT 
	a.rental_id,
    a.rental_date,
    a.customer_id,
    b.film_id,
    b.store_id,
    c.category_id, 
    d.payment_id
FROM rental a
INNER JOIN inventory b on a.inventory_id = b.inventory_id
INNER JOIN film_category c on b.film_id = c.film_id
INNER JOIN payment d on a.rental_id = d.rental_id
);

# tabela trazendo informações de receita no mês mais atual por categoria (ex de uso CTE e agregações)
WITH max_date AS (
SELECT 
	MONTH(MAX(rental_date)) AS month,
    YEAR(MAX(rental_date)) AS year
FROM f_rental
)
SELECT
	c.name AS category,
	SUM(b.amount) AS revenue,
    AVG(b.amount) AS avg_revenue
FROM f_rental a
INNER JOIN d_payment b ON a.payment_id = b.payment_id
INNER JOIN d_category c ON a.category_id = c.category_id
JOIN max_date m
WHERE YEAR(a.rental_date) = m.year
	AND MONTH(a.rental_date) = m.month
GROUP BY c.name
ORDER BY c.name;
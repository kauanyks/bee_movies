# Introduction

The project was developed based on the simulation of a real company, from the creation of business questions to the development of a data analysis dashboard.

Database: Sakila Sample Database, documentation: https://dev.mysql.com/doc/sakila/en/sakila-introduction.html

The fictional company is called Bee Movies, as the data represents a DVD rental store. The defined business requirements were as follows:

    - Management view of the company's current situation (current month)
    - Analysis of which movie categories are most rented and generate the highest revenue
    - Identification of the company's main customers and their locations
    - Month-by-month revenue analysis and comparison with the target
    - Analysis of which countries are the main customers

# Data Modeling

The database structure follows the diagram below:

![This is an image](https://dev.mysql.com/doc/sakila/en/images/sakila-schema.png)

In order to simplify the relationships and create a star schema in Power BI, the following tables were created:

**d_payment** 

A dimension table containing payment information for the rentals.
```
schema = (
    payment_id varchar(10), 
    payment_date datetime,
    amount numeric(16,2),
    payment_type varchar(30)
)
```
To enable a more detailed analysis, the "payment_type" field was created by generating random numbers and assigning a payment method based on the generated number.
```
CASE
    WHEN round(RAND() * 3) = 0 THEN "debit card"
    WHEN round(RAND() * 3) = 1 THEN "credit card"
    WHEN round(RAND() * 3) = 2 THEN "cash"
    ELSE "pix"
END payment_type
```
The remaining information comes from the original "payment" table.

**d_category**

A dimension table with the category name derived from the category ID. All information comes from the original "category" table.
```
schema = (
    category_id varchar(10),
    name varchar(30)
)
```
**d_film**

A dimension table containing movie information. All data comes from the original "film" table.
```
schema = (
    film_id varchar(10),
    title varchar(30),
    description varchar(200),
    rental_duration int,
    rental_rate numeric(16,2),
    rating varchar(10)
)
```
**d_customer**

A dimension table containing customer information. The data comes from the original "customer," "address," "city," and "country" tables.
```
schema = (
    customer_id varchar(10),
    first_name varchar(50), 
    last_name varchar(50),
    email varchar(100),
    address varchar(60),
    district varchar(30),
    postal_code varchar(10),
    city varchar(50),
    country varchar(50)
)
```
**d_store**

A dimension table containing store information. The data comes from the original "store," "address," "city," and "country" tables.
```
schema = (
    store_id varchar(10),
    address varchar(60),
    district varchar(30),
    city varchar(50),
    country varchar(50)
)
```
**f_rental**

A fact table containing rental occurrences along with the fields category_id, film_id, store_id, and payment_id. The data comes from the original "rental," "inventory," "film_category," and "payment" tables.
```
schema = (
    rental_id varchar(10),
    rental_date datetime,
    customer_id varchar(10),
    film_id varchar(10),
    store_id varchar(10),
    category_id varchar(10), 
    payment_id varchar(10)
)
```
# Dashboard

## Star Schema

Based on the data modeling, a connection was established between Power BI and the Sakila database from the localhost.

Within the BI tool, a d_calendar table was created with variable dates based on the dates present in the fact table, ensuring that the entire required period was covered.
```
d_calendar = CALENDAR(MIN(f_rental[rental_date]), MAX(f_rental[rental_date]))
```
Except for the d_calendar, all dimension tables were linked to the fact table by the corresponding ID, using a one-to-many relationship. The calendar was related through the date, using a 1:1 relationship.

## Dashboard

All pages, except for the home screen, feature synchronized filters for year, month, country, and customer name. This means that any changes made to these filters on one page are automatically reflected across all other pages.

### Home

A home screen was created displaying the key information in a managerial format. To show only the most recent information (current month), a calculated column (boolean) was added to the calendar table using the formula described below. A page filter was then applied to select only the data identified as the reference month in the formula.
```
mes_ref = IF(AND(YEAR(d_calendar[Date]) = YEAR(MAX(d_calendar[Date])), MONTH(d_calendar[Date]) = MONTH(MAX(d_calendar[Date]))), 1, 0)
```
### Categories

For the analysis of the categories, a historical evolution was made available based on the total number of rentals and a top 5. In addition, a matrix was created that presents total rental and revenue values, which can be viewed only by categories or in a more granular way, viewing by films within each category.

### Clients

The customer screen displays Big Numbers related to the total number of customers and the total number of countries served by the company. Additionally, it shows the top 5 customers with the highest rental volumes and their locations on a map*.

*To enable map visualization, you need to activate the feature in Power BI: File > Options and Settings > Options > Global > Security.

### Revenue

The revenue screen has a unique feature compared to the other screens. In addition to the historical evolution graph, the table with more granular information and the analysis of which payment method is most used, an indicator graph (speedometer) is presented that compares the revenue achieved with the defined target. To achieve this, the indicator feature was used, which allows for a hidden filter linked to the action of a button. It was also necessary to change the interactions between the screen components, so that the hidden filter would only work for the speedometer while the other filters on the screen would work for the other views. In addition, there is also the use of conditional formatting based on a measure that defines the color of this speedometer, with green for values ​​above the target and red for values ​​below.

```
rev_conditional_format = 
    SWITCH(
        TRUE(),
        SUM(d_payment[amount]) >= [rev_target_amount], "#00E6BB",
        SUM(d_payment[amount]) < [rev_target_amount], "#e6002b"
    )
```

### Countries

Finally, the country analysis screen presents simpler graphs, but with a detail different from the others: the graph that shows the total number of customers by country has a personalized tooltip, which, when hovering the mouse over each bar on the graph, displays a table with the name and address of the customers.

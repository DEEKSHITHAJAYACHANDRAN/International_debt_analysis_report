use debt_db;

#Basic Queries
#Retrieve all distinct country names from the dataset.
SELECT distinct country_name as countries from dim_country;

#Count the total number of countries available.

SELECT distinct count(country_name) as Total_countries from dim_country;

#Find the total number of indicators present.

SELECT count(indicator_name) from dim_series;

#Display the first 10 records of the dataset.

SELECT * 
FROM fact_debt
LIMIT 10;

#Calculate the total global debt.

SELECT sum(value) as Total_debt from fact_debt;

#List all unique indicator names.

SELECT DISTINCT indicator_name from dim_series;

#Find the number of records for each country.

SELECT 
    c.country_name,
    COUNT(*) AS record_count
FROM fact_debt f
JOIN dim_country c 
    ON f.country_code = c.country_code
GROUP BY c.country_name
ORDER BY record_count DESC;

#Display all records where debt is greater than 1 billion USD.

SELECT *
FROM fact_debt
WHERE value > 1000000000;

#Find the minimum, maximum, and average debt values.

SELECT min(value) as Min_debt, max(value) as Max_debt, avg(value) Avg_debt from fact_debt;

#Count total number of records in the dataset.

select COUNT(*) as Total_records from fact_debt;

#########################################################################################################

#Intermediate Level

#Find the total debt for each country.

SELECT c.country_name as Country,sum(value) as Total_debt from fact_debt as f
join dim_country as c
on f.country_code = c.country_code
group by Country
Order by Total_debt DESC;

#Display the top 10 countries with the highest total debt.

SELECT c.country_name as Country,sum(value) as Total_debt from fact_debt as f
join dim_country as c
on f.country_code = c.country_code
group by Country
Order by Total_debt DESC
limit 10;

#Find the average debt per country.

SELECT c.country_name as Country,avg(value) as Avg_debt from fact_debt as f
join dim_country as c
on f.country_code = c.country_code
group by Country
Order by Avg_debt DESC;

#Calculate total debt for each indicator.

SELECT s.indicator_name,sum(value) as Total_debt_per_indicator from fact_debt as f
join dim_series as s
on s.series_code = f.series_code
GROUP BY s.indicator_name
ORDER BY Total_debt_per_indicator DESC;

#Identify the indicator contributing the highest total debt.
SELECT s.indicator_name,sum(value) as Total_debt_per_indicator from fact_debt as f
join dim_series as s
on s.series_code = f.series_code
GROUP BY s.indicator_name
ORDER BY Total_debt_per_indicator DESC
limit 1;

#Find the country with the lowest total debt.

SELECT c.country_name as Country,sum(value) as Total_debt from fact_debt as f
join dim_country as c
on f.country_code = c.country_code
group by Country
Order by Total_debt ASC
limit 1;


#Calculate total debt for each country and indicator combination.

SELECT c.country_name as Country,s.indicator_name as Indicator_name ,sum(value) as Total_debt from fact_debt as f
join dim_country as c
on f.country_code = c.country_code
join dim_series as s
on s.series_code = f.series_code
group by Country,Indicator_name
Order by Total_debt DESC;

#Count how many indicators each country has.

SELECT 
    c.country_name,
    COUNT(DISTINCT f.series_code) AS indicator_count
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
GROUP BY c.country_name
ORDER BY indicator_count DESC;

#Display countries whose total debt is above the global average.

SELECT c.country_name as Country,sum(value) as Total_per_country from fact_debt as f
join dim_country as c
on f.country_code = c.country_code
group by Country
having Total_per_country > (SELECT AVG(total_country)
    FROM (
        SELECT 
            SUM(value) AS total_country
        FROM fact_debt
        GROUP BY country_code
    ) t
);
#Rank countries based on total debt (highest to lowest).'


SELECT 
    c.country_name AS country,
    SUM(f.value) AS total_debt,
    DENSE_RANK() OVER (ORDER BY SUM(f.value) DESC) AS country_rank
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
GROUP BY c.country_name;


#Advanced Level
#Find the top 5 indicators contributing most to global debt.

SELECT 
    s.indicator_name,
    SUM(f.value) AS total_debt
FROM fact_debt f
JOIN dim_series s
    ON f.series_code = s.series_code
GROUP BY s.indicator_name
ORDER BY total_debt DESC
LIMIT 5;

#Calculate percentage contribution of each country to total global debt.

SELECT 
    c.country_name,
    SUM(f.value) AS total_debt,
    SUM(f.value) / (SELECT SUM(value) FROM fact_debt) * 100 AS percentage_contribution
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
GROUP BY c.country_name
ORDER BY percentage_contribution DESC;

#Identify the top 3 countries for each indicator based on debt.

 SELECT *
FROM (
    SELECT 
        s.indicator_name,
        c.country_name,
        SUM(f.value) AS total_debt,
        DENSE_RANK() OVER (
            PARTITION BY s.indicator_name
            ORDER BY SUM(f.value) DESC
        ) AS rnk
    FROM fact_debt f
    JOIN dim_country c 
        ON f.country_code = c.country_code
    JOIN dim_series s 
        ON f.series_code = s.series_code
    GROUP BY s.indicator_name, c.country_name
) t
WHERE rnk <= 3;

#Find the difference between maximum and minimum debt for each country.

SELECT 
    c.country_name,
    MAX(f.value) AS max_debt,
    MIN(f.value) AS min_debt,
    MAX(f.value) - MIN(f.value) AS debt_difference
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
GROUP BY c.country_name
ORDER BY debt_difference DESC;

#Create a view for the top 10 countries with highest debt.

CREATE VIEW top_10_countries_debt AS
SELECT 
    c.country_name,
    SUM(f.value) AS total_debt
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
GROUP BY c.country_name
ORDER BY total_debt DESC
LIMIT 10;

#Categorize countries into:
#High Debt
#Medium Debt
#Low Debt (based on thresholds)

SELECT 
    c.country_name,
    SUM(f.value) AS total_debt,
    CASE 
        WHEN SUM(f.value) > 1000000000000 THEN 'High Debt'
        WHEN SUM(f.value) BETWEEN 500000000000 AND 1000000000000 THEN 'Medium Debt'
        ELSE 'Low Debt'
    END AS debt_category
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
GROUP BY c.country_name
ORDER BY total_debt DESC;

#Use window functions to calculate cumulative debt per country.

SELECT 
    c.country_name,
    f.year,
    f.value,
    SUM(f.value) OVER (
        PARTITION BY c.country_name
        ORDER BY f.year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_debt
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code;

#Find indicators where average debt is higher than overall average debt.

SELECT 
    s.indicator_name,
    AVG(f.value) AS avg_debt
FROM fact_debt f
JOIN dim_series s
    ON f.series_code = s.series_code
GROUP BY s.indicator_name
HAVING AVG(f.value) > (
    SELECT AVG(value) 
    FROM fact_debt
);

#Identify countries contributing more than 5% of global debt.

SELECT 
    c.country_name,
    SUM(f.value) AS total_debt,
    SUM(f.value) / (SELECT SUM(value) FROM fact_debt) * 100 AS percentage
FROM fact_debt f
JOIN dim_country c
    ON f.country_code = c.country_code
GROUP BY c.country_name
HAVING percentage > 5
ORDER BY percentage DESC;

#Find the most dominant indicator (highest contribution) for each country.

SELECT *
FROM (
    SELECT 
        c.country_name,
        s.indicator_name,
        SUM(f.value) AS total_debt,
        DENSE_RANK() OVER (
            PARTITION BY c.country_name
            ORDER BY SUM(f.value) DESC
        ) AS rnk
    FROM fact_debt f
    JOIN dim_country c
        ON f.country_code = c.country_code
    JOIN dim_series s
        ON f.series_code = s.series_code
    GROUP BY c.country_name, s.indicator_name
) t
WHERE rnk = 1;






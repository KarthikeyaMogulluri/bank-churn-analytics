-- 02_analysis.sql
-- Each query answers one business question. Queries are separated by a line
-- starting with "-- Q" so run_pipeline.py can run and print them one by one.

-- Q1. How big is the churn problem?
SELECT COUNT(*)                                   AS customers,
       SUM(churned)                               AS churned,
       ROUND(100.0 * AVG(churned), 1)             AS churn_rate_pct,
       ROUND(SUM(CASE WHEN churned = 1 THEN balance END) / 1e6, 1) AS balance_lost_millions
FROM churn_base;

-- Q2. Which country loses the most customers and money?
SELECT country,
       COUNT(*)                                   AS customers,
       ROUND(100.0 * AVG(churned), 1)             AS churn_rate_pct,
       ROUND(SUM(CASE WHEN churned = 1 THEN balance END) / 1e6, 1) AS balance_lost_millions,
       ROUND(100.0 * SUM(CASE WHEN churned = 1 THEN balance END)
             / SUM(SUM(CASE WHEN churned = 1 THEN balance END)) OVER (), 1) AS share_of_balance_lost_pct
FROM churn_base
GROUP BY country
ORDER BY churn_rate_pct DESC;

-- Q3. Counterfactual: is Germany worse only because it has no zero-balance customers?
SELECT country,
       balance_band,
       COUNT(*)                                   AS customers,
       ROUND(100.0 * AVG(churned), 1)             AS churn_rate_pct
FROM churn_base
GROUP BY country, balance_band
ORDER BY balance_band, country;

-- Q4. Does holding more products keep customers?
SELECT num_products,
       COUNT(*)                                   AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS share_of_customers_pct,
       ROUND(100.0 * AVG(churned), 1)             AS churn_rate_pct
FROM churn_base
GROUP BY num_products
ORDER BY num_products;

-- Q5. Which age groups leave, and does being active matter?
SELECT age_band,
       COUNT(*)                                   AS customers,
       ROUND(100.0 * AVG(CASE WHEN is_active = 1 THEN churned END), 1) AS churn_active_pct,
       ROUND(100.0 * AVG(CASE WHEN is_active = 0 THEN churned END), 1) AS churn_inactive_pct,
       ROUND(100.0 * AVG(churned), 1)             AS churn_rate_pct
FROM churn_base
GROUP BY age_band
ORDER BY age_band;

-- Q6. Does credit score predict churn? (often assumed, worth checking)
SELECT credit_band,
       COUNT(*)                                   AS customers,
       ROUND(100.0 * AVG(churned), 1)             AS churn_rate_pct
FROM churn_base
GROUP BY credit_band
ORDER BY credit_band;

-- Q7. Riskiest segments (min 100 customers), ranked with a window function
WITH seg AS (
    SELECT country, age_band,
           CASE WHEN is_active = 1 THEN 'Active' ELSE 'Inactive' END AS activity,
           COUNT(*) AS customers,
           ROUND(100.0 * AVG(churned), 1) AS churn_rate_pct
    FROM churn_base
    GROUP BY country, age_band, activity
    HAVING COUNT(*) >= 100
)
SELECT DENSE_RANK() OVER (ORDER BY churn_rate_pct DESC) AS risk_rank, *
FROM seg
ORDER BY risk_rank
LIMIT 8;

-- Q8. Retention target list: customers still with the bank who match the riskiest pattern
SELECT COUNT(*)                                   AS customers_to_contact,
       ROUND(SUM(balance) / 1e6, 1)               AS balance_at_risk_millions
FROM churn_base
WHERE churned = 0
  AND is_active = 0
  AND age BETWEEN 40 AND 59
  AND balance > 0;

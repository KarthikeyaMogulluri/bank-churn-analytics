-- 01_clean_and_model.sql
-- Turns the two raw tables into a clean model for analysis and Power BI.
-- Input : raw_customer_info (10,001 rows, messy), raw_account_info (10,000 rows)
-- Output: customers, accounts, churn_base (view), data_quality_log

DROP TABLE IF EXISTS data_quality_log;
CREATE TABLE data_quality_log (
    check_name     TEXT,
    rows_affected  INTEGER,
    action_taken   TEXT
);

-- ---------- 1. Record every defect before fixing it ----------
INSERT INTO data_quality_log
SELECT 'Exact duplicate customer rows',
       COUNT(*) - COUNT(DISTINCT CustomerId),
       'Kept the first row per CustomerId (ROW_NUMBER)'
FROM raw_customer_info;

INSERT INTO data_quality_log
SELECT 'Country written as FRA / French instead of France',
       SUM(Geography IN ('FRA', 'French')),
       'Mapped to France'
FROM raw_customer_info;

INSERT INTO data_quality_log
SELECT 'Missing surname', SUM(Surname IS NULL OR TRIM(Surname) = ''), 'Set to Unknown (not used in analysis)'
FROM raw_customer_info;

INSERT INTO data_quality_log
SELECT 'Missing age', SUM(Age IS NULL), 'Left as NULL, shown as age band Unknown (not imputed)'
FROM raw_customer_info;

INSERT INTO data_quality_log
SELECT 'Salary = -999999 (placeholder code)', SUM(EstimatedSalary < 0), 'Set to NULL'
FROM raw_customer_info;

-- ---------- 2. Clean customer table ----------
DROP TABLE IF EXISTS customers;
CREATE TABLE customers AS
WITH ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY CustomerId) AS rn
    FROM raw_customer_info
)
SELECT
    CustomerId                                              AS customer_id,
    COALESCE(NULLIF(TRIM(Surname), ''), 'Unknown')          AS surname,
    CreditScore                                             AS credit_score,
    CASE WHEN Geography IN ('FRA', 'French', 'France') THEN 'France'
         ELSE Geography END                                 AS country,
    Gender                                                  AS gender,
    CAST(Age AS INTEGER)                                    AS age,
    Tenure                                                  AS tenure_years,
    CASE WHEN EstimatedSalary < 0 THEN NULL
         ELSE EstimatedSalary END                           AS estimated_salary,
    CASE WHEN Age IS NULL THEN 'Unknown'
         WHEN Age < 30 THEN '18-29'
         WHEN Age < 40 THEN '30-39'
         WHEN Age < 50 THEN '40-49'
         WHEN Age < 60 THEN '50-59'
         ELSE '60+' END                                     AS age_band,
    CASE WHEN CreditScore < 580 THEN '1 Poor (<580)'
         WHEN CreditScore < 670 THEN '2 Fair (580-669)'
         WHEN CreditScore < 740 THEN '3 Good (670-739)'
         WHEN CreditScore < 800 THEN '4 Very good (740-799)'
         ELSE '5 Excellent (800+)' END                      AS credit_band
FROM ranked
WHERE rn = 1;

-- ---------- 3. Account table ----------
DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts AS
SELECT
    CustomerId      AS customer_id,
    Balance         AS balance,
    NumOfProducts   AS num_products,
    HasCrCard       AS has_credit_card,
    IsActiveMember  AS is_active,
    Exited          AS churned,
    CASE WHEN Balance = 0       THEN '1 Zero'
         WHEN Balance < 100000  THEN '2 Under 100K'
         WHEN Balance < 150000  THEN '3 100K-150K'
         ELSE '4 150K+' END     AS balance_band
FROM raw_account_info;

-- ---------- 4. One wide view for analysis ----------
DROP VIEW IF EXISTS churn_base;
CREATE VIEW churn_base AS
SELECT c.*, a.balance, a.num_products, a.has_credit_card, a.is_active, a.churned, a.balance_band
FROM customers c
JOIN accounts  a ON a.customer_id = c.customer_id;

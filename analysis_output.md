## Data quality log

| check_name                                        |   rows_affected | action_taken                                          |
|:--------------------------------------------------|----------------:|:------------------------------------------------------|
| Exact duplicate customer rows                     |               1 | Kept the first row per CustomerId (ROW_NUMBER)        |
| Country written as FRA / French instead of France |            3274 | Mapped to France                                      |
| Missing surname                                   |               3 | Set to Unknown (not used in analysis)                 |
| Missing age                                       |               3 | Left as NULL, shown as age band Unknown (not imputed) |
| Salary = -999999 (placeholder code)               |               3 | Set to NULL                                           | 

## Q1. How big is the churn problem?

|   customers |   churned |   churn_rate_pct |   balance_lost_millions |
|------------:|----------:|-----------------:|------------------------:|
|       10000 |      2037 |             20.4 |                   185.6 | 

## Q2. Which country loses the most customers and money?

| country   |   customers |   churn_rate_pct |   balance_lost_millions |   share_of_balance_lost_pct |
|:----------|------------:|-----------------:|------------------------:|----------------------------:|
| Germany   |        2509 |             32.4 |                    98   |                        52.8 |
| Spain     |        2477 |             16.7 |                    29.9 |                        16.1 |
| France    |        5014 |             16.2 |                    57.7 |                        31.1 | 

## Q3. Counterfactual: is Germany worse only because it has no zero-balance customers?

| country   | balance_band   |   customers |   churn_rate_pct |
|:----------|:---------------|------------:|-----------------:|
| France    | 1 Zero         |        2418 |             13.9 |
| Spain     | 1 Zero         |        1199 |             13.6 |
| France    | 2 Under 100K   |         688 |             18.9 |
| Germany   | 2 Under 100K   |         543 |             19.9 |
| Spain     | 2 Under 100K   |         353 |             24.9 |
| France    | 3 100K-150K    |        1476 |             16.1 |
| Germany   | 3 100K-150K    |        1652 |             39.1 |
| Spain     | 3 100K-150K    |         702 |             14.7 |
| France    | 4 150K+        |         432 |             24.3 |
| Germany   | 4 150K+        |         314 |             19.1 |
| Spain     | 4 150K+        |         223 |             26.5 | 

## Q4. Does holding more products keep customers?

|   num_products |   customers |   share_of_customers_pct |   churn_rate_pct |
|---------------:|------------:|-------------------------:|-----------------:|
|              1 |        5084 |                     50.8 |             27.7 |
|              2 |        4590 |                     45.9 |              7.6 |
|              3 |         266 |                      2.7 |             82.7 |
|              4 |          60 |                      0.6 |            100   | 

## Q5. Which age groups leave, and does being active matter?

| age_band   |   customers |   churn_active_pct |   churn_inactive_pct |   churn_rate_pct |
|:-----------|------------:|-------------------:|---------------------:|-----------------:|
| 18-29      |        1641 |                5.4 |                  9.8 |              7.6 |
| 30-39      |        4344 |                8.2 |                 13.6 |             10.9 |
| 40-49      |        2617 |               22.6 |                 38   |             30.8 |
| 50-59      |         869 |               37.1 |                 81.2 |             56   |
| 60+        |         526 |               12.5 |                 85.6 |             27.9 |
| Unknown    |           3 |                0   |                  0   |              0   | 

## Q6. Does credit score predict churn? (often assumed, worth checking)

| credit_band           |   customers |   churn_rate_pct |
|:----------------------|------------:|-----------------:|
| 1 Poor (<580)         |        2362 |             22   |
| 2 Fair (580-669)      |        3331 |             20.6 |
| 3 Good (670-739)      |        2428 |             18.6 |
| 4 Very good (740-799) |        1224 |             20.6 |
| 5 Excellent (800+)    |         655 |             19.5 | 

## Q7. Riskiest segments (min 100 customers), ranked with a window function

|   risk_rank | country   | age_band   | activity   |   customers |   churn_rate_pct |
|------------:|:----------|:-----------|:-----------|------------:|-----------------:|
|           1 | Germany   | 50-59      | Inactive   |         146 |             86.3 |
|           2 | France    | 50-59      | Inactive   |         152 |             77.6 |
|           3 | Germany   | 40-49      | Inactive   |         414 |             51.9 |
|           3 | Germany   | 50-59      | Active     |         131 |             51.9 |
|           4 | Germany   | 40-49      | Active     |         325 |             36.6 |
|           5 | France    | 50-59      | Active     |         230 |             34.3 |
|           6 | Spain     | 40-49      | Inactive   |         332 |             33.1 |
|           7 | France    | 40-49      | Inactive   |         650 |             31.5 | 

## Q8. Retention target list: customers still with the bank who match the riskiest pattern

|   customers_to_contact |   balance_at_risk_millions |
|-----------------------:|---------------------------:|
|                    579 |                       69.5 | 

Exported model tables to D:\bank-churn-analytics\data\model

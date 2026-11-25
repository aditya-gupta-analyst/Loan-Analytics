/* ============================================================================
   LOAN PORTFOLIO ANALYTICS: BUSINESS PROBLEMS 1 - 7
   Author   : Aditya Gupta
   Database : MySQL 8.0+  (PostgreSQL notes are given where syntax differs)
   Tables   : customers, loans, payments   (see setup.sql)
   Data     : synthetic, as of 31-Dec-2025
   ============================================================================ */


/* ----------------------------------------------------------------------------
   Q1. Latest loan per customer
   Business ask : For every customer, return their most recent loan
                  (loan_id, loan_type, loan_amount, status).
   Technique    : ROW_NUMBER() with PARTITION BY
   Note         : loan_id DESC is a tie-breaker so the result is always stable.
   Expected     : one row per customer who has at least one loan
   ---------------------------------------------------------------------------- */
WITH ranked_loans AS (
    SELECT customer_id, loan_id, loan_type, loan_amount, status, disbursal_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY disbursal_date DESC, loan_id DESC) AS rn
    FROM loans
)
SELECT customer_id, loan_id, loan_type, loan_amount, status, disbursal_date
FROM ranked_loans
WHERE rn = 1;


/* ----------------------------------------------------------------------------
   Q2. Loan size ranking within each loan type (RANK vs DENSE_RANK)
   Business ask : Rank loans by amount (highest first) within each loan type,
                  showing a version that leaves gaps after ties and one that
                  does not.
   Technique    : RANK(), DENSE_RANK() with PARTITION BY
   ---------------------------------------------------------------------------- */
SELECT loan_id, loan_type, loan_amount,
       RANK()       OVER (PARTITION BY loan_type ORDER BY loan_amount DESC) AS rnk,
       DENSE_RANK() OVER (PARTITION BY loan_type ORDER BY loan_amount DESC) AS dense_rnk
FROM loans
ORDER BY loan_type, loan_amount DESC;

/* Explanation with an example from the data:
   In the 'Business' loan type, two loans have the same amount of 2,902,000.
       loan_amount   RANK   DENSE_RANK
       2,908,000      10       10
       2,902,000      11       11
       2,902,000      11       11
       2,884,000      13       12     <-- RANK skips 12, DENSE_RANK does not
   RANK() leaves a gap after a tie (11, 11, 13).
   DENSE_RANK() never skips a number (11, 11, 12).                           */

-- Query to list all tied loans so the example above can be verified:
SELECT *
FROM (
    SELECT loan_id, loan_type, loan_amount,
           RANK()       OVER (PARTITION BY loan_type ORDER BY loan_amount DESC) AS rnk,
           DENSE_RANK() OVER (PARTITION BY loan_type ORDER BY loan_amount DESC) AS dense_rnk,
           COUNT(*)     OVER (PARTITION BY loan_type, loan_amount)              AS same_amount_count
    FROM loans
) t
WHERE same_amount_count > 1
ORDER BY loan_type, loan_amount DESC;


/* ----------------------------------------------------------------------------
   Q3. Top 3 largest loans in each city
   Business ask : Find the 3 largest loans per city (join loans with customers).
   Technique    : ROW_NUMBER() + JOIN + CTE
   Tie choice   : ROW_NUMBER() returns exactly 3 loans per city; ties are broken
                  by the smaller loan_id.
                  (DENSE_RANK() <= 3 would keep the top 3 distinct amounts and
                   can return more than 3 rows per city.)
   Expected     : 8 cities x 3 loans = 24 rows
   ---------------------------------------------------------------------------- */
WITH ranked_loans AS (
    SELECT l.loan_id, l.customer_id, c.city, l.loan_amount,
           ROW_NUMBER() OVER (PARTITION BY c.city
                              ORDER BY l.loan_amount DESC, l.loan_id) AS rn
    FROM loans l
    JOIN customers c ON c.customer_id = l.customer_id
)
SELECT city, loan_id, customer_id, loan_amount, rn
FROM ranked_loans
WHERE rn <= 3
ORDER BY city, rn;


/* ----------------------------------------------------------------------------
   Q4. Cumulative disbursals by month
   Business ask : Show the monthly disbursed amount and the cumulative total
                  up to and including each month.
   Technique    : GROUP BY in a CTE, then SUM() OVER with a running frame
   Check        : last cumulative_disbursed = SELECT SUM(loan_amount) FROM loans
                  (3,161,498,000)
   PostgreSQL   : replace DATE_FORMAT(x,'%Y-%m') with TO_CHAR(x,'YYYY-MM')
   ---------------------------------------------------------------------------- */
WITH monthly AS (
    SELECT DATE_FORMAT(disbursal_date, '%Y-%m') AS month,
           SUM(loan_amount)                     AS monthly_disbursed
    FROM loans
    GROUP BY DATE_FORMAT(disbursal_date, '%Y-%m')
)
SELECT month,
       monthly_disbursed,
       SUM(monthly_disbursed) OVER (ORDER BY month
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                                   ) AS cumulative_disbursed
FROM monthly
ORDER BY month;


/* ----------------------------------------------------------------------------
   Q5. Month-over-month change and growth %
   Business ask : For each month show the amount, previous month's amount,
                  the change and the % growth. Find the biggest drops.
   Technique    : LAG()
   Notes        : First month has NULL for previous amount (no earlier month).
                  NULLIF avoids division by zero.
                  growth % = (current - previous) / previous * 100
   ---------------------------------------------------------------------------- */
WITH monthly AS (
    SELECT DATE_FORMAT(disbursal_date, '%Y-%m') AS month,
           SUM(loan_amount)                     AS monthly_disbursed
    FROM loans
    GROUP BY DATE_FORMAT(disbursal_date, '%Y-%m')
),
with_prev AS (
    SELECT month,
           monthly_disbursed,
           LAG(monthly_disbursed) OVER (ORDER BY month) AS prev_amount
    FROM monthly
)
SELECT month,
       monthly_disbursed                                AS amount,
       prev_amount,
       monthly_disbursed - prev_amount                  AS change_amt,
       ROUND((monthly_disbursed - prev_amount)
             / NULLIF(prev_amount, 0) * 100, 2)         AS growth_pct
FROM with_prev
ORDER BY month;

-- Biggest drops (by amount):
-- Use the query above as a CTE, or add:
--   WHERE prev_amount IS NOT NULL ORDER BY change_amt ASC LIMIT 5;


/* ----------------------------------------------------------------------------
   Q6. Income quartiles and default rate
   Business ask : Split customers into 4 equal income groups; find the share of
                  loans with status = 'Defaulted' in each group.
   Technique    : NTILE(4), JOIN, conditional aggregation (SUM + CASE WHEN)
   Note         : * 100.0 forces decimal division.
   Expected     : 4 rows; total loans = 1,680; total defaulted = 221
   ---------------------------------------------------------------------------- */
WITH income_groups AS (
    SELECT customer_id,
           monthly_income,
           NTILE(4) OVER (ORDER BY monthly_income) AS income_quartile
    FROM customers
)
SELECT g.income_quartile,
       COUNT(DISTINCT g.customer_id)                            AS customers,
       COUNT(l.loan_id)                                         AS total_loans,
       SUM(CASE WHEN l.status = 'Defaulted' THEN 1 ELSE 0 END)  AS defaulted_loans,
       ROUND(SUM(CASE WHEN l.status = 'Defaulted' THEN 1 ELSE 0 END) * 100.0
             / COUNT(l.loan_id), 2)                             AS default_rate_pct
FROM income_groups g
JOIN loans l ON l.customer_id = g.customer_id
GROUP BY g.income_quartile
ORDER BY g.income_quartile;


/* ----------------------------------------------------------------------------
   Q7. 3-month moving average of collections
   Business ask : Total amount_paid per month (by paid_date), then the average
                  of the current month and the two months before it.
   Technique    : GROUP BY in a CTE, then AVG() OVER with a sliding frame
   Note         : The first two months average fewer than 3 values.
   ---------------------------------------------------------------------------- */
WITH monthly_collections AS (
    SELECT DATE_FORMAT(paid_date, '%Y-%m') AS month,
           SUM(amount_paid)                AS collected
    FROM payments
    GROUP BY DATE_FORMAT(paid_date, '%Y-%m')
)
SELECT month,
       collected,
       ROUND(AVG(collected) OVER (ORDER BY month
                                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS three_month_avg
FROM monthly_collections
ORDER BY month;

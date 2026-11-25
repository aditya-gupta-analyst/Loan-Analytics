Loan Portfolio Analytics: Credit Risk and Collections Insights (SQL)
Business Context

A mid-sized retail lender offers Personal, Home, Auto, Education and Business loans across 8 Indian cities. Disbursals have grown quickly, and management, credit risk and collections teams need clearer answers about where the money is going, how it is collected, and which customers carry the most risk.

As the data analyst on the credit analytics team, I used SQL to answer their questions directly from the loan database.

Problem Statement

How can the lender understand its loan book better (who its recent borrowers are, where its largest exposures sit, how disbursals and collections are trending) and identify whether customer income is linked to defaults, so that underwriting and collections can act on it?

Data
Table	Rows	Description
customers	1,200	city, age, monthly income, employment type, credit score, signup date
loans	1,680	loan type, amount, interest rate, tenure, disbursal date, EMI, status (Active / Closed / Defaulted)
payments	31,377	instalment-level due date, paid date, amount paid, days past due (DPD)

Reporting date: 31 December 2025. Data note: this is a synthetic dataset modelled on a retail lending portfolio, so no real customer information is used. Figures should be read as illustrative.

Stakeholder Questions and Analysis
#	Stakeholder	Business question	SQL approach
1	Collections	What is each customer's most recent loan and its status?	ROW_NUMBER() with PARTITION BY
2	Credit Risk	How do loans rank by size within each product, and how do ties affect ranking?	RANK() vs DENSE_RANK()
3	Regional Sales	Which are the 3 largest loans in each city?	ROW_NUMBER(), JOIN, CTE
4	Management	What is the cumulative amount disbursed over time?	Running total with SUM() OVER
5	Management	How is disbursal changing month over month, and when did it drop most?	LAG() and growth %
6	Underwriting	Do lower-income customers default more?	NTILE(4) and conditional aggregation
7	Finance	What is the underlying trend in monthly collections?	3-month moving average (AVG() OVER)

All queries are in solutions.sql, each with the business ask, approach and notes.

Key Findings
Scale and growth: about 3.16 billion disbursed over 58 months (Feb 2021 to Dec 2025), with monthly disbursals growing sharply from 2021 to 2025.
Volatile disbursals: March 2024 saw the largest drop in amount (136.7M to 70.7M, about 48% lower). November 2022 had the largest percentage fall (about 77%).
Income and default: customers in the top income quartile have the lowest default rate (11.0%). The other three quartiles are close together (13.4% to 14.4%), so income alone does not strongly separate risk.
Concentration risk: the largest loans in each product and city are identified in Q2 and Q3, so exposure can be monitored.
Recommendations
Investigate disbursal dips. Find the cause of the March 2024 and November 2022 falls (pipeline, policy change, seasonality) so planning can account for them.
Do not rely on income alone for risk cut-offs. Combine it with credit score, loan-to-income ratio and repayment history when setting underwriting rules.
Monitor the largest exposures. Review top loans by city and product regularly.
Track collections with a smoothed trend. The 3-month average avoids reacting to one-off monthly swings.
Skills Demonstrated

Window functions (ROW_NUMBER, RANK, DENSE_RANK, LAG, NTILE, running totals, moving averages), CTEs, joins, conditional aggregation, business metric design (default rate, growth %), and translating results into recommendations.

How to Reproduce
Create a database in MySQL 8.0+ (PostgreSQL also works; use TO_CHAR in place of DATE_FORMAT).
Run setup.sql to create the tables.
Import the CSV files from /data.
Confirm row counts: 1,200 / 1,680 / 31,377.
Run solutions.sql.
Repository Structure
.
|-- README.md
|-- solutions.sql
|-- setup.sql
`-- data/
    |-- customers.csv
    |-- loans.csv
    `-- payments.csv
Next Steps
Identify concentration of the loan book (which loans make up 80% of the amount).
Flag early-warning accounts with consecutive late payments.
Analyse customer borrowing history and gaps between loans.
Extend the analysis to the Home Credit Default Risk dataset for a full credit-risk study.
Author

Aditya Gupta, Data Analyst (B.Sc. Data Science) LinkedIn | GitHub

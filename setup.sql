-- Works in MySQL 8+ and PostgreSQL. Create a database first, e.g. CREATE DATABASE loan_practice;
CREATE TABLE customers (
  customer_id INT PRIMARY KEY, city VARCHAR(30), age INT, monthly_income INT,
  employment_type VARCHAR(30), credit_score INT, signup_date DATE);
CREATE TABLE loans (
  loan_id INT PRIMARY KEY, customer_id INT, loan_type VARCHAR(20), loan_amount INT,
  interest_rate DECIMAL(5,2), tenure_months INT, disbursal_date DATE, emi_amount INT, status VARCHAR(15));
CREATE TABLE payments (
  payment_id INT PRIMARY KEY, loan_id INT, installment_no INT, due_date DATE,
  paid_date DATE, emi_amount INT, amount_paid INT, dpd INT);

-- PostgreSQL load (run in psql, adjust path):
-- \copy customers FROM 'data/customers.csv' CSV HEADER
-- \copy loans FROM 'data/loans.csv' CSV HEADER
-- \copy payments FROM 'data/payments.csv' CSV HEADER
-- MySQL: use Table Data Import Wizard in Workbench (right-click table > Table Data Import Wizard),
-- or LOAD DATA LOCAL INFILE 'data/loans.csv' INTO TABLE loans FIELDS TERMINATED BY ',' IGNORE 1 LINES;

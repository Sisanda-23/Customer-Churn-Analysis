CREATE DATABASE churn_analysis;
\c churn_analysis
CREATE TABLE customers (
    customer_id VARCHAR PRIMARY KEY,
    gender VARCHAR(10),
    senior_citizen INT,
    partner VARCHAR(5),
    dependents VARCHAR(5),
    tenure INT,
    contract VARCHAR(20),
    paperless_billing VARCHAR(5),
    payment_method VARCHAR(50),
    monthly_charges NUMERIC(10,2),
    total_charges NUMERIC(10,2),
    churn_flag INT
);
COPY customers
FROM "C:\Users\thobi\Downloads\cleaned_data.csv"
DELIMITER ','
CSV HEADER;
SELECT
    customer_id,
    monthly_charges,
    CASE
        WHEN monthly_charges >= PERCENTILE_CONT(0.7) 
             WITHIN GROUP (ORDER BY monthly_charges) THEN 40
        WHEN monthly_charges >= PERCENTILE_CONT(0.3) 
             WITHIN GROUP (ORDER BY monthly_charges) THEN 20
        ELSE 0
    END AS charge_score
FROM customers;
WITH charge_thresholds AS (
    SELECT
        PERCENTILE_CONT(0.3) WITHIN GROUP (ORDER BY monthly_charges) AS p30,
        PERCENTILE_CONT(0.7) WITHIN GROUP (ORDER BY monthly_charges) AS p70
    FROM customers
),
scored_customers AS (
    SELECT
        c.customer_id,
        c.tenure,
        c.contract,
        c.monthly_charges,
        c.churn_flag,

        CASE
            WHEN c.monthly_charges >= t.p70 THEN 40
            WHEN c.monthly_charges >= t.p30 THEN 20
            ELSE 0
        END AS charge_score,

        CASE
            WHEN c.tenure < 12 THEN 35
            WHEN c.tenure < 24 THEN 20
            ELSE 0
        END AS tenure_score,

        CASE
            WHEN c.contract = 'Month-to-month' THEN 25
            WHEN c.contract = 'One year' THEN 10
            ELSE 0
        END AS contract_score

    FROM customers c
    CROSS JOIN charge_thresholds t
)

SELECT *,
       (charge_score + tenure_score + contract_score) AS churn_risk_score,
       CASE
           WHEN (charge_score + tenure_score + contract_score) >= 70 THEN 'High Risk'
           WHEN (charge_score + tenure_score + contract_score) >= 40 THEN 'Medium Risk'
           ELSE 'Low Risk'
       END AS risk_segment
FROM scored_customers;


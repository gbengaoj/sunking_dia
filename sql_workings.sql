
/*
Follow-on Revenue Realization (FRR) is the percentage collected out of the total cost of
 unit remaining after the deposit has been paid.
*/

-- Q1
/** Write and present the formula that allows you to build the FRR **/
/*
FRR = (Collection / Adjusted Total Cost of Unit ) * 100

Where 
Collection = Portfolio Derived Amount
Adjusted Total Cost of Unit = Account Unlock Price - Account Upfront Price
*/

-- Q2

-- FRR Calculation
WITH aggregate_table AS (
    -- Create an aggregate table to derive payment and cost values
    SELECT pd."Portfolio Derived Account Angaza ID" AS account_id,
        SUM(pd."Portfolio Derived Amount") AS total_payment,
        MAX(pd."Portfolio Derived Previous Cumulative Paid") AS cummulative_payment,
        MAX(a."Accounts Unlock Price") AS total_cost,
        MAX(a."Accounts Upfront Price") AS total_deposit
    FROM portfolio_derived AS pd 
    JOIN accounts AS a 
    ON pd."Portfolio Derived Account Angaza ID" = a."Accounts Angaza ID"
    GROUP BY 1
),
sum_table AS (
    -- Aggregate payment and cost values
    SELECT SUM(agt.total_payment) AS overall_total_payment,
       SUM(agt.cummulative_payment) AS overall_cummulative_payment,
       SUM(REPLACE(agt.total_cost,',','')::NUMERIC) AS overall_total_cost,
       SUM(REPLACE(agt.total_deposit,',','')::NUMERIC) AS overall_total_deposit
    FROM aggregate_table AS agt
)
-- Derive FRR
SELECT 
    TO_CHAR(((st.overall_total_payment) / 
    (st.overall_total_cost - st.overall_total_deposit)) * 100, 'fm00D00%') AS "FRR"
FROM sum_table AS st;


-- Q3 (b)

-- FRR performance of Disabled Accounts by area by average repayment tenure gap
SELECT  agg.status AS account_status,
        agg.area,
        CASE WHEN AVG(DATE_PART('day', agg.last_action_date::timestamp - agg.signup_date::timestamp)) > AVG(REPLACE(agg.total_cost,',','')::NUMERIC / (agg.price_per_day)) THEN 'EXPIRED' ELSE 'ACTIVE' END AS tenure_status,
        (ROUND(AVG(REPLACE(agg.total_cost,',','')::NUMERIC / (agg.price_per_day))) - ROUND(AVG(DATE_PART('day', agg.last_action_date::timestamp - agg.signup_date::timestamp)))) AS "avg_tenure_gap (days)",
        ROUND((SUM(agg.total_payment) / (SUM(REPLACE(agg.total_cost,',','')::NUMERIC) - SUM(REPLACE(agg.total_deposit,',','')::NUMERIC))) * 100) AS "FRR (%)",
        ROUND(AVG(DATE_PART('day', agg.last_action_date::timestamp - agg.signup_date::timestamp))) AS "avg_actual_tenure (days)",
        ROUND(AVG(REPLACE(agg.total_cost,',','')::NUMERIC / (agg.price_per_day))) AS "avg_expected_tenure (days)",
        SUM(agg.total_payment) AS overall_total_payment,
        SUM(agg.cummulative_payment) AS overall_cummulative_payment,
        SUM(REPLACE(agg.total_cost,',','')::NUMERIC) AS overall_total_cost,
        SUM(REPLACE(agg.total_deposit,',','')::NUMERIC) AS overall_total_deposit
FROM(
    SELECT pd."Portfolio Derived Account Angaza ID" AS account_id,
        a."Accounts Area" AS area,
        a."Accounts Date of Registration Date" AS signup_date,
        a."Accounts Date of Latest Payment Utc Date" AS last_action_date,
        a."Accounts Account Status" AS status,
        SUM(pd."Portfolio Derived Amount") AS total_payment,
        MAX(pd."Portfolio Derived Previous Cumulative Paid") AS cummulative_payment,
        MAX(a."Accounts Unlock Price") AS total_cost,
        MAX(a."Accounts Upfront Price") AS total_deposit,
        MAX(a."Accounts Price per Day") AS price_per_day
    FROM portfolio_derived AS pd 
    JOIN accounts AS a 
    ON pd."Portfolio Derived Account Angaza ID" = a."Accounts Angaza ID"
    WHERE a."Accounts Account Status" = 'DISABLED'
    GROUP BY 5, 1, 2, 3, 4) AS agg
GROUP BY 1, 2
ORDER BY 3 DESC, 5 ASC, 4 DESC;


-- FRR performance of Enabled Accounts by area by average repayment tenure gap
SELECT  agg.status AS account_status,
        agg.area,
        CASE WHEN AVG(DATE_PART('day', agg.last_action_date::timestamp - agg.signup_date::timestamp)) > AVG(REPLACE(agg.total_cost,',','')::NUMERIC / (agg.price_per_day)) THEN 'EXPIRED' ELSE 'ACTIVE' END AS tenure_status,
        (ROUND(AVG(REPLACE(agg.total_cost,',','')::NUMERIC / (agg.price_per_day))) - ROUND(AVG(DATE_PART('day', agg.last_action_date::timestamp - agg.signup_date::timestamp)))) AS "avg_tenure_gap (days)",
        ROUND((SUM(agg.total_payment) / (SUM(REPLACE(agg.total_cost,',','')::NUMERIC) - SUM(REPLACE(agg.total_deposit,',','')::NUMERIC))) * 100) AS "FRR (%)",
        ROUND(AVG(DATE_PART('day', agg.last_action_date::timestamp - agg.signup_date::timestamp))) AS "avg_actual_tenure (days)",
        ROUND(AVG(REPLACE(agg.total_cost,',','')::NUMERIC / (agg.price_per_day))) AS "avg_expected_tenure (days)",
        SUM(agg.total_payment) AS overall_total_payment,
        SUM(agg.cummulative_payment) AS overall_cummulative_payment,
        SUM(REPLACE(agg.total_cost,',','')::NUMERIC) AS overall_total_cost,
        SUM(REPLACE(agg.total_deposit,',','')::NUMERIC) AS overall_total_deposit
FROM(
    SELECT pd."Portfolio Derived Account Angaza ID" AS account_id,
        a."Accounts Area" AS area,
        a."Accounts Date of Registration Date" AS signup_date,
        a."Accounts Date of Latest Payment Utc Date" AS last_action_date,
        a."Accounts Account Status" AS status,
        SUM(pd."Portfolio Derived Amount") AS total_payment,
        MAX(pd."Portfolio Derived Previous Cumulative Paid") AS cummulative_payment,
        MAX(a."Accounts Unlock Price") AS total_cost,
        MAX(a."Accounts Upfront Price") AS total_deposit,
        MAX(a."Accounts Price per Day") AS price_per_day
    FROM portfolio_derived AS pd 
    JOIN accounts AS a 
    ON pd."Portfolio Derived Account Angaza ID" = a."Accounts Angaza ID"
    WHERE a."Accounts Account Status" = 'ENABLED'
    GROUP BY 5, 1, 2, 3, 4) AS agg
GROUP BY 1, 2
ORDER BY 3 DESC, 5 ASC, 4 DESC;


-- Q4 

/* 
Analyze and present the impact of the calls performed by the call center on the collection
performance.
*/

-- For accouts that were called, what was their collection performance in March?

-- Collection performance comparison by accounts
WITH t1 AS (
    -- List of each accounts called in April 2019 and their collection in April
    SELECT 
        pd."Portfolio Derived Account Angaza ID" AS account_id,
        cc."April Collections Calls List Date Called Date" AS call_days_april,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        cc."April Collections Calls List Reachability" AS call_status,
        pd."Portfolio Derived Days From Last Payment" AS turnaround_time,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_month_of_call
    FROM portfolio_derived AS pd
    JOIN call_center AS cc
    ON pd."Portfolio Derived Account Angaza ID" = cc."April Collections Calls List Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-04'
        AND
        DATE_PART('Month', cc."April Collections Calls List Date Called Date"::DATE) = '04'
    GROUP BY 1,2,3,4,5
    ORDER BY 2 DESC, 1
),
t2 AS (
    -- List of each accounts called in April 2019 and their collection in March
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_previous_month
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-03'
    GROUP BY 1, 2
),
t3 AS (
    -- List of each accounts called in April 2019 and their collection in May
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_subsequent_month
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-05'
    GROUP BY 1, 2
)
SELECT 
    t1.account_id,
    t2.total_payment_in_previous_month AS total_payment_in_march_2019,
    t1.total_payment_in_month_of_call AS total_payment_in_april_2019,
    t3.total_payment_in_subsequent_month AS total_payment_in_may_2019
FROM t1
JOIN t2
ON t1.account_id = t2.account_id
JOIN t3
ON t1.account_id = t3.account_id;


-- Collection performance comparison by call status by total collection
WITH t1 AS (
    -- List of each accounts called in April 2019 and their collection in April
    SELECT 
        pd."Portfolio Derived Account Angaza ID" AS account_id,
        cc."April Collections Calls List Date Called Date" AS call_days_april,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        cc."April Collections Calls List Reachability" AS call_status,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_month_of_call
    FROM portfolio_derived AS pd
    JOIN call_center AS cc
    ON pd."Portfolio Derived Account Angaza ID" = cc."April Collections Calls List Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-04'
        AND
        DATE_PART('Month', cc."April Collections Calls List Date Called Date"::DATE) = '04'
    GROUP BY 1,2,3,4
    ORDER BY 2 DESC, 1
),
t2 AS (
    -- List of each accounts called in April 2019 and their collection in March
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_previous_month
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-03'
    GROUP BY 1, 2
),
t3 AS (
    -- List of each accounts called in April 2019 and their collection in May
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_subsequent_month
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-05'
    GROUP BY 1, 2
)
SELECT 
    t1.call_status,
    SUM(t2.total_payment_in_previous_month) AS march_2019_total_payment,
    SUM(t1.total_payment_in_month_of_call) AS april_2019_total_payment,
    SUM(t3.total_payment_in_subsequent_month) AS may_2019_total_payment
FROM t1
JOIN t2
ON t1.account_id = t2.account_id
JOIN t3
ON t1.account_id = t3.account_id
GROUP BY 1
ORDER BY 1 DESC;


-- Collection performance comparison by call status by avg total collection
WITH t1 AS (
    -- List of each accounts called in April 2019 and their collection in April
    SELECT 
        pd."Portfolio Derived Account Angaza ID" AS account_id,
        cc."April Collections Calls List Date Called Date" AS call_days_april,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        cc."April Collections Calls List Reachability" AS call_status,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_month_of_call
    FROM portfolio_derived AS pd
    JOIN call_center AS cc
    ON pd."Portfolio Derived Account Angaza ID" = cc."April Collections Calls List Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-04'
        AND
        DATE_PART('Month', cc."April Collections Calls List Date Called Date"::DATE) = '04'
    GROUP BY 1,2,3,4
    ORDER BY 2 DESC, 1
),
t2 AS (
    -- List of each accounts called in April 2019 and their collection in March
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_previous_month
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-03'
    GROUP BY 1, 2
),
t3 AS (
    -- List of each accounts called in April 2019 and their collection in May
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_subsequent_month
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-05'
    GROUP BY 1, 2
)
SELECT 
    t1.call_status,
    ROUND(AVG(t2.total_payment_in_previous_month)) AS march_2019_avg_total_payment,
    ROUND(AVG(t1.total_payment_in_month_of_call)) AS april_2019_avg_total_payment,
    ROUND(AVG(t3.total_payment_in_subsequent_month)) AS may_2019_avg_total_payment
FROM t1
JOIN t2
ON t1.account_id = t2.account_id
JOIN t3
ON t1.account_id = t3.account_id
GROUP BY 1
ORDER BY 1 DESC;


-- Collection performance comparison by call status by avg turnaround time
WITH t1 AS (
    -- List of each accounts called in April 2019 and their collection in April
    SELECT 
        pd."Portfolio Derived Account Angaza ID" AS account_id,
        cc."April Collections Calls List Date Called Date" AS call_days_april,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        cc."April Collections Calls List Reachability" AS call_status,
        ROUND(AVG(pd."Portfolio Derived Days From Last Payment")) AS turnaround_time
    FROM portfolio_derived AS pd
    JOIN call_center AS cc
    ON pd."Portfolio Derived Account Angaza ID" = cc."April Collections Calls List Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-04'
        AND
        DATE_PART('Month', cc."April Collections Calls List Date Called Date"::DATE) = '04'
    GROUP BY 1,2,3,4
    ORDER BY 2 DESC, 1
),
t2 AS (
    -- List of each accounts called in April 2019 and their collection in March
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        ROUND(AVG(pd."Portfolio Derived Days From Last Payment")) AS turnaround_time
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-03'
    GROUP BY 1, 2
),
t3 AS (
    -- List of each accounts called in April 2019 and their collection in May
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        ROUND(AVG(pd."Portfolio Derived Days From Last Payment")) AS turnaround_time
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-05'
    GROUP BY 1, 2
)
SELECT 
    t1.call_status,
    ROUND(AVG(t2.turnaround_time)) AS march_2019_avg_turnaround_time,
    ROUND(AVG(t1.turnaround_time)) AS april_2019_avg_turnaround_time,
    ROUND(AVG(t3.turnaround_time)) AS may_2019_avg_turnaround_time
FROM t1
JOIN t2
ON t1.account_id = t2.account_id
JOIN t3
ON t1.account_id = t3.account_id
GROUP BY 1;


-- Collection performance comparison by call status by avg turnaround time
WITH t1 AS (
    -- List of each accounts called in April 2019 and their collection in April
    SELECT 
        pd."Portfolio Derived Account Angaza ID" AS account_id,
        cc."April Collections Calls List Date Called Date" AS call_days_april,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        cc."April Collections Calls List Reachability" AS call_status,
        ROUND(AVG(pd."Portfolio Derived Days From Last Payment")) AS turnaround_time
    FROM portfolio_derived AS pd
    JOIN call_center AS cc
    ON pd."Portfolio Derived Account Angaza ID" = cc."April Collections Calls List Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-04'
        AND
        DATE_PART('Month', cc."April Collections Calls List Date Called Date"::DATE) = '04'
    GROUP BY 1,2,3,4
    ORDER BY 2 DESC, 1
),
t2 AS (
    -- List of each accounts called in April 2019 and their collection in March
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        ROUND(AVG(pd."Portfolio Derived Days From Last Payment")) AS turnaround_time
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-03'
    GROUP BY 1, 2
),
t3 AS (
    -- List of each accounts called in April 2019 and their collection in May
    SELECT 
        t1.account_id,
        DATE_TRUNC('Month', pd."Portfolio Derived Date Date"::DATE) AS snapshot_date,
        ROUND(AVG(pd."Portfolio Derived Days From Last Payment")) AS turnaround_time
    FROM t1
    JOIN portfolio_derived AS pd
    ON t1.account_id = pd."Portfolio Derived Account Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-05'
    GROUP BY 1, 2
)
SELECT 
    t1.call_status,
    ROUND(AVG(t2.turnaround_time)) AS march_2019_avg_turnaround_time,
    ROUND(AVG(t1.turnaround_time)) AS april_2019_avg_turnaround_time,
    ROUND(AVG(t3.turnaround_time)) AS may_2019_avg_turnaround_time
FROM t1
JOIN t2
ON t1.account_id = t2.account_id
JOIN t3
ON t1.account_id = t3.account_id
GROUP BY 1;


/*
We consider a call to be successful if a payment was made within X days of call.
Can you figure out a suitable x from the data? (Support your hypothesis with vizualization).
*/

-- Average days taken to make first payment, and total first payment by accounts within call categories
WITH t1 AS (
    -- List of each accounts called in April 2019 and their collection per day
    SELECT 
        pd."Portfolio Derived Account Angaza ID" AS account_id,
        cc."April Collections Calls List Reachability" AS call_status,
        cc."April Collections Calls List Date Called Date" AS date_of_call,
        pd."Portfolio Derived Date Date" AS snapshot_date,
        DATE_PART('day', pd."Portfolio Derived Date Date"::timestamp - cc."April Collections Calls List Date Called Date"::timestamp) AS days_from_call_date,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_month_of_call
    FROM portfolio_derived AS pd
    JOIN call_center AS cc
    ON pd."Portfolio Derived Account Angaza ID" = cc."April Collections Calls List Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-04'
        AND
        DATE_PART('Month', cc."April Collections Calls List Date Called Date"::DATE) = '04'
    GROUP BY 1,2,3,4,5
    ORDER BY 2 DESC, 1
),
t2 AS (
    -- List of the first payment date of accounts that made payment after call
    SELECT 
        t1.account_id,
        t1.call_status,
        t1.date_of_call,
        MIN(t1.snapshot_date) AS date_of_first_payment_after_call
    FROM t1
    WHERE t1.days_from_call_date >=0 AND t1.total_payment_in_month_of_call != 0
    GROUP BY 1,2,3
    ORDER BY 1, 4 DESC
),
t3 AS (
    -- List of the turnaround time and the total first payment by accounts that made payment after call
    SELECT 
        t2.*, t1.days_from_call_date, t1.total_payment_in_month_of_call
    FROM t2
    JOIN t1
    ON t2.account_id = t1.account_id
    WHERE t2.date_of_first_payment_after_call = t1.snapshot_date
)
-- The average days it took to make first payment, and the total payments made by accounts within call categories
SELECT
    t3.call_status,
    ROUND(AVG(t3.days_from_call_date)) AS avg_days_to_make_first_payment_from_call_date,
    SUM(t3.total_payment_in_month_of_call) AS total_first_payment_after_call
FROM t3
GROUP BY 1;


-- Average days taken to make first payment, and total first payment by accounts within call categories
WITH t1 AS (
    -- List of each accounts called in April 2019 and their collection per day
    SELECT 
        pd."Portfolio Derived Account Angaza ID" AS account_id,
        cc."April Collections Calls List Reachability" AS call_status,
        cc."April Collections Calls List Date Called Date" AS date_of_call,
        pd."Portfolio Derived Date Date" AS snapshot_date,
        DATE_PART('day', pd."Portfolio Derived Date Date"::timestamp - cc."April Collections Calls List Date Called Date"::timestamp) AS days_from_call_date,
        SUM(pd."Portfolio Derived Amount") AS total_payment_in_month_of_call
    FROM portfolio_derived AS pd
    JOIN call_center AS cc
    ON pd."Portfolio Derived Account Angaza ID" = cc."April Collections Calls List Angaza ID"
    WHERE 
        TO_CHAR(pd."Portfolio Derived Date Date"::DATE, 'YYYY-MM') = '2019-04'
        AND
        DATE_PART('Month', cc."April Collections Calls List Date Called Date"::DATE) = '04'
    GROUP BY 1,2,3,4,5
    ORDER BY 2 DESC, 1
),
t2 AS (
    -- List of the first payment date of accounts that made payment after call
    SELECT 
        t1.account_id,
        t1.call_status,
        t1.date_of_call,
        MIN(t1.snapshot_date) AS date_of_first_payment_after_call
    FROM t1
    WHERE t1.days_from_call_date >=0 AND t1.total_payment_in_month_of_call != 0
    GROUP BY 1,2,3
    ORDER BY 1, 4 DESC
)
-- List of the turnaround time and the total first payment by accounts that made payment after call
SELECT 
    t2.*, t1.days_from_call_date, t1.total_payment_in_month_of_call
FROM t2
JOIN t1
ON t2.account_id = t1.account_id
WHERE t2.date_of_first_payment_after_call = t1.snapshot_date;
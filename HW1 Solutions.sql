SELECT 
	*
FROM health
limit 10
;

-- 2.
SELECT
	COUNT(DISTINCT ID)
FROM health;

-- 3. Write a query to count the total number of patients for each sex.  Sort your output on this count from lowest to highest value.  

SELECT
	SEX
    ,COUNT(*) AS PATIENT_COUNT
FROM health
GROUP BY SEX
ORDER BY PATIENT_COUNT;

-- 4. Next, for each sex, calculate the average incidence of hypertension, vascular disease, and diabetes (in a single query).  
-- Exclude the one patient with ‘Unknown’ sex.  (Note:  there is no need for any difficult calculation here—take advantage of the fact that hypertension, vascular disease, 
-- and diabetes are defined as “dummy” variables).

SELECT
	SEX
    ,COUNT(*) AS PATIENT_COUNT
    ,AVG(HYPERTENSION)
    ,AVG(VASC_DISEASE)
    ,AVG(DIABETES)
FROM	health
WHERE SEX <> 'Unknown'
GROUP BY SEX;

SHOW COLUMNS
	FROM health;
    
SELECT 
	DISTINCT AGE
FROM health;

SELECT 10 + '90+';

-- For now, take advantage of this implicit type conversion and calculate the estimated average age for patients grouped by sex and hypertension.  
-- Be sure to ROUND the average ages to two decimal places (and search the internet if you need some help!).  Include the count of patients in each group as well.  
-- Only include patients that were alive when the data was collected.  Further, exclude the patient with ‘Unknown’ sex.  
-- Finally, only include groups that have at least 10,000 patients with diabetes.  Order your output by sex and then hypertension (both in ascending order).  
-- Are we necessarily underestimating or overestimating the average age of each group?

SELECT
	SEX
    ,HYPERTENSION
    ,COUNT(*) AS PATIENT_COUNT
    ,ROUND(AVG(AGE),2) AS AVG_AGE
FROM health
WHERE
	STATUS = 'Alive'
AND	SEX <> 'Unknown'

GROUP BY 
	SEX
    ,HYPERTENSION
HAVING 
	SUM(DIABETES) >= 10000
ORDER BY 
	SEX
    ,HYPERTENSION;
    
SELECT SEX, DIABETES, HYPERTENSION, MIN(AGE), MAX(AGE)
FROM health
GROUP BY 1,2,3;

SELECT COUNT(*)
FROM health
WHERE A1C IS NULL;

SELECT 
	visits_sched
    ,COUNT(*)
FROM health
GROUP BY visits_sched
ORDER BY COUNT(*) DESC
LIMIT 20;

SELECT COUNT(*)
FROM health
WHERE visits_sched = 'NULL';

SELECT COUNT(*)
FROM health
WHERE
	BMI IS NOT NULL
AND VISITS_SCHED <> 'NULL'
AND VISITS_MISS <> 0;

-- Write a query to count the total number of patients who have had at least 2 scheduled appointments and missed at least 75% of those appointments.  
-- The stakeholder wants the counts grouped by payor and ranked by the count in descending order.  
-- Only include patients who are currently alive. 

SELECT 
	PAYOR
    ,COUNT(ID) AS PATIENT_COUNT
FROM
	health
WHERE
	VISITS_SCHED >= 2
AND
	VISITS_MISS >= 0.75 * VISITS_SCHED
AND
	STATUS = 'Alive'
GROUP BY PAYOR
ORDER BY PATIENT_COUNT DESC;   

-- Oh no!  MariaDB just released an update and the aggregate function AVG() is buggy and not working properly (or at least let’s pretend that’s the situation for now). 
-- A stakeholder wants to investigate the percentage of people with diabetes in different “smoke” groups.
--  Specifically, she wants you to only consider patients who are currently alive and “smoke” groups that have at least 10,000 living patients.
--  For each of these “smoke” groups she wants you to calculate the percentage of patients that have diabetes.
--  (Remember, we’re assuming you cannot use the AVG() function at all in your final query.
--  But, feel free to use it while you’re developing your query to check your calculations.)
--  She also wants you to calculate a column that represents each “smoke” group’s percentage of the total number of records for only the “smoke” groups that are in your final output.
--  Put differently, if you have 3 “smoke” groups in your final output, this column contains each “smoke” groups count divided by the total count for only these 3 “smoke” groups combined.
--  As a result, the sum of the values in this last column will equal 1.
--  Your final output should have 4 columns:  “smoke” group, a count of the number of records in that “smoke” group, the percentage of patients that have diabetes for each “smoke” group,
-- and the each “smoke” group’s percentage of the total number of records for only the “smoke” groups that are in your final output.
--  Order your output by the count in descending order.
--  Remember, your final answer cannot utilize the AVG() aggregate function!
--  (HINT:  to generate the last column you will need to run some separate queries and generate a value which you can “hard-code” directly into your final query.
--  Typically we don’t like to do this but we don’t know enough yet to avoid it!)  		




SELECT
	SMOKE
    ,COUNT(ID) AS PATIENT_COUNT
    ,SUM(DIABETES)
    ,SUM(DIABETES)/COUNT(ID) AS AVG_DIABETES
    ,COUNT(ID) / (SELECT SUM(T.SMOKE_GROUPS) 
				  FROM ( SELECT COUNT(ID) AS SMOKE_GROUPS 
						 FROM health 
                         WHERE STATUS = 'Alive' 
                         GROUP BY SMOKE 
                         HAVING COUNT(ID) >= 10000 )T) AS SMOKE_GROUP_PERC
    
FROM
	health
WHERE
	STATUS = 'Alive'
GROUP BY SMOKE
HAVING
	COUNT(ID) >= 10000;
	
-- Let’s categorize patients as either “high_risk” or “low_risk” for severe illness from COVID-19.
--  We will define a patient as “high_risk” if they are at least 65 years old OR they have hypertension OR they have vascular disease OR they have diabetes OR they have a BMI value of at least 30.
-- Otherwise, a patient is “low_risk.” Call this categorization variable “risk_group.”
--  Write a query that counts the number of patients in each risk category and also counts the number people who are “current every day smokers” for each risk category (and call this second aggregate “current_smoke”).
--  Show “low_risk” patients first in your output.

SELECT
	CASE
		WHEN AGE >= 65 OR HYPERTENSION = 1 OR VASC_DISEASE = 1 OR DIABETES = 1 OR BMI >= 30
        THEN 'high_risk'
        ELSE 'low_risk'
	END AS risk_group
	,COUNT(ID) AS patient_count
    ,SUM(CASE
			WHEN SMOKE = 1 
            THEN 1 
		END) AS current_smoke
    
FROM health
GROUP BY 1
ORDER BY RISK_GROUP DESC;


-- Let’s briefly switch over to the “yelp” database.
--  For this question, you’ll want to focus on the “user” table.
--  Each row in the “user” table represents a unique user of yelp.com.
--  In this question you can assume that a value of NULL in the “elite” column indicates that a specific user (i.e. a “user_id”) never attained “elite status.”
--  Categorize users into two groups:  those that are never “elite” (call these users “no_elite”) versus those that are “elite” at least once (call these “yes_elite”).
-- You can name his grouping variable “elite_group.”  Write a query that, for each “elite_group,” calculates the average number of funny and useful responses per review.
--  (You should focus on the “funny,” “useful,” and “review_count” columns in your calculation.) Round your results to three decimal places. 

SELECT * FROM user LIMIT 10
;

SELECT
	CASE
		WHEN ELITE IS NULL THEN 'no_elite'
        ELSE 'yes_elite'
	END AS elite_group
    ,SUM(REVIEW_COUNT)
    ,SUM(FUNNY)
    ,SUM(USEFUL)
    ,ROUND(SUM(FUNNY)/SUM(REVIEW_COUNT),3) AS avg_funny_per_review
    ,ROUND(SUM(USEFUL)/SUM(REVIEW_COUNT),3) AS avg_useful_per_review
FROM
	user
GROUP BY 1;
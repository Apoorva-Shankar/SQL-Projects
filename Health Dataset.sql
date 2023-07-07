SELECT 
	*
FROM health
limit 10
;

SELECT
	COUNT(DISTINCT ID)
FROM health;

--  counting the total number of patients for each sex. 

SELECT
	SEX
    ,COUNT(*) AS PATIENT_COUNT
FROM health
GROUP BY SEX
ORDER BY PATIENT_COUNT;

--  calculating the average incidence of hypertension, vascular disease, and diabetes.  

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

-- calculating the estimated average age for patients grouped by sex and hypertension. 

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

-- counting the total number of patients who have had at least 2 scheduled appointments and missed at least 75% of those appointments. 

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
	
-- categorizing patients as either “high_risk” or “low_risk” for severe illness from COVID-19.
--  defining a patient as “high_risk” if they are at least 65 years old OR they have hypertension OR they have vascular disease OR they have diabetes OR they have a BMI value of at least 30.
-- Otherwise, a patient is “low_risk.”

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


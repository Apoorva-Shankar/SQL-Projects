-- ASSIGNMENT #2
-- Q1
/* Continuing with the “sanford” database, categorize all patients with “Alive” status into the five blood pressure categories defined here:  
https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings.  
Categorize each patient into the HIGHEST group in which he/she falls.  
For example, if a patient has systolic blood pressure of 150 mm Hg and diastolic blood pressure of 85 mm Hg, we want to categorize that patient as “Hypertension Stage 2” NOT “Hypertension Stage 1.”  
Be sure to exclude any records with a negative value for either blood pressure reading.  
Also, be sure to include an ELSE NULL at the appropriate spot in your query.  
Your output should include 
	the blood pressure categories (call this “BP_Group”), 
    the count of patients in each category (call this “Total_Patients”), 
    and the average BMI of patients in each blood pressure category, 
rounded to two decimal places (call this “Avg_BMI”). 
 Order your output from highest to lowest “Avg_BMI.”  
 (NOTE:  remember that the CASE statement reads from top to bottom and each record is categorized into the FIRST condition that it satisfies.)
*/

SELECT
	CASE 
		WHEN SBP < 120 AND DBP < 80
        THEN 'Normal'
        WHEN SBP BETWEEN 120 AND 129 AND DBP < 80
        THEN 'Elevated'
        WHEN SBP > 180 OR DBP > 120
        THEN 'Hypertensive Crisis'
        WHEN SBP >= 140 OR DBP >= 90
        THEN 'Hypertension Stage 2'
        WHEN SBP >= 130 OR DBP BETWEEN 80 AND 89
        THEN 'Hypertension Stage 1'
        ELSE NULL
	END AS BP_Group
    ,COUNT(ID) AS Total_Patients
    ,ROUND(AVG(BMI),2) AS Avg_BMI
FROM
	sanford.health
WHERE
	STATUS = 'Alive'
 AND SBP >= 0
 AND DBP >= 0 
GROUP BY
	BP_GROUP
ORDER BY
	AVG_BMI DESC;

-- Q 2    
/*
Using the “business” table, what percentage of all “Pizza” places (i.e. the string “Pizza” exists in the categories column) have 3 or fewer total categories? 
(You can assume all potential categories in the categories column are separated by the string ‘, ‘.)
*/

SELECT * 
FROM business 
LIMIT 10;

SELECT
	COUNT(*)/(
				SELECT 
					COUNT(*) 
				FROM 
					business 
				WHERE UPPER(CATEGORIES) LIKE '%PIZZA%'
			)
    
FROM
	business
WHERE
	UPPER(CATEGORIES) LIKE '%PIZZA%'
AND
	LENGTH(REPLACE(CATEGORIES, ',', 'AA')) - LENGTH(CATEGORIES) + 1 <= 3;

-- Q3
/*
Using the “business” table, 
how many different (i.e. not identical) values exist in the categories column that contain the strings “Pizza”, “Restaurants”, and “Italian”. 
Your final result set should be a single number.
*/

SELECT
	COUNT(DISTINCT CATEGORIES) AS UNIQUE_CATEGORIES
FROM
	business
WHERE
	UPPER(CATEGORIES) LIKE '%PIZZA%'
    AND UPPER(CATEGORIES) LIKE '%RESTAURANTS%'
    AND UPPER(CATEGORIES) LIKE '%ITALIAN%';


-- Q4
/*
Using the “business” table, group records using the categories column and only include categories that contain the strings “Pizza”, “Restaurants”, and “Italian”. 
Calculate the average number of reviews per business in each group. 
Only keep groups that have an average number of reviews per business greater than the average number of reviews per business across all businesses. 
How many groups satisfy this criteria? Your final result set should be a single number.
*/    

SELECT
	SUM(CATEGORY_COUNT) AS CATEGORY_COUNT
FROM
(
	SELECT
		CATEGORIES
		,COUNT(DISTINCT CATEGORIES) AS CATEGORY_COUNT
		,AVG(REVIEW_COUNT)
		,76.3768 AS AVG_REVIEWS_ALL_BIZ
	FROM
		business
	WHERE
		UPPER(CATEGORIES) LIKE '%PIZZA%'
		AND UPPER(CATEGORIES) LIKE '%RESTAURANTS%'
		AND UPPER(CATEGORIES) LIKE '%ITALIAN%'
	GROUP BY CATEGORIES
	HAVING AVG(REVIEW_COUNT) > (SELECT
									AVG(REVIEW_COUNT)
								FROM
									business
								)
) A;

-- Q5
/*
Again using “yelp,” suppose you want to further drill down into your “elite_group” groups (from HW#1) by generating subcategories based on how long a user has been yelping.  
Specifically, suppose we want to categorize all users into three “buckets”
	—those that have been yelping for 1000 days or less (call them “group1”), 
    those that have been yelping for more than 1000 days but less than 3000 days (call them “group2”), 
    and those that have been yelping for 3000 days or more (call them “group3”).  
Each user’s yelping “tenure” should be calculated relative to 7/29/22. 
Provide a count of the number of users that fall into each combination of “elite_group” and “tenure.” 
Order your output by “tenure” and then “elite_group” (both ascending).
*/

SELECT
	CASE
		WHEN ELITE IS NULL THEN 'no_elite'
		ELSE 'yes_elite'
		END AS elite_group
	,CASE
		WHEN datediff(DATE('2022-07-29'),YELPING_SINCE)  <= 1000
        THEN 'group1'
        WHEN datediff(DATE('2022-07-29'),YELPING_SINCE)  BETWEEN 1000 AND 2999
        THEN 'group2'
        WHEN datediff(DATE('2022-07-29'),YELPING_SINCE)  >= 3000
        THEN 'group3'
	END AS tenure
    ,COUNT(*)

FROM
	yelp.user
GROUP BY 
	ELITE_GROUP
    ,TENURE
ORDER BY
	TENURE
    ,ELITE_GROUP
;
    
-- Q6
/*
Using the “name” column in the “business” table of the “yelp” database, 
count the number of restaurants that have exactly two words in their name where the second word 
is longer (i.e. has more characters) than the first word.
*/
SELECT
	COUNT(DISTINCT NAME) AS COUNT_OF_RES
    ,count(*)
FROM
	(
    SELECT
		NAME
		,LENGTH(NAME)
		,REPLACE(TRIM(NAME), ' ', '~~' )
		,POSITION('~~' IN REPLACE(TRIM(NAME), ' ', '~~' )) - 1 AS WORD_LEN1
		,CHAR_LENGTH(TRIM(NAME)) - POSITION('~~' IN REPLACE(TRIM(NAME), ' ', '~~' )) AS WORD_LEN2
		,LENGTH(REPLACE(TRIM(NAME), ' ', '~~' )) - LENGTH(NAME)
	FROM
		business
	WHERE
		LENGTH(NAME) - LENGTH(REPLACE(TRIM(NAME), ' ', '' )) = 1
	GROUP BY 1
    ) A
WHERE
	WORD_LEN2 > WORD_LEN1;
    

    SELECT
		COUNT(*)
	FROM
		business
	WHERE
    
		LENGTH(TRIM(NAME)) - LENGTH(REPLACE(TRIM(NAME), ' ', '' )) = 1
	AND 
	
	CHAR_LENGTH(TRIM(NAME)) - POSITION('~~' IN REPLACE(TRIM(NAME), ' ', '~~' ))>POSITION('~~' IN REPLACE(TRIM(NAME), ' ', '~~' )) - 1 ;



-- Q7
/*
Excluding all flights that were cancelled or diverted, what are the average departure and arrival delays for all flights (in minutes)?
*/
SELECT
	AVG(DEPDELAY)
    ,AVG(ARRDELAY)
FROM
	ontime
WHERE
	CANCELLED = 0
AND
	DIVERTED = 0
;

SELECT DISTINCT DEPTIME, CRSDEPTIME, DEPDELAY, DepTime - CRSDepTime from ontime ORDER BY DEPTIME DESC, CRSDEPTIME DESC LIMIT 100;

-- Q8
SELECT	AVG(DepTime - CRSDepTime)
FROM		ontime
WHERE	Cancelled = 0 AND 
Diverted = 0;

-- Q9
/*
We may not be able to resolve all of the issues from the previous problem but we can certainly resolve one of them.  
First, check out the data type of the “DepTime” and “CRSDepTime” fields.  
Figure out how to transform both of these fields to times.  
There will be multiple ways of performing this task.  
Write a query that includes the two original departure time fields along with these two new generated variables, “NewDT” and “NewCRSDT,” and shows ten values of each.
*/
show columns from ontime  ;
SELECT
	DEPTIME
    ,CRSDEPTIME
    ,TIME(DEPTIME * 100)
    ,TIME(CRSDEPTIME*100)
FROM
	ontime
LIMIT 10;

SELECT DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where
table_schema = 'airline_ontime' and tablename = 'ontime' ;

-- Q10
/*
Great!  Now we’ve made some progress!  
Next, we’ll use our newly created variables to see if we can calculate a departure delay which is consistent with the value of “DepDelay.”  
So, let’s focus on some “well-behaved” records.  
Only include flights that were not cancelled and not diverted.  
Further, only include records with a scheduled departure time between 8:00 AM and 4:00 PM (inclusive). 
Lastly, only include records where the absolute value of “DepDelay” is less than or equal to 4 hours (240 minutes).  
Given these filters, I want you to calculate the average departure delay using your new calculated times and compare it with the average departure delay simply using “DepDelay” 
(both should be measured in minutes).  So, your result set should consist of one row and two columns.  
And, if you’ve written the query correctly, the two values should be the same!  
(NOTE:  in the average departure delay calculation where you are using your two new calculated times from the previous question, you CANNOT explicitly use the “DepDelay” field.)
*/
SELECT

    AVG(DEPDELAY)
    ,AVG(TIME_TO_SEC(TIMEDIFF(TIME(DEPTIME),TIME(CRSDEPTIME))))
    
FROM
	ontime
WHERE
	CANCELLED = 0
AND 
	DIVERTED = 0
AND
	CRSDEPTIME BETWEEN 800 AND 1600 
AND
	ABS(DEPDELAY) <= 240 
;

-- Q11

/*
What is the total distance traveled of all non-cancelled, non-diverted flights that departed from RDU on July 20, 2007? 
*/

SELECT
	SUM(DISTANCE)
FROM
	ontime
WHERE
	CANCELLED = 0
AND
	DIVERTED = 0
AND
	ORIGIN = 'RDU'
AND
	CONCAT(DAYOFMONTH,'+',MONTH,'+',YEAR) = '20+7+2007';
    
-- Q12
/*
First, write a query to calculate the total number of direct flights between SFO airport in San Francisco and LAX airport in Los Angeles.  
Since you want to maximize the amount of time that you spend with your mom (while trying to avoid taking too many vacation days), these flights must satisfy certain conditions.  
All flights from SFO to LAX must be scheduled to leave after 5 PM and before 8 PM on Fridays and all flights from LAX to SFO must be scheduled to leave after 5 PM and before 8 PM on Sundays.  
Exclude all cancelled and diverted flights.  How should you incorporate this value into your second query
*/


SELECT 
	COUNT(*)
FROM
	ontime
WHERE
	CANCELLED = 0
AND
	DIVERTED = 0
AND
	((ORIGIN = 'SFO' AND DEST = 'LAX' AND CRSDEPTIME > 1700 AND CRSDEPTIME < 2000 AND DAYOFWEEK = 5)
	OR
	(ORIGIN = 'LAX' AND DEST = 'SFO' AND CRSDEPTIME > 1700 AND CRSDEPTIME < 2000 AND DAYOFWEEK = 7))

;

/*
Second, calculate your “score” for each unique carrier (assuming “unique carrier” is synonymous with “airline”).  
Your score will be the sum of two separate percentages.  
First, the unique carrier’s percentage of all direct flights between the two airports (satisfying all of the same conditions as in your first query). 
Second, the unique carrier’s percentage of its own flights that do NOT have an arrival delay of at least 60 minutes.  
(For instance, if a carrier has 10 flight records and 3 of them have an arrival delay of at least 60 minutes, the percentage you want here is 0.70.)  
Exclude cancelled and diverted flights.  
Just to be clear with you here—the conditions in your WHERE clause in this query should be identical to those used in the WHERE clause in your first query.  
You will likely want to try to use a CASE statement inside an aggregate function.  Order your output by your score in descending order.
*/
SELECT 
	UniqueCarrier
    ,ROUND((UNIQUE_CARRIER_PERC+PERC_OF_OWN_FLIGHTS) * 100,2) AS SCORE
FROM
(
SELECT
	UNIQUECARRIER
	,COUNT(*)/ ( SELECT 
					COUNT(*)
				FROM
					ontime
				WHERE
					CANCELLED = 0
				AND
					DIVERTED = 0
				AND
					((ORIGIN = 'SFO' AND DEST = 'LAX' AND CRSDEPTIME > 1700 AND CRSDEPTIME < 2000 AND DAYOFWEEK = 5)
					OR
					(ORIGIN = 'LAX' AND DEST = 'SFO' AND CRSDEPTIME > 1700 AND CRSDEPTIME < 2000 AND DAYOFWEEK = 7))
				) AS UNIQUE_CARRIER_PERC
			,SUM(
					CASE
						WHEN ARRDELAY < 60
                        THEN 1
					END
				)/COUNT(*) AS PERC_OF_OWN_FLIGHTS
                        
FROM
	ontime
	
WHERE
	CANCELLED = 0
AND
	DIVERTED = 0
AND
	((ORIGIN = 'SFO' AND DEST = 'LAX' AND CRSDEPTIME > 1700 AND CRSDEPTIME < 2000 AND DAYOFWEEK = 5)
	OR
	(ORIGIN = 'LAX' AND DEST = 'SFO' AND CRSDEPTIME > 1700 AND CRSDEPTIME < 2000 AND DAYOFWEEK = 7))

GROUP BY UNIQUECARRIER
) A

ORDER BY SCORE DESC;

-- Q13
/*
 What are the ten calendar weeks of 2007 with the greatest number of cancelled flight records? 
 Assume that a week starts on Sunday, the “week number” can take on values from 1 to 53, and Week 1 is the 1st week with a Sunday in 2007.  
 Your output should contain the aforementioned “week number,” the start date corresponding to that “week number,” 
 the end date corresponding to that “week number,” and the total number of cancelled flight records for that week.  
 To give you a hint, the first line in your output should be:

	6	2007-02-11	2007-02-17	11351

	You can answer this question with a single query and you CANNOT “hard code” the date when each week number starts—you must use date functions.
*/

SELECT
	WEEK(DATE(CONCAT(YEAR,'-',MONTH,'-',DAYOFMONTH)),2) AS WEEK_NUMBER
    ,MIN(DATE(CONCAT(YEAR,'-',MONTH,'-',DAYOFMONTH))) AS START_OF_WEEK
    ,MAX(DATE(CONCAT(YEAR,'-',MONTH,'-',DAYOFMONTH))) AS END_OF_WEEK
    ,COUNT(*) AS CANCELLED_FLIGHT_COUNT
FROM 
	ontime
 WHERE
	CANCELLED = 1
GROUP BY WEEK_NUMBER
ORDER BY COUNT(*) DESC
LIMIT 10;

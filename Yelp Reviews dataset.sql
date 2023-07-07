

-- Pizza Restaurants

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


SELECT
	COUNT(DISTINCT CATEGORIES) AS UNIQUE_CATEGORIES
FROM
	business
WHERE
	UPPER(CATEGORIES) LIKE '%PIZZA%'
    AND UPPER(CATEGORIES) LIKE '%RESTAURANTS%'
    AND UPPER(CATEGORIES) LIKE '%ITALIAN%';


-- Italian Pizza restaurants 

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

-- “elite_group” groups by generating subcategories based on how long a user has been yelping calculated relative to 7/29/22.  

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
    
-- Restaurants with 2 words in their names
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


/*
Using the “yelp” database, let’s examine some data on recent reviews.  
Focus on all reviews in the database on or after October 1, 2019.  
What percentage of restaurants that are open (is_open = 1) have at least one review since October 1, 2019? 
*/

WITH RECENTLY_REVIEWD AS
(
SELECT 
	BUSINESS_ID
    ,COUNT(*) 
FROM review 
GROUP BY BUSINESS_ID
HAVING MAX(DATE) >= DATE('2019-10-01')
)

SELECT 
	CASE
		WHEN RECENTLY_REVIEWD.business_id IS NOT NULL
        THEN 'Recently Reviewed Restaurant'
        ELSE 'Not Recently Reviewed'
	END AS REVIEW_GROUP
    ,COUNT(DISTINCT business.BUSINESS_ID)
    ,(COUNT(distinct business.business_id)/
    (SELECT COUNT(distinct business.business_id) 
    FROM review 
    LEFT JOIN
    business
    ON
	business.business_id = review.business_id
    WHERE IS_OPEN = 1)) * 100 AS PERCENTAGE
FROM
	business
INNER JOIN
	review
ON 
	business.business_id = review.business_id
LEFT JOIN
	RECENTLY_REVIEWD
ON
	business.business_id = RECENTLY_REVIEWD.business_id
WHERE
	IS_OPEN = 1
GROUP BY REVIEW_GROUP;



/*
Consider all of the users in our “yelp” database that have made at least 10 reviews. 
For all of these users, what is the average number of time (in days) between their 1st and 10th reviews?
*/

WITH USERS AS
(
SELECT 
	 R.USER_ID
     ,R.DATE
     ,RANK() OVER (PARTITION BY R.USER_ID ORDER BY R.DATE) AS REVIEW_ORDER 
     ,COUNT(*) OVER (PARTITION BY R.USER_ID) AS TOTAL_REVIEWS
FROM
	review R
GROUP BY 1,2
)    
,REVIEW1 AS
(
SELECT
	USER_ID
    ,DATE AS FIRST_REVIEW
FROM
	USERS
WHERE 
	TOTAL_REVIEWS >= 10  
AND
	REVIEW_ORDER = 1
GROUP BY 1,2
)

,REVIEW10 AS
(
SELECT
	USER_ID
    ,DATE AS TENTH_REVIEW
FROM
	USERS
WHERE 
	TOTAL_REVIEWS >= 10  
AND
	REVIEW_ORDER = 10
GROUP BY 1,2
)

,FINAL AS
(
SELECT 
	REVIEW1.USER_ID
    ,DATEDIFF(TENTH_REVIEW,FIRST_REVIEW) AS TIME_DIFFERENCE
FROM
	REVIEW1
LEFT JOIN
    REVIEW10
ON 
	REVIEW1.USER_ID = REVIEW10.USER_ID
)
SELECT AVG(TIME_DIFFERENCE) FROM FINAL;
    
 
 /*
 Yikes!  That’s a pretty long time!  Let’s dig a little deeper.  
 Consider the same set of users from the previous question.  
 But now, splitting them into two different groups:  
	those that gave a “high” rating (i.e. 4 or 5 stars) on their first review 
    versus those that gave a “low” rating on their first review (i.e. less than 4 stars).  

*/

WITH USERS AS
(
SELECT 
	 R.USER_ID
     ,R.DATE
     ,R.STARS
     ,RANK() OVER (PARTITION BY R.USER_ID ORDER BY R.DATE) AS REVIEW_ORDER 
     ,COUNT(*) OVER (PARTITION BY R.USER_ID) AS TOTAL_REVIEWS
FROM
	review R
GROUP BY 1,2,3

)    

,REVIEW1_10 AS
(
SELECT
	USER_ID
    ,STARS
    ,REVIEW_ORDER
    ,CASE 
		WHEN REVIEW_ORDER = 1 AND STARS >= 4
        THEN 'HIGH'
        ELSE 'LOW'
	END AS REVIEW_GROUP
    ,DATE
    ,LEAD(DATE) OVER (PARTITION BY USER_ID ORDER BY DATE) AS CONS_REVIEW
FROM
	USERS
WHERE 
	TOTAL_REVIEWS >= 10  
AND
	REVIEW_ORDER <= 10
GROUP BY 1,2,3,4,5
)
,GROUPS AS
(
SELECT 
,DATE_DIFF AS
(
SELECT 
	REVIEW_ORDER
    ,REVIEW_GROUP
    ,AVG(DATEDIFF(CONS_REVIEW,DATE)) AS TIME_DIFFERENCE
FROM
	REVIEW1_10
GROUP BY 1,2
)
SELECT * FROM DATE_DIFF;
SELECT
	L.REVIEW_ORDER AS ReviewNum
    ,L.TIME_DIFFERENCE AS AvgTimeTilNextLow
    ,H.TIME_DIFFERENCE AS AvgTimeTilNextHigh
FROM
	DATE_DIFF L
INNER JOIN
	DATE_DIFF H
ON
	L.REVIEW_ORDER = H.REVIEW_ORDER
AND
	L.REVIEW_GROUP = 'LOW'
AND
	H.REVIEW_GROUP = 'HIGH'
;


WITH USERS AS
(
SELECT 
	 R.USER_ID
     ,R.DATE
     ,STARS
     ,RANK() OVER (PARTITION BY R.USER_ID ORDER BY R.DATE) AS REVIEW_ORDER 
     ,COUNT(*) OVER (PARTITION BY R.USER_ID) AS TOTAL_REVIEWS
FROM
	review R
GROUP BY 1,2,3
)  

,REVIEW_GROUPS AS
(
SELECT
	USER_ID
    ,CASE
		WHEN STARS >= 4
        THEN 'HIGH'
        ELSE 'LOW'
	END AS REVIEW_GROUP
FROM
	USERS
WHERE
	REVIEW_ORDER = 1
)

,DATE_DIFF AS
(
SELECT
	U.USER_ID
    ,U.REVIEW_ORDER
    ,U.DATE
    ,LEAD(U.DATE) OVER (PARTITION BY U.USER_ID ORDER BY U.DATE) AS CONS_DATE
    ,REVIEW_GROUP
FROM
	USERS U
LEFT JOIN
	REVIEW_GROUPS
ON 
	U.USER_ID = REVIEW_GROUPS.USER_ID
WHERE
	TOTAL_REVIEWS >= 10
AND
	U.REVIEW_ORDER <= 10

)

,LOW_REVIEWS AS
(
SELECT 
	REVIEW_GROUP
    ,REVIEW_ORDER
    ,AVG(DATEDIFF(CONS_DATE,DATE)) AS AvgTimeTilNextLow
FROM
	DATE_DIFF
WHERE
	REVIEW_GROUP = 'LOW'
GROUP BY 1,2
)

,HIGH_REVIEWS AS
(
SELECT 
	REVIEW_GROUP
    ,REVIEW_ORDER
    ,AVG(DATEDIFF(CONS_DATE,DATE)) AS AvgTimeTilNextHigh
FROM
	DATE_DIFF
WHERE
	REVIEW_GROUP = 'HIGH'
GROUP BY 1,2
)

SELECT
	L.REVIEW_ORDER
    ,L.AvgTimeTilNextLow
    ,H.AvgTimeTilNextHigh
FROM
	LOW_REVIEWS L
INNER JOIN
	HIGH_REVIEWS H
ON
	L.REVIEW_ORDER = H.REVIEW_ORDER
WHERE
	L.REVIEW_ORDER <= 9
;

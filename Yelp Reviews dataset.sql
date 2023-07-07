

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

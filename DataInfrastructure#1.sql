SELECT    COUNT(*)
FROM      Reviews;

-- UNDERSTANDING SELECT STATEMENT
SELECT 
    ReviewID, Title, Rating, RateDate, PROFILE
FROM
    Reviews;
    

-- SELECTING ALL FIELDS    
SELECT
	COUNT(*)
FROM
	Reviews;
 
-- HANDLING NULL VALUES
SELECT
	COUNT(Genre)
FROM
	Reviews;
-- TABLE WITH NULLS IN EVERY RECORD DOESNT EXIT
-- ROW BY DEFINITION SHOULD HAVE ATLEAST 1 NON NULL VALUE
-- IS NULL AND IS NOT NULL FUNCTIONS

-- SELECTING DISTINCT VALUE IN A COLUMN
SELECT
	COUNT(DISTINCT GENRE) AS DISTINCT_VALUES
FROM
	Reviews;
    
-- WHERE CLAUSE
SELECT
	*
FROM
	Reviews
WHERE
	RATING = 4;
    
SELECT
	*
FROM
	Reviews
WHERE
	RATING IS NOT NULL;
    
-- GROUP BY STATEMENT
SELECT
	TITLE
	,PROFILE
    ,COUNT(*) AS PROFILE_COUNT
FROM
	Reviews
GROUP BY 
	TITLE
    ,PROFILE;
-- LIST OF FIELDS IN GROUP BY CLASE MUST BE IDENTICAL TO LIST OF FIELDS IN SELECT STATEMENT LESS AGGREGATES
-- GENERATES MEANINGLESS AND MISLEADING RESULTS IF THE COLUMNS IN SELECT DONT REFLECT IN GROUP STATEMENT (IN MYSQL AND MARIADB)

SELECT
	PROFILE
    ,TYPE
    ,COUNT(*)
FROM
	Reviews
GROUP BY
	PROFILE
    ,TYPE;
    
SELECT
	GENRE
    ,COUNT(*)
    ,COUNT(GENRE)
    ,SUM(RATING)
    ,MAX(RATING)
    ,MIN(RATING)
FROM
	Reviews
GROUP BY
	GENRE;

-- WHEN GROUP BY 
SELECT
	DISTINCT GENRE
    ,COUNT(*)
FROM
	Reviews;
    
-- HAVING CLAUSE
SELECT
	PROFILE
    ,AVG(RATING)
FROM
	Reviews
GROUP BY
	PROFILE
HAVING 
	AVG(RATING) >= 4;

SELECT
	PROFILE
    ,MIN(RATEDATE)
    ,AVG(RATING)
FROM
	Reviews
GROUP BY
	PROFILE
HAVING
	MAX(RateDate) >= '2016-07-01';
    
-- ORDER BY & LIMIT
-- FORMATS THE ORDER OF THE RESULT

    
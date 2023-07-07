SELECT * FROM Reviews;

SELECT PROFILE,

SELECT   *
FROM	 Reviews
WHERE	 Rating < 4 OR
		 Profile = 'Dad'
         AND Title NOT LIKE '_a%';
         
SELECT   Type, 
         Genre,
         COUNT(NewRat)
FROM     (
         SELECT   *,
                  CASE WHEN Title LIKE 'Fuller%' THEN NULL
                  ELSE Rating
                  END AS NewRat
         FROM     Reviews
         ) AS temp
WHERE    Title IN (
                  SELECT  Title 
                  FROM    Reviews 
                  WHERE   Title LIKE 'F%'
                  )
GROUP BY Type,
         Genre;
 
SELECT   *, 
         DAYNAME(RateDate) AS '??' 
FROM     Reviews
 
WHERE    DAYNAME(RateDate) LIKE 'S%';

SELECT
	UNIQUECARRIER
    ,AVG(TOTAL_DIST)
FROM
(
SELECT
    TAILNUM
    ,UNIQUECARRIER
    ,DATE(CONCAT(YEAR,'-',MONTH,'-',DAYOFMONTH)) AS FLIGHT_DATE
    ,SUM(DISTANCE) AS TOTAL_DIST
    
FROM
    ontime
WHERE 
    CANCELLED = 0
AND
    DIVERTED = 0
    
AND UPPER(TAILNUM) LIKE 'N%'
GROUP BY 1,2,3
) A
INNER JOIN
(SELECT
    TAILNUM
    ,DATE(CONCAT(YEAR,'-',MONTH,'-',DAYOFMONTH)) AS FLIGHT_DATE
    
FROM
    ontime
WHERE 
    CANCELLED = 0
AND
    DIVERTED = 0
    
AND UPPER(TAILNUM) LIKE 'N%'
GROUP BY 1,2
HAVING COUNT(DISTINCT UNIQUECARRIER) = 1  
) B

ON A.TAILNUM = B.TAILNUM
AND A.FLIGHT_DATE = B.FLIGHT_DATE
GROUP BY UNIQUECARRIER;

/*In each season of The Simpsons, which non-main character (i.e. not Homer, Marge, Bart, or Lisa) says the most words? 
Order output from highest number of words to lowest number of words.
*/

SELECT * FROM simpsons.characters limit 10;
select * from episodes;
SELECT * from locations limit 10;
select * from script_lines LIMIT 100;

SELECT 
	SEASON
    ,C.NAME AS CHARACTER_NAME
    ,SUM(WORD_COUNT)
FROM
	script_lines S
INNER JOIN
	characters C
ON 
	UPPER(S.RAW_CHARACTER_TEXT) = UPPER(C.NAME)
INNER JOIN
	episodes E
ON
	E.ID = S.EPISODE_ID
WHERE
	UPPER(C.NAME) NOT IN ('HOMER SIMPSON','MARGE SIMPSON','BART SIMPSON','LISA SIMPSON')
GROUP BY
	1,2
ORDER BY SUM(WORD_COUNT) DESC
LIMIT 1;


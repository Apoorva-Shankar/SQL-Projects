#Q1

WITH WINNINGS AS
(
SELECT 
	DATE
    ,NAME
    ,SUM(PRICE) AS WINNINGS
    ,MAX(SUM(PRICE)) OVER (PARTITION BY DATE) AS MAX_WINNINGS
FROM
	five_ep
WHERE 
	WIN = 1
GROUP BY 
	DATE
    ,NAME
)
SELECT
	DATE
    ,NAME
    ,WINNINGS
FROM
	WINNINGS
WHERE
	WINNINGS = MAX_WINNINGS
ORDER BY
	DATE;
    
#Q2
SELECT  MAX(MAX_FIRST_SPIN)
FROM
(
SELECT
	NAME
    ,DATE
    ,SUM(WINNINGS)
    ,MAX(CASE 
			WHEN SPINNUM = 1 THEN WINNINGS
		END) AS MAX_FIRST_SPIN
FROM
(
SELECT 
	SPINNUM
    ,NAME
    ,DATE
    ,SUM(EVENTAMOUNT) AS WINNINGS
FROM
	five_ep
WHERE
	EVENTTYPE = 'Big Wheel'
GROUP BY 1,2,3
) T
GROUP BY NAME,DATE
HAVING SUM(WINNINGS) <= 1 AND SUM(SPINNUM) = 3
) A;
    
#Q3

WITH BIDS AS
(
SELECT
	DATE
    ,EVENTTYPECOUNTER
    ,MAX(CASE 
		WHEN EVENTORDER = 4
        THEN WIN
	END) AS 4TH_WIN
    ,MAX(CASE
		WHEN EVENTORDER < 4
        THEN EVENTAMOUNT
	END) AS MAX_BID
    ,SUM(CASE
		WHEN EVENTORDER = 4
        THEN EVENTAMOUNT
	END) AS 4TH_BID
    
FROM
	five_ep
WHERE
	EVENTTYPE = 'Bidders Row'
GROUP BY 1,2
)

SELECT 
	CASE
		WHEN 4TH_WIN = 1 THEN 'bidder4_wins'
        ELSE 'bidder4_loses'
	END AS outcome_group
    ,COUNT(*) AS n_times
	,(COUNT(CASE
				WHEN 4TH_WIN = 1 THEN 1
                ELSE 0
		END)/SUM(COUNT(*)) OVER())*100 AS percentages
        
FROM
	BIDS
WHERE
	4TH_BID - MAX_BID = 1
GROUP BY 1;

#Q4
/*
How often do bidders make less-accurate bids on “Bidders Row” as the show progresses? 
Specifically, focus on all contestants that make at least two bids on “Bidders Row” during a show. 
You can define a bid’s “accuracy” as the absolute value of the difference between the bid and the actual value of prize. 
We want to find all contestants who are making incrementally “less accurate” bids for each bid they make on “Bidders Row.” 
If a contestant is “equally accurate” (i.e. the absolute value of the difference between the bid and the prize price is the same on consecutive bids) they should still be included here. 
Provide a count of the number of contestants who are incrementally “less accurate” for ALL of their bids, the average number of bids that they make, 
and the percentage of contestants in this set who actually win on their last bid. 
Just to be clear, your output should be a single row with three columns (one for each of the values we want to calculate).
*/

WITH BIDS AS
(
SELECT DATE,NAME, COUNT(*) AS TOTAL_BIDS
FROM 	five_ep
WHERE EVENTTYPE = 'Bidders Row'
GROUP BY 1,2
)

,PARTICIPANTS AS
(
SELECT 
	DATE
    ,NAME
   -- ,EVENTORDER
    ,EVENTTYPECOUNTER
    -- ,TOTAL_BIDS
    ,CASE WHEN EVENTTYPECOUNTER = MAX(EVENTTYPECOUNTER) OVER (PARTITION BY DATE,NAME) 
		  THEN WIN 
          END AS LAST_BID_WIN
    ,SUM(EVENTAMOUNT) AS TOTAL_WINNINGS
    ,SUM(PRICE)
    ,ROUND(ABS(SUM(EVENTAMOUNT) - SUM(PRICE)),0) AS ACCURACY
    -- ,SUM(TOTAL_BIDS) AS TOTAL_BIDS
    ,COUNT(EVENTTYPECOUNTER) OVER (PARTITION BY DATE,NAME) AS COUNT_BIDS
    
FROM  five_ep
WHERE EVENTTYPE = 'Bidders Row'
GROUP BY 1,2,3
)

,RANKING AS
(
SELECT 
	P.DATE
    ,P.NAME
    ,P.EVENTTYPECOUNTER
    ,P.ACCURACY
   -- ,P.TOTAL_BIDS AS COUNT_BIDS_
    ,LAST_BID_WIN
    ,RANK() OVER (PARTITION BY P.DATE, P.NAME ORDER BY P.ACCURACY) AS ACCURACY_RANKING
    ,RANK() OVER (PARTITION BY P.DATE, P.NAME ORDER BY P.EVENTTYPECOUNTER) AS BID_RANKING

FROM PARTICIPANTS P

WHERE COUNT_BIDS >= 2
ORDER BY 
	DATE
    ,NAME
    ,EVENTTYPECOUNTER
)
-- SELECT * FROM RANKING;
,FINAL AS
(
SELECT
	MAIN.DATE
    ,MAIN.NAME
    ,COUNT(*)
    ,COUNT(CON.DATE)
    ,SUM(BIDS.TOTAL_BIDS) AS BIDS
    ,SUM(CON.LAST_BID_WIN) AS WINS
    ,COUNT(*) OVER ()
    ,SUM(SUM(CON.LAST_BID_WIN)) OVER ()
    ,SUM(SUM(CON.LAST_BID_WIN)) OVER () /COUNT(*) OVER () 
FROM
	RANKING MAIN
LEFT JOIN
	RANKING CON
ON
	MAIN.DATE = CON.DATE
AND
	MAIN.NAME = CON.NAME
AND
	MAIN.EVENTTYPECOUNTER = CON.EVENTTYPECOUNTER
AND
	CON.ACCURACY_RANKING = CON.BID_RANKING
LEFT JOIN
	BIDS
ON BIDS.DATE = MAIN.DATE
AND BIDS.NAME = MAIN.NAME

GROUP BY 1,2
HAVING COUNT(*) = COUNT(CON.DATE)
)
-- SELECT * FROM FINAL;
SELECT 
	COUNT(*) AS CONTESTANTS
    , AVG(BIDS) AS AVG_BIDS
    , SUM(WINS)/ COUNT(*) AS WIN_PERC
FROM 
	FINAL;
    
SELECT NAME, EVENTTYPECOUNTER, WIN
FROM  five_ep
WHERE EVENTTYPE = 'Bidders Row'
and NAME IN ('Ashleigh', 'Danielle', 'Patricia', 'Amy','Clinton','Daniel','Thomas','Cashala','Charles','Renee','Shelmarie')
GROUP BY 1,2,3;

#Q5
/*
Redo the following problem from Class 6 without using any JOINs:
For each carrier, determine the average distance that each of its planes flies each day. 
Only include planes that have a tail number beginning with 'N'. 
IMPORTANT: only consider plane-days where the plane flies for exactly one carrier in that day. 
(And do not exclude cases by "hard-coding" those instances.) Exclude all cancelled and diverted flight records. 
Your output should include the airline carrier code, the total number of records for each carrier code, and the average distance that each of its planes flies each day.
*/

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

WITH FLIGHTS AS
(
SELECT
    TAILNUM
    ,UNIQUECARRIER
    ,DATE(CONCAT(YEAR,'-',MONTH,'-',DAYOFMONTH)) AS FLIGHT_DATE
    ,SUM(DISTANCE) AS TOTAL_DIST
    ,RANK() OVER (PARTITION BY TAILNUM,DATE(CONCAT(YEAR,'-',MONTH,'-',DAYOFMONTH)) ORDER BY UNIQUECARRIER) AS NO_CARRIERS
    
FROM
    ontime
    
WHERE 
    CANCELLED = 0
AND
    DIVERTED = 0
    
AND UPPER(TAILNUM) LIKE 'N%'
GROUP BY 1,2,3
)
SELECT
	UNIQUECARRIER
    ,AVG(TOTAL_DIST) AS AVG_DIST
    ,COUNT(*) AS TOTAL_FLIGHTS
FROM
	FLIGHTS
WHERE
	NO_CARRIERS = 1
GROUP BY 1;

#Q6
/*
Provide a “Top-2” ranking for each month in terms of greatest average departure delay by airport.  
Focus only on non-cancelled, non-diverted flights.  
Only consider airports that have at least 1000 departures in every month 
(i.e. if an airport has at least one month with less than 1000 departures then it should be excluded from the rankings in all months).  
Use month names (i.e. January, February, etc.) and airport names instead of the “Origin” code.  
Your output should include month names, airport names, and rankings.  
Order your output from January to December then by ranking in ascending order.
*/
WITH AIRPORTS_1 AS
(
SELECT

	ORIGIN
    ,MONTH
    ,CASE
		WHEN COUNT(*)  >= 1000
        THEN 1
        END AS DEST_FLIGHT
	,COUNT(*)
    ,COUNT(*) OVER (PARTITION BY ORIGIN) AS AIRPORT_MONTH_TOT
    ,COUNT(DISTINCT MONTH,ORIGIN) 
    ,AVG(DEPDELAY) AS AVG_DELAY
FROM
	ontime A
WHERE
	CANCELLED = 0
AND
	DIVERTED = 0
GROUP BY 1,2
)
,AIRPORTS_FILTERED AS
(
SELECT 
	ORIGIN
FROM 
	AIRPORTS_1
GROUP BY 1
HAVING AVG(AIRPORT_MONTH_TOT) = SUM(DEST_FLIGHT)
 )
 ,RANKING AS
 (
 SELECT 
 A.*
 ,RANK() OVER (PARTITION BY MONTH ORDER BY AVG_DELAY DESC) AS RANKING
 FROM 
	AIRPORTS_1 A
 INNER JOIN
	AIRPORTS_FILTERED B
ON 
	A.ORIGIN = B.ORIGIN
)

SELECT
	airports.Name AS AIRPORT
    ,MONTHNAME(DATE(CONCAT(2022,'-',R.Month,'-',01))) AS DEPARTURE_MONTH
    ,R.RANKING
FROM
	RANKING R
INNER JOIN
	airports 
ON
	R.ORIGIN = airports.IATA
WHERE 
	RANKING <= 2
ORDER BY 
	MONTH
    ,RANKING;

SELECT * FROM airports limit 10;

-- Q7
/*
Consider all of the users in our “yelp” database that have made at least 10 reviews.  
(You want to verify the number of reviews that a user has made using the data in the “review” table NOT the “review_count” column in the “user” table.)  
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
    
 -- Q8
 /*
 Yikes!  That’s a pretty long time!  Let’s dig a little deeper.  
 Consider the same set of users from the previous question.  
 But now, split them into two different groups:  
	those that gave a “high” rating (i.e. 4 or 5 stars) on their first review 
    versus those that gave a “low” rating on their first review (i.e. less than 4 stars).  
For each of these groups, calculate the average amount of time (in days) between each consecutive review in the first 10 reviews.  
So, you are calculating the average amount of time between the 1st and 2nd reviews, the 2nd and 3rd reviews, the 3rd and 4th reviews, etc.  
Your output should have 9 rows and 3 columns and should look like the template I have included below…
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

#Q9
/*
Homer Simpson loves many things in life, including beer (his favorite brand is “Duff”).  
In what season/episode does Homer say “beer” or “Duff” for the 50th, 150th, and 250th times?  
Be sure to only include instances of “beer” or “Duff” linked to Homer’s character_id=2.  
Be aware that a single record in the “script_lines” table can contain multiple instances of “beer” and/or “Duff” and I want you to count all of them.  
For instance, if Homer says “I love Duff beer. Duff beer is the greatest!” in one “script_lines” record then that counts as 4, not 1.  
Specifically, count all instances of the strings “beer” and “duff” in the “normalized_text” field.  
(You don’t need to worry about any oddities here.  
For instance, if Homer says “beeeeeer” out of excitement, something like that can be ignored.  
You should just want to identify all records containing “beer” and/or “duff” and count the number of instances of these two strings in those records.)  
Your output should include 
	the season
    , episode number within the season
    , episode title
    , location
    , raw_text
    , and ‘beer/duff counter’ 
for each of the 50th, 150th, and 250th occurrences (so your output should only have 3 rows). 
(It’s okay to make the font for your output very small and wrap text for the title and raw_text columns.)
*/
SELECT     *,COUNT(CASE 
              WHEN 	UPPER(NORMALIZED_TEXT) LIKE '%DUFF%' 
              THEN 1
          END) OVER (PARTITION BY S.ID) 
          + COUNT(CASE 
              WHEN 	UPPER(NORMALIZED_TEXT) LIKE '%BEER%'
              THEN 1
          END) OVER (PARTITION BY S.ID)	 AS DUFF_BEER_COUNT
FROM
	script_lines S
INNER JOIN
	characters C
ON 
	UPPER(S.RAW_CHARACTER_TEXT) = UPPER(C.NAME)
WHERE
	UPPER(NORMALIZED_TEXT) LIKE '%DUFF%'
OR	
	UPPER(NORMALIZED_TEXT) LIKE '%BEER%'
AND 
	UPPER(C.NAME) = 'HOMER SIMPSON'
;
WITH CHARACTER_SCRIPT AS
(
SELECT 
	SEASON
    ,NUMBER_IN_SEASON
    ,NUMBER_IN_SERIES
    ,EPISODE_ID
    ,S.ID AS SCRIPT_LINE_ID
    ,TITLE
    ,NORMALIZED_TEXT
    ,RAW_LOCATION_TEXT
    ,(LENGTH(NORMALIZED_TEXT) - LENGTH(REPLACE((NORMALIZED_TEXT),'duff','')))/4 AS DUFF_COUNT
    ,(LENGTH(NORMALIZED_TEXT) - LENGTH(REPLACE((NORMALIZED_TEXT),'beer','')))/4 AS BEER_COUNT
    ,(LENGTH(NORMALIZED_TEXT) - LENGTH(REPLACE((NORMALIZED_TEXT),'duff','')))/4 + (LENGTH(NORMALIZED_TEXT) - LENGTH(REPLACE((NORMALIZED_TEXT),'beer','')))/4 AS DUFF_BEER_COUNT
FROM
	script_lines S
INNER JOIN
	episodes E
ON
	E.ID = S.EPISODE_ID
WHERE
	S.CHARACTER_ID = 2
)
,RANKING AS
(
SELECT 
	*
    ,SUM(DUFF_BEER_COUNT) OVER (ORDER BY SCRIPT_LINE_ID) AS RNK
 FROM 
	CHARACTER_SCRIPT
WHERE
	DUFF_BEER_COUNT <> 0 
 )

 SELECT
	SEASON
    ,NUMBER_IN_SEASON AS EPISODE_NUMBER
    ,TITLE
    ,NORMALIZED_TEXT
    ,RAW_LOCATION_TEXT
    ,RNK
FROM
	RANKING
WHERE
	RNK = 50 
OR 
	RNK = 150 
OR 
	RNK = 250;
    
SELECT
	EPISODE_ID
    ,NUMBER
    ,CHARACTER_ID
    ,CASE
		WHEN CHARACTER_ID = 18 
        THEN 1
        ELSE 0
	END AS BARNEY_IND
FROM
	script_lines
WHERE
	EPISODE_ID = 114;
    
    #q4
WITH BIDS AS
(
SELECT 
	NAME
    ,DATE
    ,COUNT(*) AS TOTAL_BIDS
    ,COUNT(EVENTTYPECOUNTER) AS COUNT_BIDS
FROM 	five_ep
WHERE EVENTTYPE = 'Bidders Row'
GROUP BY 1,2
)
SELECT * FROM BIDS


;
,PARTICIPANTS AS
(
SELECT 
	DATE
    ,NAME
   -- ,EVENTORDER
    ,EVENTTYPECOUNTER
    -- ,TOTAL_BIDS
    ,CASE WHEN EVENTTYPECOUNTER = MAX(EVENTTYPECOUNTER) OVER (PARTITION BY DATE,NAME) 
		  THEN WIN 
          END AS LAST_BID_WIN
    ,SUM(EVENTAMOUNT) AS TOTAL_WINNINGS
    ,SUM(PRICE)
    ,ROUND(ABS(SUM(EVENTAMOUNT) - SUM(PRICE)),0) AS ACCURACY
    -- ,SUM(TOTAL_BIDS) AS TOTAL_BIDS
    ,COUNT(EVENTTYPECOUNTER) OVER (PARTITION BY DATE,NAME) AS COUNT_BIDS
    
FROM  five_ep
WHERE EVENTTYPE = 'Bidders Row'
GROUP BY 1,2,3
)

,RANKING AS
(
SELECT 
	P.DATE
    ,P.NAME
    ,P.EVENTTYPECOUNTER
    ,P.ACCURACY
   -- ,P.TOTAL_BIDS AS COUNT_BIDS_
    ,LAST_BID_WIN
    ,RANK() OVER (PARTITION BY P.DATE, P.NAME ORDER BY P.ACCURACY) AS ACCURACY_RANKING
    ,RANK() OVER (PARTITION BY P.DATE, P.NAME ORDER BY P.EVENTTYPECOUNTER) AS BID_RANKING

FROM PARTICIPANTS P

WHERE COUNT_BIDS >= 2
ORDER BY 
	DATE
    ,NAME
    ,EVENTTYPECOUNTER
)
-- SELECT * FROM RANKING;
,FINAL AS
(
SELECT
	MAIN.DATE
    ,MAIN.NAME
    ,COUNT(*)
    ,COUNT(CON.DATE)
    ,SUM(BIDS.TOTAL_BIDS) AS BIDS
    ,SUM(CON.LAST_BID_WIN) AS WINS
    ,COUNT(*) OVER ()
    ,SUM(SUM(CON.LAST_BID_WIN)) OVER ()
    ,SUM(SUM(CON.LAST_BID_WIN)) OVER () /COUNT(*) OVER () 
FROM
	RANKING MAIN
LEFT JOIN
	RANKING CON
ON
	MAIN.DATE = CON.DATE
AND
	MAIN.NAME = CON.NAME
AND
	MAIN.EVENTTYPECOUNTER = CON.EVENTTYPECOUNTER
AND
	CON.ACCURACY_RANKING = CON.BID_RANKING
LEFT JOIN
	BIDS
ON BIDS.DATE = MAIN.DATE
AND BIDS.NAME = MAIN.NAME

GROUP BY 1,2
HAVING COUNT(*) = COUNT(CON.DATE)
)
-- SELECT * FROM FINAL;
SELECT 
	COUNT(*) AS CONTESTANTS
    , AVG(BIDS) AS AVG_BIDS
    , SUM(WINS)/ COUNT(*) AS WIN_PERC
FROM 
	FINAL;
    
SELECT NAME, EVENTTYPECOUNTER, WIN
FROM  five_ep
WHERE EVENTTYPE = 'Bidders Row'
and NAME IN ('Ashleigh', 'Danielle', 'Patricia', 'Amy','Clinton','Daniel','Thomas','Cashala','Charles','Renee','Shelmarie')
GROUP BY 1,2,3;


WITH t1 AS
(
SELECT *, COUNT(*) AS num, AVG(DepDelay) as AVG
FROM ontime
WHERE Cancelled = 0 AND DIVERTED = 0 
GROUP BY Month, Origin
), t2 AS
(
SELECT *, MIN(num) OVER(PARTITION BY Origin) as Min_Count
FROM t1
), t3 AS
(
SELECT *, RANK() OVER (PARTITION BY Year, Month ORDER BY AVG DESC) AS RNK
FROM t2
WHERE Min_Count >= 1000
), t4 AS(
SELECT t3.Month, airports.Name, t3.RNK
FROM t3 AS t3
INNER JOIN airports 
ON    t3.Origin = airports.IATA
WHERE RNK <= 2
ORDER BY Month, RNK
), t5 AS
(
SELECT *, ROW_NUMBER() OVER() AS new_RNK
FROM t4
)
SELECT *
FROM t5;
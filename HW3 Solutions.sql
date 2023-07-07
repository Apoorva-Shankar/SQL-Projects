/*
Using the pir database, generate a result set that contains the biggest winner (i.e. most total winnings) on each day of the show. 
Your result set should contain three columns: the date of the show, the biggest winner’s name on that date, and the biggest winner’s total winnings on that date (call this column “tot_winnings”). 
Order your output by the date of the show in ascending order.
*/

SELECT * FROM pir.five_ep LIMIT 10
;
SELECT A.DATE, B.NAME, A.TOT_WINNINGS
FROM
(
SELECT DATE,MAX(WINNINGS) AS TOT_WINNINGS
FROM
(
SELECT 
	DATE
    ,NAME
    ,SUM(PRICE) AS WINNINGS
FROM
	five_ep
WHERE 
	WIN = 1
GROUP BY 
	DATE
    ,NAME
) T
GROUP BY DATE) A
INNER JOIN
(SELECT 
	DATE
    ,NAME
    ,SUM(PRICE) AS WINNINGS
FROM
	five_ep
WHERE 
	WIN = 1
GROUP BY 
	DATE
    ,NAME
    )B
ON A.DATE = B.DATE
AND  A.TOT_WINNINGS = B.WINNINGS
ORDER BY DATE;

/* Q2
Again using the pir database, focus on the “Big Wheel.” 
In particular, determine the highest first spin amount where the contestant decided to take a second spin and their total for both spins was still less than or equal to $1.00. 
Your result set should be a single value. (Feel free to ignore the one instance where a contestant took a third “bonus” spin. 
Put differently, focus only on a contestant’s first two spins.)
*/

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

SELECT * FROM 
	five_ep
WHERE
	EVENTTYPE = 'Big Wheel'
    AND NAME IN ('Philip','Eleanor');
    
    
/* Q3
Again using the pir database, focus on “Bidders Row.” 
Depending on the previous three contestants’ bids, it can sometimes be a good strategy for the fourth (i.e. last) bidder to bid exactly 
$1 more than the maximum bid up to that point. 
(In doing this, as long as the fourth bidder’s bid is less than the prize value, they will automatically win.) 
So, first identify all of the instances on “Bidders Row” where the last bidder bids exactly $1 more than maximum of the first three bids. 
What percentage of the time does the 4th bidder win when using this strategy? 
Your result set should have two rows and three columns. 
The first column (call this column “outcome_group”) should have two categories: “bidder4_wins” and “bidder4_loses”. 
The other two columns should contain the appropriate counts (call this column “n_times”) 
and percentages (call this column “percent_total”) for each category.
*/

SELECT
	CASE
		WHEN WIN = 1 THEN 'bidder4_wins'
        ELSE 'bidder4_loses'
	END AS outcome_group
    ,COUNT(*) AS n_times
	,(COUNT(CASE
				WHEN WIN = 1 THEN 1
		END)/COUNT(*))*100 AS percentages
FROM
(
SELECT 
	A.DATE
    ,A.NAME
    ,A.eventTypeCounter
    ,A.WIN
    ,SUM(A.EVENTAMOUNT) AS _4th_bid
    ,SUM(B.MAX_BID) AS max_bid
    ,SUM(A.EVENTAMOUNT) - SUM(B.MAX_BID) AS DIFF
    
FROM
	five_ep A
LEFT JOIN
(SELECT 
	DATE
    ,eventTypeCounter
    ,MAX(EVENTAMOUNT) AS MAX_BID
FROM
	five_ep
WHERE
	EVENTTYPE = 'Bidders Row'
AND
	EVENTORDER < 4
GROUP BY
	DATE
    ,EVENTTYPECOUNTER
    ) B
ON A.DATE = B.DATE
AND A.eventTypeCounter = B.eventTypeCounter
WHERE
	EVENTTYPE = 'Bidders Row'
AND
	EVENTORDER = 4
GROUP BY
	DATE
    ,eventTypeCounter
    ,NAME
) T
WHERE _4TH_BID - MAX_BID = 1
GROUP BY outcome_group;
    
    
SELECT eventTypeCounter,eventOrder,NAME, DATE,sum(eventAmount) FROM five_ep
WHERE EVENTTYPE = 'Bidders Row'

group by 1,2,3,4;

/* Q4
Next, let’s switch over to the airline_ontime database. 
We want to confirm that every flight record in our “ontime” table has valid information for the origin and destination airports. 
Let’s do this by running three separate queries. 
First, count the total number of records in the airline_ontime.ontime table. 
Next, join the airline_ontime.ontime table with the airline_ontime.airports table on the origin airport 
(using the appropriate column in the “airports” table—documentation for the airports table can be found here:  
https://openflights.org/data.html).
 Finally, join the airline_ontime.ontime table with the airline_ontime.airports table on the destination airport. 
 Compare the three counts—are they equal? If so, we can conclude that all of our flight records have valid origins and destinations! 
 (Be sure to use the correct type of joins. Why would using a LEFT JOIN in this situation not help us answer our question of interest???)
*/
SELECT 
	COUNT(*) 
FROM
	ontime;
SELECT DISTINCT COUNTRY FROM airports;

SELECT COUNT(*)
FROM
	ontime A
INNER JOIN
	airports B
ON A.Dest = B.IATA;

/*Q5
Provide a count (“Total_Rec”) of the number of non-cancelled, non-diverted flights departing from each airport outside of the ‘United States’. 
Include country name and airport name in your output (but you do not need to generate aliases for these two columns). Order your output from highest to lowest “Total_Rec.” 
*/

SELECT
	COUNTRY
    ,CITY
    ,COUNT(*) AS TOTAL_REC
FROM
	ontime A
INNER JOIN
	airports B
ON A.ORIGIN = B.IATA
WHERE
	UPPER(B.COUNTRY) <> 'UNITED STATES' 
AND
	A.CANCELLED = 0
AND
	A.DIVERTED = 0
GROUP BY
	COUNTRY
    ,CITY;
    
    
/*
What are the 10 most common flights that originate inside the ‘United States’? 
Ignore all cancelled and diverted flights. 
Your output should include the name of the airport where the flight departs, 
the name of the airport where the flight lands, 
and the total count of flight records for each departure/arrival pair. 
Drop the string ‘ Airport’ from your departaure and arrival airport names to conserve space in your output. 
(HINT: nothing is preventing you from JOINing with the airports table twice! Whenever you have multiple JOINs they always occur sequentially—the first JOIN you specify happens first. Then, the result of that first JOIN is JOINed again with the next table.)
*/

SELECT 

    REPLACE(ORIG.NAME,'Airport','') as ORIGIN_AIRPORT,
  
	REPLACE(DEST.NAME,'Airport','') as DESTINATION_AIRPORT 

    ,COUNT(*)
FROM
	ontime O
INNER JOIN
	airports ORIG 
ON 
	O.ORIGIN = ORIG.IATA
INNER JOIN
	airports DEST
ON
	O.DEST = DEST.IATA

WHERE
	UPPER(ORIG.COUNTRY) = 'UNITED STATES' 
AND
	O.Cancelled = 0
AND
	O.Diverted = 0
GROUP BY
	ORIGIN_AIRPORT
    ,DESTINATION_AIRPORT
ORDER BY 
	COUNT(*) DESC
LIMIT 10;

SELECT ORIGIN,DEST,COUNT(*),country FROM ontime
INNER JOIN airports on ontime.origin = airports.iata
WHERE
Cancelled = 0
AND
Diverted = 0
GROUP BY 1,2,4
ORDER BY COUNT(*) DESC

;

/*  Q7
Count the total number of flight records that both depart and arrive in the ‘UNITED STATES’ where the altitude change between departure and arrival locations is at least 3000 feet. 
 Ignore all records that are cancelled or diverted.
*/

SELECT 
	COUNT(*)
FROM
	ontime 
INNER JOIN
	airports ORIG
ON ontime.Origin = ORIG.IATA
AND UPPER(ORIG.COUNTRY) = 'UNITED STATES'

INNER JOIN
	airports DESTI
ON ontime.Dest = DESTI.IATA
AND UPPER(DESTI.COUNTRY) = 'UNITED STATES'

WHERE ABS(ORIG.ALTITUDE-DESTI.ALTITUDE) >= 3000
AND DIVERTED = 0
AND CANCELLED = 0
;

/* Q8
Using your code from the previous question (and continuing to ignore all cancelled or diverted flights), the flight records that “both depart and arrive in the ‘United States’ where the altitude change between departure and arrival locations is at least 3000 feet” is what percentage of all flight records that both depart and arrive in the ‘United States’?  Calculate this percentage in a single query.
*/
SELECT 
	(SUM(CASE
			WHEN  ABS(ORIG.ALTITUDE-DESTI.ALTITUDE) >= 3000
            THEN 1
		END)/COUNT(*))*100 AS PERCENTAGE
        ,COUNT(*)
FROM
	ontime 
INNER JOIN
	airports ORIG
ON ontime.Origin = ORIG.IATA
AND UPPER(ORIG.COUNTRY) = 'UNITED STATES'

INNER JOIN
	airports DESTI
ON ontime.Dest = DESTI.IATA
AND UPPER(DESTI.COUNTRY) = 'UNITED STATES'

WHERE 
	DIVERTED = 0
AND CANCELLED = 0
;


/* Q9
For the next few questions we’ll focus on time zones spanning the “lower 48” (i.e. the United States excluding Alaska and Hawaii).  
Our ultimate goal is to determine the total number of flights that span at least three time zones.  
But, we’ll break the problem into parts.  First, we want to consider the following time zone values from our “airports” table:
		--America/New_York (this is the Eastern timezone)
		--America/Chicago (this is the Central timezone)
		--America/Denver and America/Phoenix (this is the Mountain timezone)
		--America/Los_Angeles (this is the Pacific timezone)
Moving from east to west, write a CASE statement to assign the numbers 1 to 4 to each time zone group.  
(NOTE:  you are not writing an entire query here—just a CASE statement! And, make sure to include an ELSE NULL condition!)
*/

CASE
	WHEN TIMEZONE = 'America/New_York'
    THEN 1
    WHEN TIMEZONE = 'America/Chicago'
    THEN 2
    WHEN TIMEZONE IN ('America/Denver','America/Phoenix')
    THEN 3
    WHEN TIMEZONE = 'America/Los_Angeles'
    THEN 4
    ELSE NULL
END

;

/* Q 10
Next, we’ll apply our CASE statement from the previous problem to assign each origin and destination airport a TZ_Num.  
Only consider flights that depart and arrive in the United States.  
Ignore cancelled and diverted flights.  (So, this means each flight record will have two time zone group numbers.)  
Run the query, but you do not need to include your output.
*/
SELECT
	DEPART.NAME
    ,CASE
		WHEN DEPART.TIMEZONE = 'America/New_York'
		THEN 1
		WHEN DEPART.TIMEZONE = 'America/Chicago'
		THEN 2
		WHEN DEPART.TIMEZONE IN ('America/Denver','America/Phoenix')
		THEN 3
		WHEN DEPART.TIMEZONE = 'America/Los_Angeles'
		THEN 4
		ELSE NULL
	END AS TZ_NUM_DEPART
    ,ARRIVE.NAME
	,CASE
		WHEN ARRIVE.TIMEZONE = 'America/New_York'
		THEN 1
		WHEN ARRIVE.TIMEZONE = 'America/Chicago'
		THEN 2
		WHEN ARRIVE.TIMEZONE IN ('America/Denver','America/Phoenix')
		THEN 3
		WHEN ARRIVE.TIMEZONE = 'America/Los_Angeles'
		THEN 4
		ELSE NULL
	END AS TZ_NUM_DEPART
FROM
	ontime 
INNER JOIN
	airports DEPART
ON ontime.Origin = DEPART.IATA
AND UPPER(DEPART.COUNTRY) = 'UNITED STATES'

INNER JOIN
	airports ARRIVE
ON ontime.Dest = ARRIVE.IATA
AND UPPER(ARRIVE.COUNTRY) = 'UNITED STATES'

WHERE 
	DIVERTED = 0
AND CANCELLED = 0
GROUP BY
	1,2,3,4;
    
/* Q11
Utilize the previous query (with an additional new CASE statement that also includes and ELSE NULL condition) to determine the total number of flights that span at least three time zones.
*/
SELECT COUNT(*) 
FROM
(
SELECT
	DEPART.NAME AS DEPARTURE
    ,CASE
		WHEN DEPART.TIMEZONE = 'America/New_York'
		THEN 1
		WHEN DEPART.TIMEZONE = 'America/Chicago'
		THEN 2
		WHEN DEPART.TIMEZONE IN ('America/Denver','America/Phoenix')
		THEN 3
		WHEN DEPART.TIMEZONE = 'America/Los_Angeles'
		THEN 4
		ELSE NULL
	END AS TZ_NUM_DEPART
    ,ARRIVE.NAME AS ARRIVAL
	,CASE
		WHEN ARRIVE.TIMEZONE = 'America/New_York'
		THEN 1
		WHEN ARRIVE.TIMEZONE = 'America/Chicago'
		THEN 2
		WHEN ARRIVE.TIMEZONE IN ('America/Denver','America/Phoenix')
		THEN 3
		WHEN ARRIVE.TIMEZONE = 'America/Los_Angeles'
		THEN 4
		ELSE NULL
	END AS TZ_NUM_ARRIVE
FROM
	ontime 
INNER JOIN
	airports DEPART
ON ontime.Origin = DEPART.IATA
AND UPPER(DEPART.COUNTRY) = 'UNITED STATES'

INNER JOIN
	airports ARRIVE
ON ontime.Dest = ARRIVE.IATA
AND UPPER(ARRIVE.COUNTRY) = 'UNITED STATES'

WHERE 
	DIVERTED = 0
AND CANCELLED = 0
) T
WHERE ABS(TZ_NUM_DEPART - TZ_NUM_ARRIVE) >= 2
;

SELECT * FROM ontime LIMIT 10;

/*
OH NO!  In 2007 there were no direct flights between RDU and SFO.  
What a travesty! (And my how things have changed!)  
In 2007, how many different routes could you take to get from RDU to SFO with EXACTLY ONE STOP IN BETWEEN? 
Drop all flight records that are cancelled or diverted (or both). 
You can ignore all “timing” considerations in your query 
(i.e. you don’t, for instance, need to verify that there is a flight record leaving your layover city after you would arrive there from RDU).  
You should also ignore carriers in this problem (i.e. it’s perfectly fine to fly the two “legs” of your trip on different carriers).  
The only restriction is that each leg of a valid route must have 300 flights in 2007.  
So, for instance, if your route is RDU>JFK>SFO, it must be that there are 300 flights from RDU to JFK and 300 flights from JFK to SFO.
*/
WITH DEPART AS
(
SELECT
	ORIGIN AS DEPARTURE_AIRPORT
    ,DEST
    ,COUNT(*)
FROM
	ontime
WHERE
	ORIGIN = 'RDU'
GROUP BY 1,2
HAVING COUNT(*) >= 300
)
,ARRIVE AS
(
SELECT 
	ORIGIN
    ,DEST AS ARRIVAL_AIRPORT
    ,COUNT(*)
FROM
	ontime
WHERE
	DEST = 'SFO'
GROUP BY 1,2
HAVING COUNT(*) >= 300
)
SELECT
COUNT(*)
FROM
DEPART
INNER JOIN
ARRIVE
ON DEPART.DEST = ARRIVE.ORIGIN
;

/*
Using the “yelp” database, let’s examine some data on recent reviews.  
Focus on all reviews in the database on or after October 1, 2019.  
What percentage of restaurants that are open (is_open = 1) have at least one review since October 1, 2019?  
Your output should have two rows (one for each restaurant group—those that have at least one review and those that don’t) 
and two columns (restaurant group and the percentage of restaurants in each group).
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

SELECT
	COUNTRY
    ,CITY
    ,COUNT(*) AS TOTAL_REC
FROM
	ontime A
INNER JOIN
	airports B
ON A.ORIGIN = B.IATA
WHERE
	UPPER(B.COUNTRY) NOT LIKE 'UNITED STATES' 
AND
	A.CANCELLED = 0
AND
	A.DIVERTED = 0
GROUP BY
	COUNTRY
    ,CITY
ORDER BY 
TOTAL_REC DESC;

SELECT * FROM review LIMIT 10;
SELECT
CASE
		WHEN WIN = 1 THEN 'bidder4_wins'
        ELSE 'bidder4_loses'
	END AS outcome_group
    ,COUNT(*) AS n_times
	,(COUNT(CASE
				WHEN WIN = 1 THEN 1
                ELSE 2
		END)/MAX(TOTAL_BIDS))*100 AS percentages

FROM
(
SELECT
	*
    ,COUNT(WIN) OVER (PARTITION BY 1) AS TOTAL_BIDS
FROM
(
SELECT 
	A.DATE
    ,A.NAME
    ,A.eventTypeCounter
    ,A.WIN
    ,SUM(A.EVENTAMOUNT) AS _4th_bid
    ,SUM(B.MAX_BID) AS max_bid
    ,SUM(A.EVENTAMOUNT) - SUM(B.MAX_BID) AS DIFF
	
    
FROM
	five_ep A
LEFT JOIN
(SELECT 
	DATE
    ,eventTypeCounter
    ,MAX(EVENTAMOUNT) AS MAX_BID
FROM
	five_ep
WHERE
	EVENTTYPE = 'Bidders Row'
AND
	EVENTORDER < 4
GROUP BY
	DATE
    ,EVENTTYPECOUNTER
    ) B
ON A.DATE = B.DATE
AND A.eventTypeCounter = B.eventTypeCounter
WHERE
	EVENTTYPE = 'Bidders Row'
AND
	EVENTORDER = 4
GROUP BY
	DATE
    ,eventTypeCounter
    ,NAME
) T
WHERE _4TH_BID - MAX_BID = 1
) K
GROUP BY outcome_group;





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
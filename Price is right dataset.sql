/*
generating a result set that contains the biggest winner (i.e. most total winnings) on each day of the show. 
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

/*
focusing on the “Big Wheel.” 
In particular, determining the highest first spin amount where the contestant decided to take a second spin and their total for both spins was still less than or equal to $1.00.
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
    
    
/* 
focusing on “Bidders Row.” 
Depending on the previous three contestants’ bids, it can sometimes be a good strategy for the fourth (i.e. last) bidder to bid exactly 
$1 more than the maximum bid up to that point. 
(In doing this, as long as the fourth bidder’s bid is less than the prize value, they will automatically win.) 
So, first identify all of the instances on “Bidders Row” where the last bidder bids exactly $1 more than maximum of the first three bids. 
What percentage of the time does the 4th bidder win when using this strategy? 
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

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

------

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
    
----
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
    
----

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

--
/*
How often do bidders make less-accurate bids on “Bidders Row” as the show progresses? 
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

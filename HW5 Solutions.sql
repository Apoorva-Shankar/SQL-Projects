

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

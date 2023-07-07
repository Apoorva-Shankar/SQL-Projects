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
    

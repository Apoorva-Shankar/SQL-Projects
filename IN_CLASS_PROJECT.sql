SELECT DISTINCT WCWIN, DIVWIN, LGWIN,WSWIN FROM Teams 
WHERE YEARID BETWEEN 1980 AND 2019 ;

WITH TEAM AS
(
SELECT 
	YEARID
    ,TEAMID
    ,BPF AS X
    ,W/G AS Y
    ,R
    ,BPF*(W/G) AS XY
    ,(W/G)*(W/G) AS Ysq
    ,BPF*BPF AS Xsq
	,COUNT(*) OVER () AS N
    ,RANK() OVER (PARTITION BY YEARID ORDER BY W/G DESC , R DESC) AS TEAM_RANKING
    ,RANK() OVER (PARTITION BY YEARID ORDER BY W/G DESC , R DESC)* RANK() OVER (PARTITION BY YEARID ORDER BY W/G DESC , R DESC) AS TEAM_RANKING_SQ
    ,RANK() OVER (PARTITION BY YEARID ORDER BY W/G DESC , R DESC)*BPF AS X_RANKING
    ,WCWIN, DIVWIN, LGWIN,WSWIN
    ,CASE
		WHEN UPPER(TRIM(WCWIN)) = 'Y' THEN 1
        WHEN UPPER(TRIM(DIVWIN)) = 'Y' THEN 2
        WHEN UPPER(TRIM(LGWIN)) = 'Y' THEN 5
        WHEN UPPER(TRIM(WSWIN)) = 'Y' THEN 10
	END AS PLAYOFF_POINTS
    , (CASE
		WHEN UPPER(TRIM(WCWIN)) = 'Y' THEN 1
        WHEN UPPER(TRIM(DIVWIN)) = 'Y' THEN 2
        WHEN UPPER(TRIM(LGWIN)) = 'Y' THEN 5
        WHEN UPPER(TRIM(WSWIN)) = 'Y' THEN 10
	END) * (CASE
		WHEN UPPER(TRIM(WCWIN)) = 'Y' THEN 1
        WHEN UPPER(TRIM(DIVWIN)) = 'Y' THEN 2
        WHEN UPPER(TRIM(LGWIN)) = 'Y' THEN 5
        WHEN UPPER(TRIM(WSWIN)) = 'Y' THEN 10
	END) AS PLAYOFF_POINTS_SQ
    ,(CASE
		WHEN UPPER(TRIM(WCWIN)) = 'Y' THEN 1
        WHEN UPPER(TRIM(DIVWIN)) = 'Y' THEN 2
        WHEN UPPER(TRIM(LGWIN)) = 'Y' THEN 5
        WHEN UPPER(TRIM(WSWIN)) = 'Y' THEN 10
	END) * BPF AS X_PLAY_OFF
        
    
FROM
	Teams
WHERE YEARID BETWEEN 1980 AND 2019
)

,NUMERATOR_1 AS
(
SELECT AVG(N)
		,SUM(XY)
        ,SUM(X)
        ,SUM(Y)
		,(AVG(N)*SUM(XY)) - (SUM(X)*SUM(Y)) AS NUM_1
FROM TEAM
)
,DENOMINATOR_1 AS
(
SELECT 
	AVG(N)
    ,SUM(Xsq)
    ,SUM(Ysq)
    ,SUM(X)*SUM(X)
    ,(SQRT(AVG(N)*SUM(Xsq) - SUM(X)*SUM(X)))*(SQRT(AVG(N)*SUM(Ysq) - SUM(Y)*SUM(Y))) AS DEN_1
FROM
	TEAM
)
,NUMERATOR_2 AS
(
SELECT AVG(N)
		,SUM(X_RANKING)
        ,SUM(X)
        ,SUM(TEAM_RANKING)
		,(AVG(N)*SUM(X_RANKING)) - (SUM(X)*SUM(TEAM_RANKING)) AS NUM_2
FROM TEAM
)
,DENOMINATOR_2 AS
(
SELECT 
	AVG(N)
    ,SUM(Xsq)
    ,SUM(TEAM_RANKING_SQ)
    ,SUM(X)*SUM(X)
    ,(SQRT(AVG(N)*SUM(Xsq) - SUM(X)*SUM(X)))*(SQRT(AVG(N)*SUM(TEAM_RANKING_SQ) - SUM(TEAM_RANKING)*SUM(TEAM_RANKING))) AS DEN_2
FROM
	TEAM
)
,NUMERATOR_3 AS
(
SELECT AVG(N)
		,SUM(X_PLAY_OFF)
        ,SUM(X)
        ,SUM(PLAYOFF_POINTS)
		,(AVG(N)*SUM(X_PLAY_OFF)) - (SUM(X)*SUM(PLAYOFF_POINTS)) AS NUM_3
FROM TEAM
)
,DENOMINATOR_3 AS
(
SELECT 
	AVG(N)
    ,SUM(Xsq)
    ,SUM(PLAYOFF_POINTS_SQ)
    ,SUM(X)*SUM(X)
    ,(SQRT(AVG(N)*SUM(Xsq) - SUM(X)*SUM(X)))*(SQRT(AVG(N)*SUM(PLAYOFF_POINTS_SQ) - SUM(PLAYOFF_POINTS)*SUM(PLAYOFF_POINTS))) AS DEN_3
FROM
	TEAM
)
SELECT    NUM_1/DEN_1 AS CORR_1
        , NUM_2/DEN_2 AS CORR_2
        , NUM_3/DEN_3 AS CORR_3
FROM DENOMINATOR_1
INNER JOIN NUMERATOR_1
ON 1 = 1
INNER JOIN DENOMINATOR_2
ON 1 = 1
INNER JOIN NUMERATOR_2
ON 1 = 1
INNER JOIN NUMERATOR_3
ON 1=1
INNER JOIN DENOMINATOR_3
ON 1=1
;
-- NO MERIT IN HYPOTHESIS

#2
SELECT * FROM Batting limit 100;
select * from BattingPost limit 100
So, before you do anything else, you should sum a player’s stats for BB, IBB, HBP, H, 2B, 3B, HR, AB, and SF  before you do anything else and use these summed values for an individual player year, in a specific year in the equation below.)  Once you have summed each player’s stats for an entire year, you should then filter out all player-years where the player does not meet the AB threshold for that year.

For each player that qualifies (based on the AB threshold) in a given year, calculate their “wOBA” (“wOBA” is short for “weighted on-base average” and is intended to measure a batter’s overall offensive value) for that year.  The equation for wOBA is given as follows:

wOBA=  ((0.692×(BB-IBB))+(0.723×HBP)+(0.889×(H-2B-3B-HR))+(1.264×2B)+(1.604×3B)+(2.076×HR))/(AB+BB-IBB+SF+HBP);

SELECT 
	PLAYERID
    ,YEARID
    ,SUM(BB) AS BB
    ,SUM(IBB) AS IBB
    ,SUM(HBP) AS HBP
    ,SUM(H) AS H
    ,SUM(2B) AS 2B
    ,SUM(3B) AS 3B
    ,SUM(HR) AS HR
    ,SUM(AB) AS AB
    ,SUM(SF) AS SF
    ,((0.692*(COALESCE(SUM(BB),0)-COALESCE(SUM(IBB),0)))+(0.723*COALESCE(SUM(HBP),0))+(0.889*(COALESCE(SUM(H),0)-COALESCE(SUM(2B),0)-COALESCE(SUM(3B))-COALESCE(SUM(HR),0)))+(1.264*COALESCE(SUM(2B),0))+(1.604*COALESCE(SUM(3B),0))+(2.076*COALESCE(SUM(HR),0)))/(COALESCE(SUM(AB))+COALESCE(SUM(BB))-COALESCE(SUM(IBB))+COALESCE(SUM(SF))+COALESCE(SUM(HBP))) AS wOBA
FROM
	Batting
WHERE 
	YEARID BETWEEN 2010 AND 2021
GROUP BY
	1,2
;
WITH t1 AS
(
SELECT *,
CASE
WHEN teamID = 'ANA' OR teamID = 'CAL' THEN 'LAA'
WHEN teamID = 'FLO' THEN 'MIA'
WHEN teamID = 'MON' THEN 'WAS'
WHEN teamID = 'ML4' THEN 'MIL'
ELSE teamID
END AS teamIDnew
FROM Teams
),
t2 as
(
select *,
       R-RA,
       rank() over(partition by yearID,lgID order by W/G,R) as rnk_league,
       rank() over(partition by yearID,lgID,divID order by W/G,R) as rnk_division
from t1
where yearID>=1980),
t3 as
(
select *,
       avg(R-RA) over (partition by yearID,lgID) as avg_R,
       R-RA-avg(R-RA) over (partition by yearID,lgID) as R_diff,
       STDDEV(R-RA) over(partition by yearID,lgID) as SD_R
from t2),
t4 as
(
select *,
       R_diff/SD_R as Z_score,
       case when rnk_league in (1,2,3)
       and rnk_division in (1,2)
       and R_diff/SD_R<=-1.0 then 1
       else 0
       end as bad_year
from t3
order by teamID,yearID),
t5 as
(
select *,
       sum(bad_year) over (partition by teamID ORDER BY yearID ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS checker
from t4
),
t6 as
(
select yearID,teamID,checker,case when substr(yearID,1,3)=198 then '1980s'
       when substr(yearID,1,3)=199 then '1990s'
       when substr(yearID,1,3)=200 then '2000s'
       when substr(yearID,1,3)=201 then '2010s'
       when substr(yearID,1,3)=202 then '2020s'
       else null
       end as decade
from t5
where checker =3
having decade is not null)
select decade,count(checker),count(distinct(teamID))
from t6
group by 1;
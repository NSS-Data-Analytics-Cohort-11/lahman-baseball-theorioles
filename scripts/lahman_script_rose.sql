select * from people

select * from pitching

select * from teams

--1. What range of years for baseball games played does the provided database cover? 
SELECT MIN(yearid) AS first_year, MAX(yearid) AS last_year
FROM batting
  --Answer 1871-2016


--2. Find the name and height of the shortest player in the database. "Edward Carl Gaedel" height 43 
--How many games did he play in? What is the name of the team for which he played?
--"Edward Carl Gaedel"	height:43	played in:1 game	"St. Louis Browns"


SELECT DISTINCT pe.fullname, pe.height, a.g_all AS games_played,t.name AS team_name  --a.team_id
FROM
	(SELECT playerid,namegiven|| ' ' || namelast AS fullname, height
	 FROM people
	 ORDER BY height
	 LIMIT 1) as pe
	 
left JOIN appearances AS a
USING(playerid)
left JOIN teams AS t
ON a.teamid = t.teamid
--order by height 
--WHERE pe.height IS NOT NULL
--ORDER BY pe.height 
--LIMIT 1
-- select * from teams
-- where teamid like 'SLA'
-- --where name = 'St. Louis Browns'
-- select * from appearances
-- --order by playerid
-- where playerid ilike'gaed%'
-- order by playerid


--3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
--Answer: "David"	"Price"	"$81,851,296.00"

WITH school_name AS (
		SELECT DISTINCT playerid, schoolname, namefirst, namelast
		FROM people
		INNER JOIN collegeplaying
		USING(playerid)
		INNER JOIN schools
		USING(schoolid)
		WHERE schoolname ILIKE '%Vander%'
		--GROUP BY schoolname, namelast, namefirst, playerid
		ORDER BY schoolname)
		
SELECT people.namefirst, people.namelast, COALESCE(SUM(salaries.salary),0)::NUMERIC::MONEY AS total_salary
FROM people
LEFT JOIN salaries
USING(playerid)
INNER JOIN school_name
USING(playerid)
GROUP BY people.namefirst, people.namelast
ORDER BY total_salary DESC;




--4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
--Answer: postion and number of putouts
--"infield"	58934
--"battery"	41424
--"outfield" 29560

SELECT
	CASE 
	WHEN pos = 'OF' THEN 'outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'infield'
		WHEN pos IN ('P', 'C') THEN 'battery'
		END AS positions,
	SUM(PO) AS num_of_putouts
FROM fielding
WHERE yearid = '2016'
GROUP BY positions
ORDER BY num_of_putouts DESC;



--5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

--Answer: strikeouts per game and homeruns per game increased over time
SELECT ROUND(1.0*SUM(teams.so)/SUM(teams.g),2)
		AS avg_strikeouts_per_game,
	ROUND(1.0*SUM(teams.hr)/SUM(teams.g),2) AS avg_homeruns_per_game,
	CONCAT(LEFT(CAST(teams.yearid AS VARCHAR), 3), '0') AS decade
FROM teams
WHERE teams.yearid >= 1920
GROUP BY CONCAT(LEFT(CAST(teams.yearid AS VARCHAR), 3), '0')
ORDER BY decade;
   
   
--6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT people.namefirst AS first_name
	, people.namelast AS last_name
	, sb AS stolen_bases
	, cs AS caught_stealing
	, ROUND(SUM(batting.sb) / (SUM(batting.sb) + SUM(batting.cs))::NUMERIC * 100, 2)||'%' AS successful_steals
FROM batting
INNER JOIN people
ON batting.playerid = people.playerid
WHERE batting.yearid = 2016
GROUP BY people.namefirst, people.namelast, stolen_bases, caught_stealing
HAVING batting.sb >= 20
ORDER BY successful_steals DESC
LIMIT 10;




--7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?116 wins What is the smallest number of wins for a team that did win the world series?63 Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. 83 How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


--I am excluding 1981 since the season was split into 2 halves. they lost 2 monhs of the regular season, hence,they played a fewer number of games so their score overall will be lower compared to any other year.


--most wins of team that did not win the world series (116)
-- SELECT teamid,yearid, sub1.mostwins,sub2.leastwins
-- FROM teams,

WITH mostwinstotal AS
(SELECT yearid
		,MAX(w) AS w	
FROM teams
WHERE yearid BETWEEN '1970' and '2016' 
AND wswin = 'N'
GROUP BY yearid
order by w DESC)

SELECT mostwinstotal.yearid, teams.name,mostwinstotal.w
FROM mostwinstotal
INNER JOIN
teams
USING(yearid,w)
ORDER BY mostwinstotal.w DESC
--LIMIT 1


--least wins of team that won the world series 63 excluding 
SELECT  yearid --,teamid
		--,wswin
		, MIN(w) AS leastwins
	
FROM teams
WHERE yearid BETWEEN '1970' and '2016' 
--AND yearid <> 1981
AND wswin = 'Y'
GROUP BY  yearid
ORDER BY leastwins 
LIMIT 1--) AS sub2


--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series.What percentage of the time?

SELECT	COUNT(teams.yearid),MAX(w) AS mostwins	

CASE WHEN wswin = 'Y'
AND yearid<>'1981'THEN 'champions' ELSE 'loss' END AS champ

FROM teams
---HAVING w = MAX (w)
GROUP BY champ


SELECT COUNT
SELECT --teams.teamid, teams.yearid,
		--,MAX(w) AS mostwins	
		COUNT(teams.yearid)

AS mostwins_wswin
FROM teams,

SELECT DISTINCT e.yearid, e.teamid, mostwins, t.teamid AS WONSERIES
FROM teams AS t,
(SELECT yearid
		,MAX(w) AS mostwins		
FROM teams
WHERE yearid BETWEEN '1970' and '2016' 
--AND wswin = 'Y'
AND yearid <> '1981'
GROUP BY yearid
ORDER BY yearid) as e
 WHERE t.teamid = e.teamid
 ORDER BY yearid
 
--QUESTION 7 ANSWER: 23% of teams with max wins that also won the series 
 WITH numberseven AS  
(SELECT yearid
		,MAX(w) AS w	
FROM teams 
WHERE yearid BETWEEN '1970' and '2016' 

AND yearid <> '1981'
GROUP BY yearid),
 
perc AS(
SELECT t.name, n.yearid, t.wswin
 FROM numberseven As n
INNER JOIN teams AS t
USING (yearid,w)
)
 SELECT 
 
 (SELECT COUNT(*) FROM perc
 WHERE wswin = 'Y')*100.0/ count(*)
 
 FROM perc
 
 
 



select * from teams


--8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

--Top 5
SELECT 	
	parks.park_name,
	teams.name AS team_name,
	SUM(homegames.attendance)/SUM(homegames.games) AS avg_att
FROM parks
JOIN homegames
	USING(park)
JOIN teams
	ON homegames.team = teams.teamid
WHERE homegames.games >= 10
GROUP BY parks.park_name, teams.name
ORDER BY avg_att DESC
LIMIT 5;--Bottom 5
SELECT 	
	parks.park_name,
	teams.name AS team_name,
	SUM(homegames.attendance)/SUM(homegames.games) AS avg_att
FROM parks
JOIN homegames
	USING(park)
JOIN teams
	ON homegames.team = teams.teamid
WHERE homegames.games >= 10
GROUP BY parks.park_name, teams.name
HAVING SUM(homegames.attendance)/SUM(homegames.games)>1
ORDER BY avg_att
LIMIT 5;



--Solution from Jessica during review
SELECT
    p.namefirst || ' ' || p.namelast AS player_name,
    b.hr AS home_runs_2016
FROM batting AS b
INNER JOIN people AS p ON b.playerID = p.playerid
WHERE b.yearid = 2016
	AND hr > 0
	AND EXTRACT(YEAR FROM debut::date) <= 2016 - 9
    AND b.hr = (
        SELECT MAX(hr)
        FROM batting
        WHERE playerid = b.playerid)
ORDER BY home_runs_2016 DESC;




--9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT people.namefirst, people.namelast, teams.name, teams.lgid, awardsmanagers.yearid
FROM
	(SELECT playerid
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid IN('NL', 'AL')
	GROUP BY playerid
	HAVING COUNT(DISTINCT lgid) > 1) AS mb
INNER JOIN awardsmanagers ON mb.playerid = awardsmanagers.playerid
INNER JOIN people ON awardsmanagers.playerid = people.playerid
INNER JOIN managers ON people.playerid = managers.playerid AND awardsmanagers.yearid = managers.yearid
INNER JOIN teams ON managers.teamid = teams.teamid AND teams.yearid = managers.yearid
WHERE awardid = 'TSN Manager of the Year';



---solution from class review

WITH both_league_winners AS (
	SELECT
		playerid--, count(DISTINCT lgid)
	FROM awardsmanagers
	WHERE awardid = 'TSN Manager of the Year'
		AND lgid IN ('AL', 'NL')
	GROUP BY playerid
	--order by COUNT(DISTINCT lgid) desc
	HAVING COUNT(DISTINCT lgid) = 2
	)
SELECT
	namefirst || ' ' || namelast AS full_name,
	yearid,
	lgid,
	name
FROM people
INNER JOIN both_league_winners
USING(playerid)
INNER JOIN awardsmanagers
USING(playerid)
INNER JOIN managers
USING(playerid, yearid, lgid)





--10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

--Leson Cruz had the most home runs in 2016

SELECT namefirst, namelast, (finalgame::TIMESTAMP-debut::TIMESTAMP) AS days_played, yearID, MAX(hr) AS max_hr_in_a_year
FROM people
INNER JOIN batting
USING(playerid)
	WHERE yearID = 2016
	AND (finalgame::TIMESTAMP-debut::TIMESTAMP) >= interval '3650 days'
GROUP BY namefirst, namelast, yearID, days_played
HAVING MAX(hr) > 1
ORDER BY max_hr_in_a_year DESC;

select * from batting









--bonus

WITH throw AS 
(SELECT DISTINCT p.playerid, pi.so, p.throws
FROM people AS p
INNER JOIN pitching AS pi
USING(playerid))

SELECT COUNT(*) FROM throw WHERE 



(SELECT COUNT(*) FROM perc
 WHERE wswin = 'Y')*100.0/ count(*)





--Used For Bonus Presentation
SELECT DISTINCT h.playerid, pe.fullname, h.category,h.votedby,h.yearid  --,t.name AS team_name
FROM
	(SELECT playerid,namegiven|| ' ' || namelast AS fullname, height
	 FROM people
	 ) as pe

INNER JOIN halloffame as h
USING(playerid)
WHERE h.inducted = 'Y'
and h.votedby NOT IN ('BBWAA','Run Off')
Order by h.yearid DESC



-- and votes <needed
-- and votedby = 'Veterans'
--AND category ilike'Player'
--GROUP BY h.category, pe.playerid
--ORDER BY pe.playerid DESC



SELECT DISTINCT pe.fullname, h.category,h.votedby  --,t.name AS team_name
FROM
	(SELECT playerid,namegiven|| ' ' || namelast AS fullname, height
	 FROM people
	 ) as pe

INNER JOIN halloffame as h
USING(playerid)
WHERE h.inducted = 'Y'
and h.votedby <> 'BBWAA'

select count(playerid) from halloffame
where inducted ='Y'
and votedby = 'BBWAA'




SELECT sub.playerid,sub.category,h.votedby
(SELECT distinct playerid,category, COUNT(playerid) AS notin 
 FROM halloffame
WHERE inducted = 'N'
--and votedby <> 'BBWAA'
-- and votes <needed
-- and votedby = 'Veterans'
--AND category ilike'Player'
GROUP BY category, playerid
ORDER BY COUNT(playerid) DESC
) sub
INNER JOIN halloffame as h
USING(playerid)
WHERE h.inducted = 'Y'
and h.votedby <> 'BBWAA'
 
 
 
 
 Select playerid, 
 
 
	

Select playerid, sub.fullname from
 (SELECT playerid,namegiven|| ' ' || namelast AS fullname from people
	)sub
INNER JOIN halloffame as h
USING(playerid)
WHERE h.inducted = 'Y'
and h.votedby <> 'BBWAA'
 
 
 
 
 
select names.fullname,playerid,category--,COUNT(playerid) AS notin ,
FROM people AS pe
inner join halloffame AS h
USING(playerid)
WHERE inducted = 'N'
--AND category ilike'Player'
GROUP BY category, playerid
ORDER BY COUNT(playerid)
	
	
	
	
select yearid, playerid,category
FROM halloffame
WHERE inducted = 'N'
and inducted = 'Y'

SELECT DISTINCT(votedby) FROM halloffame
WHERE inducted = 'Y'
and votedby <> 'BBWAA'



select * from appearances
where playerid = 'roushed01'

SELECT * FROM halloffame
WHERE playerid = 'roushed01'
WHERE playerid = 'youngro01'
order by yearid

select playerid throws  from people
order by throws

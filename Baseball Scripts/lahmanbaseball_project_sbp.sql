SELECT *
FROM pitching;

SELECT *
FROM teams;

--everything above this is notes, looking at tables, etc.

--Question 1. What range of years for baseball games played does the provided database cover?
SELECT MIN(yearid) AS first_year, MAX(yearid) AS last_year
FROM teams;
--OR
SELECT
	MIN(Year),
	MAX(YEAR),
	MAX(year) - MIN(Year) AS year_range
FROM homegames;

--Answer: The database covers games played from 1871 to 2016.


--Question 2. Find the name and height of the shortest player in the database. 
--How many games did he play in? What is the name of the team for which he played?
SELECT DISTINCT pe.fullname, pe.height, a.g_all AS games_played,t.name AS team_name  --a.team_id
FROM
	(SELECT playerid,namegiven|| ' ' || namelast AS fullname, height
	 FROM people
	 ORDER BY height
	 LIMIT 1) as pe
	
LEFT JOIN appearances AS a
USING(playerid)
LEFT JOIN teams AS t
ON a.teamid = t.teamid;

--Answer: Edward Carl Gaedel was the shortest player in the database at a height of 43 inches.
--He played in one game for the St. Louis Browns.


--Question 3. Find all players in the database who played at Vanderbilt University. 
--Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues.
--Sort this list in descending order by the total salary earned. 
--Which Vanderbilt player earned the most money in the majors?
WITH school_name AS (
		SELECT DISTINCT playerid, schoolname, namefirst, namelast
		FROM people
		INNER JOIN collegeplaying
		USING(playerid)
		INNER JOIN schools
		USING(schoolid)
		WHERE schoolname ILIKE '%Vander%'
		ORDER BY schoolname)

SELECT people.namefirst, people.namelast, COALESCE(SUM(salaries.salary),0)::NUMERIC::MONEY AS total_salary
FROM people
INNER JOIN salaries
USING(playerid)
INNER JOIN school_name
USING(playerid)
GROUP BY people.namefirst, people.namelast
ORDER BY total_salary DESC;

--Answer: David Price is the Vanderbilt alumni who went on to earn the most in the major leagues.


--Question 4. Using the fielding table, group players into three groups based on their position: 
--label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
--Determine the number of putouts made by each of these three groups in 2016.
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

--Answer: The infield had 58,934 putouts, the outfield had 29,560 putouts, and players labeled battery had 41,424 putouts.


--Question 5. Find the average number of strikeouts per game by decade since 1920. 
--Round the numbers you report to 2 decimal places. 
--Do the same for home runs per game. Do you see any trends?
SELECT ROUND(1.0*SUM(teams.so)/SUM(teams.g),2)
		AS avg_strikeouts_per_game,
	ROUND(1.0*SUM(teams.hr)/SUM(teams.g),2) AS avg_homeruns_per_game,
	CONCAT(LEFT(CAST(teams.yearid AS VARCHAR), 3), '0') AS decade
FROM teams
WHERE teams.yearid >= 1920
GROUP BY CONCAT(LEFT(CAST(teams.yearid AS VARCHAR), 3), '0')
ORDER BY decade;

--Answer: The number of both strikeouts and homeruns have, generally, risen over the years since 1920.


--Question 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured 
--as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a 
--stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
SELECT people.namefirst || ' ' || people.namelast AS full_name,
		sb AS stolen_bases,
		cs AS caught_stealing,
	ROUND(SUM(batting.sb) / (SUM(batting.sb) + SUM(batting.cs))::NUMERIC * 100, 2)||'%' AS successful_steals
FROM batting
INNER JOIN people
ON batting.playerid = people.playerid
WHERE batting.yearid = 2016
GROUP BY people.namefirst, people.namelast, stolen_bases, caught_stealing
HAVING batting.sb >= 20
ORDER BY successful_steals DESC;

--Answer: See query


--Question 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 
--What is the smallest number of wins for a team that did win the world series? 
--Doing this will probably result in an unusually small number of wins for a world series champion – 
--determine why this is the case. Then redo your query, excluding the problem year. 
--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 
--What percentage of the time?
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
 FROM perc;

--Answer: Roughly 23%


--Question 8. Using the attendance figures from the homegames table, find the teams and parks which had the 
--top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided 
--by number of games). Only consider parks where there were at least 10 games played. Report the park name, 
--team name, and average attendance. Repeat for the lowest 5 average attendance.
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
LIMIT 5;
--Bottom 5
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

--Answer: see query


--Question 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and 
--the American League (AL)? Give their full name and the teams that they were managing when they won the award.
SELECT people.namefirst || ' ' || people.namelast AS full_name, teams.name, teams.lgid, awardsmanagers.yearid
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

--SELECT *
--FROM awardsmanagers
--WHERE playerid = 'coxbo01';

--Answer: Jim Leland and Davey Johnson both won the TSN Manager of the Year Award in both the AL and Nl leagues. 
--Jim Leyland won in the NL with the Pittsburgh Pirates, and he won in the AL with the Detroit Tigers. 
--Davey Johnson won in the NL with the Washington Nationals, and he won in the AL with the Baltimore ORIOLES (the best team).


--Question 10.Find all players who hit their career highest number of home runs in 2016. 
--Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
--Report the players' first and last names and the number of home runs they hit in 2016.
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

--Answer: see query
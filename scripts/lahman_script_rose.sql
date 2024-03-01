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
	

--7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?116 wins What is the smallest number of wins for a team that did win the world series?63 Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. 83 How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


--excluding 1981 since the season was split into 2 halves. they lost 2 monhs of the regular season, hence,they played a fewer number of games so their score overall will be lower compared to any other year.


--most wins of team that did not win the world series
SELECT teamid,yearid
		,MAX(w) AS mostwins		
FROM teams
WHERE yearid BETWEEN '1970' and '2016' 
AND wswin = 'N'
GROUP BY teamid,yearid
ORDER BY 
mostwins DESC
LIMIT 1


--least wins of team that won the world series
SELECT teamid, yearid
		, MIN(w) AS leastwins
	
FROM teams
WHERE yearid BETWEEN '1970' and '2016' 
AND yearid <> 1981
AND wswin = 'Y'
GROUP BY teamid, yearid
ORDER BY leastwins 

--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series
SELECT teamid,yearid
		,MAX(w) AS mostwins	
		--,COUNT(MAX(w))
FROM teams
WHERE yearid BETWEEN '1970' and '2016' 
AND wswin = 'Y'
GROUP BY teamid,yearid
ORDER BY 
mostwins DESC



--8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


--9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

--10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
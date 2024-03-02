
-- 1. What range of years for baseball games played does the provided database cover? 
SELECT
	MIN(Year),
	MAX(YEAR),
	MAX(year) - MIN(Year) AS year_range
FROM homegames

--alternatively
SELECT MIN(yearid) AS first_year, MAX(yearid) AS last_year
FROM batting

-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
   
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

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH school_name AS (
		SELECT DISTINCT playerid, namefirst, namelast, schoolname
		FROM people
		INNER JOIN collegeplaying
		USING(playerid)
		INNER JOIN schools
		USING(schoolid)
		WHERE schoolname ILIKE '%Vander%'
		ORDER BY schoolname)

SELECT people.namefirst, people.namelast, COALESCE(SUM(salaries.salary),0)::NUMERIC::MONEY AS total_salary
FROM people
LEFT JOIN salaries
USING(playerid)
INNER JOIN school_name
USING(playerid)
GROUP BY people.namefirst, people.namelast
ORDER BY total_salary DESC;

--Notes: 
--I did a left join of people on salaries because I did not want to omit players whose salary data was missing. I did an inner join on school name CTE which is already filtered to only players who went to Vanderbilt. The highest paid player is David Price at $81 Million. However, there are 9 (out of 24) players with no salary data listed. 
--I also cast the salaries as Money for a cleaner look. I needed to first cast it as Numeric though becuase it was originally double precision and you cannot cast that as money directly. 
--The coalesce function replaces null values with 0's


-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

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
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?

SELECT ROUND(1.0*SUM(teams.so)/SUM(teams.g),2)
		AS avg_strikeouts_per_game,
	ROUND(1.0*SUM(teams.hr)/SUM(teams.g),2) AS avg_homeruns_per_game,
	CONCAT(LEFT(CAST(teams.yearid AS VARCHAR), 3), '0') AS decade
FROM teams
WHERE teams.yearid >= 1920
GROUP BY CONCAT(LEFT(CAST(teams.yearid AS VARCHAR), 3), '0')
ORDER BY decade;


-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.
	

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?


-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT * FROM homegames LIMIT 10
SELECT * FROM parks LIMIT 10
SELECT * FROM teams LIMIT 10

SELECT COUNT(DISTINCT park) FROM homegames
SELECT COUNT(DISTINCT team) FROM homegames
SELECT * FROM homegames WHERE games<10
--there are 249 unique parks and 148 unique teams in homegames table

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

--number of teams associated with each park
SELECT 
	parks.park_name, 
	COUNT(teams.name) AS num_of_teams,
	SUM(homegames.attendance)/SUM(homegames.games) AS avg_att
FROM parks
JOIN homegames
USING(park)
JOIN teams
ON homegames.team = teams.teamid
GROUP BY parks.park_name
ORDER BY num_of_teams DESC
LIMIT 20; 


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

SELECT namefirst, namelast, (finalgame::TIMESTAMP-debut::TIMESTAMP) AS days_played, yearID, MAX(hr) AS max_hr_in_a_year
FROM people
INNER JOIN batting
USING(playerid)
	WHERE yearID = 2016
	AND (finalgame::TIMESTAMP-debut::TIMESTAMP) >= interval '3650 days'
GROUP BY namefirst, namelast, yearID, days_played
HAVING MAX(hr) > 1
ORDER BY max_hr_in_a_year DESC;
--There are 75 players who played for over 10 years that peaked in homeruns in 2016. Nalson Cruz has the highest number with 43 homeruns that year. 

--just because I was curious I also identified who had the highest total number of homeruns across all years was Frank Thomas. However a quick google search claims a differnt number so this data might be incorrect. Barry Bonds is the real top homerun hitter (according to Wiki)
SELECT namefirst, namelast, SUM(hr) AS total_hr
FROM people
INNER JOIN batting
USING(playerid)
GROUP BY namefirst, namelast
ORDER BY total_hr DESC;

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--   *  Does there appear to be any correlation between attendance at home games and number of wins? </li>
--   *  Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?



--Solo Project
--I want to see if the teams we are all named after have stats in the database and if so lets compare how they performed
--1) List all the teams, their names, years active, city, etc
--Teams: Orioles, Mets, Dodgers, Padres, Cubs, Braves
--I can't use an IN statement because you cannot combine a LIKE statement with an IN list. So I made the following query:
SELECT DISTINCT teams.name
FROM teams
WHERE teams.name ILIKE '%Orioles%'
	OR teams.name ILIKE '%Mets%'
	OR teams.name ILIKE '%Dodgers%'
	OR teams.name ILIKE '%Padres%'
	OR teams.name ILIKE '%Cubs%'
	OR teams.name ILIKE '%Braves%'
ORDER BY teams.name;

--I got the following list:
-- "Atlanta Braves"
-- "Baltimore Orioles"
-- "Boston Braves"
-- "Brooklyn Dodgers"
-- "Chicago Cubs"
-- "Los Angeles Dodgers"
-- "Milwaukee Braves"
-- "New York Mets"
-- "San Diego Padres"

--Ola made the point that some of these may be franchises that were bought up and moved cities, so I made a query to look at the years they were active to determine if I should include their stats together
SELECT DISTINCT teams.name, MIN(teams.yearID), MAX(teams.yearID)
FROM teams
WHERE teams.name ILIKE '%Dodgers%'
	OR teams.name ILIKE '%Braves%'
GROUP BY teams.name
ORDER BY MAX(teams.yearID)

--It looks like the Braves started in Boston in 1912, then changed to Milwaukee in 1953, then again moved to Atlanta in 1966; Likewise, the dodgers started in Brooklyn in 1911 but moved to LA in 1958

--I updated my query to loka t date ranges the teams were active. Since the latest debut date for a team in this list is 1969 (the Padres), all my queries will look only at data from 1970 onward. 
SELECT DISTINCT teams.name,  MIN(teams.yearID), MAX(teams.yearID), MAX(teams.yearID)-MIN(teams.yearID) AS years_active
FROM teams
WHERE teams.name ILIKE '%Orioles%'
	OR teams.name ILIKE '%Mets%'
	OR teams.name ILIKE '%Dodgers%'
	OR teams.name ILIKE '%Padres%'
	OR teams.name ILIKE '%Cubs%'
	OR teams.name ILIKE '%Braves%'
GROUP BY teams.name
ORDER BY MIN(teams.yearID) DESC;


--2) List wins/losses for each team
--3) 





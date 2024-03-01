
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
		SELECT playerid, schoolname, namefirst, namelast
		FROM people
		INNER JOIN collegeplaying
		USING(playerid)
		INNER JOIN schools
		USING(schoolid)
		WHERE schoolname ILIKE '%Vander%'
		GROUP BY schoolname, namelast, namefirst, playerid
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




-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.
--   *  Does there appear to be any correlation between attendance at home games and number of wins? </li>
--   *  Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?

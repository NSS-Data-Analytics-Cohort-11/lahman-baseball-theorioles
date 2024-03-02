-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

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

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

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
HAVING SUM(homegames.attendance)/SUM(homegames.games) > 1
ORDER BY avg_att 
LIMIT 20; 


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

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
INNER JOIN managers ON people.playerid = managers.playerid
INNER JOIN teams ON managers.teamid = teams.teamid
WHERE awardid = 'TSN Manager of the Year'
	AND awardsmanagers.lgid IN('NL', 'AL')
	AND awardsmanagers.yearid = managers.yearid
	AND teams.yearid = managers.yearid;

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
--There are 75 players who played for over 10 years that peaked in homeruns in 2016. Nelson Cruz has the highest number with 43 homeruns that year. 

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

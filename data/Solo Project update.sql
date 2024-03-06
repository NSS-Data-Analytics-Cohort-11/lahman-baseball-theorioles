--Solo Project
--I wanted my project to focus on the teams our class teams were named after. I identified the teams in the data abse and then explored metrics related to: Popularity (via home game attedance), # of Wins vs. Losses, and Best Players (Hall of Famers, best pitchers, batters, and stealers)

--1) Identify all the teams and their years of activity. I want to compare apples to apples, so I need to determine a time frame all the teams were active at the same time. 

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

--It looks like the Braves started in Boston in 1912, then changed to Milwaukee in 1953, then again moved to Atlanta in 1966; Likewise, the dodgers started in Brooklyn in 1911 but moved to LA in 1958. I created a graphic to illustrate the change in location for the same team franchise over time. 

--I updated my query to look at date ranges the teams were active. Since the latest debut date for a team in this list is 1969 (the Padres), all my queries will look only at data from 1970 onward. 
SELECT DISTINCT teams.name,  MIN(teams.yearID), MAX(teams.yearID), MAX(teams.yearID)-MIN(teams.yearID)+1 AS years_active
FROM teams
WHERE teams.name ILIKE '%Orioles%'
	OR teams.name ILIKE '%Mets%'
	OR teams.name ILIKE '%Dodgers%'
	OR teams.name ILIKE '%Padres%'
	OR teams.name ILIKE '%Cubs%'
	OR teams.name ILIKE '%Braves%'
GROUP BY teams.name
ORDER BY MIN(teams.yearID) DESC;

--2) Explore popularity of teams via home game attendance

--First I built on the above query as a CTE, adding a filter to only show active teams: 
WITH class_teams AS (
	SELECT DISTINCT teams.name
	FROM teams
	INNER JOIN teamsfranchises
	ON teams.name = teamsfranchises.franchname
	WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') 
		AND teamsfranchises.active = 'Y'
	ORDER BY teams.name)

--This query shows the number of stadiums associated with each active team: 
WITH class_teams AS (
	SELECT DISTINCT teams.name
	FROM teams
	INNER JOIN teamsfranchises
	ON teams.name = teamsfranchises.franchname
	WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') 
		AND teamsfranchises.active = 'Y'
	ORDER BY teams.name)
	
SELECT DISTINCT class_teams.name, COUNT(DISTINCT park)
FROM teams
INNER JOIN class_teams
USING(name)
GROUP BY class_teams.name
ORDER BY COUNT(DISTINCT park) DESC

--This one shows the most recent park associated with each team: 
WITH class_teams AS (
	SELECT DISTINCT teams.name
	FROM teams
	INNER JOIN teamsfranchises
	ON teams.name = teamsfranchises.franchname
	WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') 
		AND teamsfranchises.active = 'Y'
	ORDER BY teams.name)
	
SELECT DISTINCT class_teams.name, park
FROM teams
INNER JOIN class_teams
USING(name)
GROUP BY class_teams.name, park
HAVING MAX(yearID) = '2016'
ORDER BY class_teams.name 

--Here is a query that filters the parks table by only the stadiums most recently associated with each team
SELECT DISTINCT parks.park_name
FROM parks WHERE park_name IN('Turner Field', 'Oriole Park at Camden Yards', 'Wrigley Field', 'Dodger Stadium', 'Citi Field', 'PETCO Park') ORDER BY park_name 

--This query shows the total and average attendance of home games between 1970-2016
WITH class_teams AS (
	SELECT DISTINCT teams.name
	FROM teams
	INNER JOIN teamsfranchises
	ON teams.name = teamsfranchises.franchname
	WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') 
		AND teamsfranchises.active = 'Y'
	ORDER BY teams.name)
	
SELECT DISTINCT class_teams.name, SUM(attendance) AS total_home_att, ROUND(AVG(attendance)::decimal/((2016-1970)+1),2) as avg_home_att
FROM teams
INNER JOIN class_teams
USING(name)
WHERE yearID >=1970
GROUP BY class_teams.name
ORDER BY avg_home_att DESC

--checking my work for null values to make sure attendance figures are accurate:
SELECT * FROM teams WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') AND attendance IS NULL ORDER BY yearid
--note there are ten records that have null attendance (but all are Oriole games before 1900, so they shouldn't affect the snapshot we are looking at above between 1970-2016)

--This additional query looks at attendance by homegames table instead of teams. The numbers are slightly different but close enough for statistical pruposes (the order remains the same in both queries). I chose this data set for the graph in my presentation. 
WITH class_teams AS (
	SELECT DISTINCT teams.name, teams.teamid
	FROM teams
	INNER JOIN teamsfranchises
	ON teams.name = teamsfranchises.franchname
	WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') 
		AND teamsfranchises.active = 'Y'
	ORDER BY teams.name)
	
SELECT DISTINCT class_teams.name, SUM(homegames.attendance) AS total_home_att, ROUND(AVG(homegames.attendance)::decimal/((2016-1970)+1),2) as avg_home_att
FROM homegames
INNER JOIN class_teams
ON class_teams.teamid = homegames.team
WHERE homegames.year >=1970
GROUP BY class_teams.name
ORDER BY avg_home_att DESC

--3) Wins Vs. Losses 
--This query shows what percentage of games were wins vs. losses for each team over the entire timespan (1970-2016), it also shows the number of times each team won their division, wildcard, league, and world series games
SELECT teams.name, 
	ROUND(SUM(w)::decimal/(SUM(w)::decimal+SUM(l)::decimal)*100, 2) AS percent_wins, 
	ROUND(SUM(l)::decimal/(SUM(w)::decimal+SUM(l)::decimal)*100, 2) AS percent_losses, 
	SUM(CASE WHEN divwin ='Y' THEN 1 ELSE 0 END) AS division_wins,
	SUM(CASE WHEN wcwin ='Y' THEN 1 ELSE 0 END) AS wildcard_wins,
	SUM(CASE WHEN lgwin ='Y' THEN 1 ELSE 0 END) AS leaguechamp_wins,
	SUM(CASE WHEN wswin ='Y' THEN 1 ELSE 0 END) AS worldseries_wins
FROM teams
WHERE teams.yearid BETWEEN 1970 AND 2016 AND teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles')
GROUP BY teams.name
ORDER BY percent_wins DESC
		  
-- DivWin         Division Winner (Y or N)
-- WCWin          Wild Card Winner (Y or N)
-- LgWin          League Champion(Y or N)
-- WSWin          World Series Winner (Y or N)



--This query confirms that there were no post season ties between 1970 and 2016
SELECT SUM(ties) FROM seriespost WHERE yearid BETWEEN 1970 AND 2016 


--What about wins/losses against the other 5 teams? 
--How did they rank in postseason (on average)? 
--How many postseason wins/losses?
--How many times did each team play against each other in postseason? How many wins/losses there?



--4) Teams with the best players
--Count the number of Hall of Famers that played on each team at any point in their career. Remember to only count players inducted 1970 or later

WITH class_teams AS (
	SELECT DISTINCT teams.name, teams.teamid
	FROM teams
	INNER JOIN teamsfranchises
	ON teams.name = teamsfranchises.franchname
	WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') 
		AND teamsfranchises.active = 'Y'
	ORDER BY teams.name)

SELECT class_teams.name AS team, COUNT(DISTINCT playerid) AS hall_of_famers FROM (SELECT playerid, people.namefirst || ' ' || people.namelast AS full_name, halloffame.category, halloffame.inducted, class_teams.name, class_teams.teamid, halloffame.yearid
FROM people
INNER JOIN halloffame USING(playerid)
INNER JOIN appearances USING(playerid)
INNER JOIN class_teams USING(teamid)
WHERE inducted = 'Y' AND category ILIKE 'player' AND halloffame.yearid >=1970
ORDER BY class_teams.name) as names_of_player_halloffamers
INNER JOIN class_teams USING(teamid)
GROUP BY class_teams.name
ORDER BY COUNT(DISTINCT playerid) DESC

--give the full list of names including teams they played for and what was thier year of induction
WITH class_teams AS (
	SELECT DISTINCT teams.name, teams.teamid
	FROM teams
	INNER JOIN teamsfranchises
	ON teams.name = teamsfranchises.franchname
	WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') 
		AND teamsfranchises.active = 'Y'
	ORDER BY teams.name)

SELECT DISTINCT playerid, full_name, class_teams.name AS teams_played_for, yearid AS year_inducted FROM (SELECT playerid, people.namefirst || ' ' || people.namelast AS full_name, halloffame.category, halloffame.inducted, class_teams.name, class_teams.teamid, halloffame.yearid
FROM people
INNER JOIN halloffame USING(playerid)
INNER JOIN appearances USING(playerid)
INNER JOIN class_teams USING(teamid)
WHERE inducted = 'Y' AND category ILIKE 'player' AND halloffame.yearid >=1970
ORDER BY class_teams.name) as names_of_player_halloffamers
INNER JOIN class_teams USING(teamid)
ORDER BY playerid


	

--average number of games per year, per team is about 162
SELECT name AS team_name, yearid AS year, g AS games
FROM teams
WHERE yearid BETWEEN 1970 AND 2016 AND name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles')
ORDER BY team_name, yearid
 

--The number of hall of fame players inducted each year since 1970
SELECT halloffame.yearid, COUNT(halloffame.playerid) FROM halloffame WHERE inducted = 'Y' AND category ILIKE '%player%' AND halloffame.yearid >=1970 GROUP BY halloffame.yearid ORDER BY yearid DESC
--the exact players inducted each year
WITH induction_year AS (SELECT DISTINCT halloffame.playerid, halloffame.yearid FROM halloffame WHERE inducted = 'Y' AND category ILIKE '%player%' AND halloffame.yearid >=1970)
	
SELECT people.playerid, people.namefirst || ' ' || people.namelast AS full_name, induction_year.yearid AS year_of_induction			
FROM induction_year
LEFT JOIN people 
USING(playerid) 
ORDER BY year_of_induction DESC

--List of categories (and their counts) in the hall of fame table:
SELECT category, COUNT(halloffame.category) FROM halloffame GROUP BY category



--Other fun facts:

--The Orioles are the 3rd longest running team in the database. 
SELECT DISTINCT teams.name,  MIN(teams.yearID), MAX(teams.yearID), MAX(teams.yearID)-MIN(teams.yearID)+1 AS years_active
FROM teams
GROUP BY teams.name
ORDER BY years_active DESC;

--Also, 40 out of 139 teams were only active for one year! Most of these were before 1900 and all but one were before 1916 
SELECT DISTINCT teams.name, MIN(teams.yearID), MAX(teams.yearID), MAX(teams.yearID)-MIN(teams.yearID)+1 AS years_active
FROM teams
GROUP BY teams.name
HAVING MAX(teams.yearID)-MIN(teams.yearID)+1 <=1
AND MAX(teams.yearID) >=1900
ORDER BY MAX(teams.yearID) DESC;


--Just for refernce, these are the hall of famers associated with each team that were NOT inducted under the player category. All 5 are managers
WITH class_teams AS (
	SELECT DISTINCT teams.name, teams.teamid
	FROM teams
	INNER JOIN teamsfranchises
	ON teams.name = teamsfranchises.franchname
	WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') 
		AND teamsfranchises.active = 'Y'
	ORDER BY teams.name)

SELECT DISTINCT full_name, category, name AS teams_played_for, yearid AS year_inducted FROM (SELECT people.namefirst || ' ' || people.namelast AS full_name, halloffame.category, halloffame.inducted, class_teams.name, halloffame.yearid
FROM people
INNER JOIN halloffame USING(playerid)
INNER JOIN appearances USING(playerid)
INNER JOIN class_teams USING(teamid)
WHERE inducted = 'Y' AND category NOT ILIKE 'player' AND halloffame.yearid >=1970
ORDER BY class_teams.name) as names_of_nonplayer_halloffamers
ORDER BY yearid DESC






--Solo Project
--I want to see if the teams we are all named after have stats in the database and if so lets explore that

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

--2) Explore facts about the teams 

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

--This query shows the total and average attendance of home games between 1970-2016
WITH class_teams AS (
	SELECT DISTINCT teams.name
	FROM teams
	INNER JOIN teamsfranchises
	ON teams.name = teamsfranchises.franchname
	WHERE teams.name IN('San Diego Padres','Atlanta Braves','New York Mets','Los Angeles Dodgers','Chicago Cubs','Baltimore Orioles') 
		AND teamsfranchises.active = 'Y'
	ORDER BY teams.name)
	
SELECT DISTINCT class_teams.name, SUM(attendance) AS total_home_att, AVG(attendance)::integer as avg_home_att
FROM teams
INNER JOIN class_teams
USING(name)
WHERE yearID >=1970
GROUP BY class_teams.name
ORDER BY avg_home_att DESC



--3) 



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




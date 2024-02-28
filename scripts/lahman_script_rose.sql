--1. What range of years for baseball games played does the provided database cover? 
SELECT MIN(yearid) AS first_year, MAX(yearid) AS last_year
FROM batting
  --Answer 1871-2016


--2. Find the name and height of the shortest player in the database. "Edward Carl Gaedel" height 43 
--How many games did he play in? What is the name of the team for which he played?
SELECT * FROM people order by height


SELECT DISTINCT pe.fullname, pe.height, a.g_all AS games_played--,a.team_id--,t.name AS team_name,
FROM
	(SELECT playerid,namegiven|| ' ' || namelast AS fullname, height
	 FROM people
	 ORDER BY height
	 LIMIT 1) as pe
	 
left JOIN appearances AS a
USING(playerid)
left JOIN teams AS t
ON a.teamid = t.teamid
--WHERE pe.height IS NOT NULL
--ORDER BY pe.height 
--LIMIT 1
select * from appearances
--order by playerid
where playerid ilike'g%'
order by playerid

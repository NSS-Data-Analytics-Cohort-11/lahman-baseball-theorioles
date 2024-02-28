


--Question 1. What range of years for baseball games played does the provided database cover?

--Answer:


--Question 2. Find the name and height of the shortest player in the database. 
--How many games did he play in? What is the name of the team for which he played?

--Answer:


--Question 3. Find all players in the database who played at Vanderbilt University. 
--Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues.
--Sort this list in descending order by the total salary earned. 
--Which Vanderbilt player earned the most money in the majors?

--Answer:


--Question 4. Using the fielding table, group players into three groups based on their position: 
--label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
--Determine the number of putouts made by each of these three groups in 2016.

--Answer:


--Question 5. Find the average number of strikeouts per game by decade since 1920. 
--Round the numbers you report to 2 decimal places. 
--Do the same for home runs per game. Do you see any trends?
SELECT pitching.so AS strikeouts, pitching.g AS games, 
	CAST(FLOOR(CAST(pitching.yearid AS INT)/ 10) * 10 AS INT) AS decade
FROM pitching;
--note: leaving this like this because I keep messing it up
--Answer:
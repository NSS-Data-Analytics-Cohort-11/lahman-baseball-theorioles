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

SELECT people.namefirst, people.namelast, SUM(salaries.salary)::NUMERIC::MONEY AS total_salary
FROM people
LEFT JOIN salaries
USING(playerid)
INNER JOIN school_name
USING(playerid)
GROUP BY people.namefirst, people.namelast
ORDER BY total_salary DESC;

--Notes: 
--I did a left join of people on salaries because I did not want to omit players whose salary data was missing. I did an inner join on school name CTE which is already filtered to only players who went to Vanderbilt. The highest paid player is David Price at $81 Million. However, there are 9 (out of 24) palyers with no salary data listed. 
--I also cast the salaries as Money for a cleaner look. I needed to first cast it as numeric though becuase it was originally double precision and you cannot cast that as money directly. 

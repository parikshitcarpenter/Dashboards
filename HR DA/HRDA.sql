SHOW DATABASES;
CREATE DATABASE hr2;
USE hr2;
SELECT * FROM hr;

-- data cleaning and preprocessing --
ALTER TABLE hr
CHANGE COLUMN ï»¿id emp_id VARCHAR(20) NULL;

DESCRIBE hr;
SELECT birthdate, hire_date, termdate FROM hr;

SET sql_safe_updates = 0; -- Disabling safe update mode
-- When safe updates mode is enabled, it prevents certain potentially 
-- dangerous update and delete operations that don't include a key constraint in the WHERE clause.
-- So enabling it can be risky because it may result in unintended changes to data if executed carelessly. 

UPDATE hr
SET birthdate = CASE 
				WHEN birthdate LIKE '%/%' THEN DATE_FORMAT(str_to_date(birthdate, '%m/%d/%Y'),'%Y-%m-%d')
                WHEN birthdate LIKE '%-%' THEN DATE_FORMAT(str_to_date(birthdate, '%m-%d-%Y'),'%Y-%m-%d')
                ELSE NULL
				END;

SELECT * FROM hr;

ALTER TABLE hr
MODIFY COLUMN birthdate DATE;

-- Change the date format and datatype of hire_date column
SELECT * FROM hr;

UPDATE hr
SET hire_date = CASE
			WHEN hire_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(hire_date,'%m/%d/%Y'),'%Y-%m-%d')
            WHEN hire_date LIKE '%-%' THEN DATE_FORMAT(STR_TO_DATE(hire_date,"%m-%d-%Y"),'%Y-%m-%d')
            ELSE NULL
				END;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

-- Change the date format and datatype of termdate column
UPDATE hr
SET termdate = DATE(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate != "";

UPDATE hr
SET termdate = NULL
WHERE termdate = '';

-- Create age column
ALTER TABLE hr
ADD column age INT;

UPDATE hr
SET age = timestampdiff(YEAR, birthdate, curdate());

SELECT min(age), max(age) FROM hr;

-- 1. What is the gender breakdown of employees in the company
SELECT gender, COUNT(*) `curr_emp_count` 
FROM hr 
WHERE termdate IS NULL 
GROUP BY 1;

-- 2. What is the race breakdown of employees in the company
SELECT race, count(*) AS 'curr_emp_count' 
FROM hr 
WHERE termdate IS NULL 
GROUP BY 1;

-- 3. What is the age distribution of employees in the company
SELECT CASE
		WHEN age>=18 AND age<=24 THEN '18-24'
        WHEN age>=25 AND age<=34 THEN '25-34'
        WHEN age>=35 AND age<=44 THEN '35-44'
        WHEN age>=45 AND age<=54 THEN '45-54'
        WHEN age>=55 AND age<=64 THEN '55-64'
        ELSE '65+'
        END AS age_group,
COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY age_group
ORDER BY age_group;

-- 4. How many employees work at HQ vs remote
SELECT location, COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY location;

-- 5. What is the average length of employement who have been terminated.
SELECT ROUND(AVG(YEAR(termdate)-YEAR(hire_date)),0) `len_of_emp` 
FROM hr 
WHERE termdate IS NOT NULL AND termdate<=curdate();

-- 6. How does the gender distribution vary across dept. and job titles

SELECT department, jobtitle, gender, count(*) AS count
FROM hr 
WHERE termdate IS NOT NULL
GROUP BY 1,2,3
ORDER BY 1,2,3;

SELECT department, gender, COUNT(*) AS count
FROM hr
WHERE termdate IS NOT NULL
GROUP BY department, gender
ORDER BY department, gender;

-- 7. What is the distribution of jobtitles across the company
SELECT jobtitle, COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY jobtitle;

-- 8. Which department has the highest turnover/termination rate
SELECT department, COUNT(*) AS total_count, 
	COUNT(
    CASE
		WHEN termdate IS NOT NULL AND termdate<=curdate() THEN 1
	END) terminated_count,
	ROUND(COUNT(
    CASE
		WHEN termdate IS NOT NULL AND termdate<=curdate() THEN 1
	END)/COUNT(*)*100,2) AS termination_rate
FROM hr 
GROUP BY 1 
ORDER BY 4 DESC;

-- 9. What is the distribution of employees across location_state
SELECT location_state, COUNT(*) AS count 
FROM hr
WHERE termdate IS NULL
GROUP BY 1;

SELECT location_city, COUNT(*) AS count
FROM hr
WHERE termdate IS NULL
GROUP BY 1;

-- 10. How has the companys employee count changed over time based on hire & termination date.
SELECT * FROM hr;

SELECT year, hires, terminations, hires-terminations AS net_change, 
CONCAT(ROUND((terminations/hires)*100,1),"%") AS change_percent
FROM (SELECT YEAR(hire_date) `year`, COUNT(hire_date) `hires`, 
COUNT(CASE WHEN termdate IS NOT NULL AND termdate<=curdate() THEN 1 END) AS terminations 
FROM hr 
GROUP BY 1
ORDER BY 1) subquery
GROUP BY 1
ORDER BY 1;

-- 11. What is the tenure distribution for each dept. #length of time an employee has been continuously employed by a company or organization
SELECT department, ROUND(AVG(datediff(termdate, hire_date)/365),0) `avg_tenure` 
FROM hr
WHERE termdate IS NOT NULL AND termdate<= curdate()
GROUP BY department;
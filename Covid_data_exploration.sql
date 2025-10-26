SELECT *
FROM covid_project.coviddeaths
WHERE continent != "";

-- Change date from txt to date format

CREATE TABLE coviddeaths_edit
LIKE coviddeaths;

INSERT INTO coviddeaths_edit
SELECT *
FROM coviddeaths;

SELECT date, STR_TO_DATE(date, '%m/%d/%Y')
FROM coviddeaths_edit;

UPDATE coviddeaths_edit
SET date = STR_TO_DATE(date, '%m/%d/%Y');

SELECT *
FROM coviddeaths_edit;

CREATE TABLE covidvaccinations_edit
LIKE covidvaccinations;

INSERT INTO covidvaccinations_edit
SELECT *
FROM covidvaccinations;

UPDATE covidvaccinations_edit
SET date = STR_TO_DATE(date, '%m/%d/%Y');



-- Select data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_project.coviddeaths_edit
WHERE continent != ""
ORDER BY 3,4;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percent
FROM covid_project.coviddeaths_edit
WHERE continent != ""
ORDER BY 1,2;

CREATE VIEW DeathByCasesPercent AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percent
FROM covid_project.coviddeaths_edit
WHERE continent != ""
ORDER BY 1,2;

-- Looking at data diveded by Countries

WITH stats_by_country AS
(
SELECT location, population, MAX(CAST(total_cases AS SIGNED)) AS total_case_count, MAX(CAST(total_deaths AS SIGNED)) AS total_death_count
FROM covid_project.coviddeaths_edit
WHERE continent != ""
GROUP BY location, population
ORDER BY total_case_count DESC
)
SELECT *, (total_death_count/total_case_count)*100 AS death_percent_by_cases, 
(total_death_count/population)*100 AS death_percent_by_population
FROM stats_by_country;

CREATE VIEW stats_by_country AS
WITH stats_by_country AS
(
SELECT location, population, MAX(CAST(total_cases AS SIGNED)) AS total_case_count, MAX(CAST(total_deaths AS SIGNED)) AS total_death_count
FROM covid_project.coviddeaths_edit
WHERE continent != ""
GROUP BY location, population
ORDER BY total_case_count DESC
)
SELECT *, (total_death_count/total_case_count)*100 AS death_percent_by_cases, 
(total_death_count/population)*100 AS death_percent_by_population
FROM stats_by_country;

-- Showing worst dates per country by the number of new cases and new deaths

SELECT location, date, CAST(new_cases AS SIGNED) AS cases, CAST(new_deaths AS SIGNED) AS deaths,
RANK() OVER(
	PARTITION BY location
	ORDER BY CAST(new_cases AS SIGNED) DESC) AS rank_in_location
FROM covid_project.coviddeaths_edit
WHERE continent != "";


WITH worst_date_cases AS
(
SELECT location, date, CAST(new_cases AS SIGNED) AS cases, CAST(new_deaths AS SIGNED) AS deaths,
RANK() OVER(
	PARTITION BY location
	ORDER BY CAST(new_cases AS SIGNED) DESC, date) AS rank_cases
FROM covid_project.coviddeaths_edit
WHERE continent != ""
)
SELECT location, date, cases, rank_cases
FROM worst_date_cases
WHERE rank_cases = 1;

DROP TABLE IF EXISTS temp_worst_date_cases;
CREATE TEMPORARY TABLE temp_worst_date_cases AS
WITH worst_date_cases AS
(
SELECT location, date, CAST(new_cases AS SIGNED) AS cases,
RANK() OVER(
	PARTITION BY location
	ORDER BY CAST(new_cases AS SIGNED) DESC, date) AS rank_cases
FROM covid_project.coviddeaths_edit
WHERE continent != "" AND new_cases != "" 
)
SELECT location, date, cases
FROM worst_date_cases
WHERE rank_cases = 1;


WITH worst_date_deaths AS
(
SELECT location, date, CAST(new_cases AS SIGNED) AS cases, CAST(new_deaths AS SIGNED) AS deaths,
RANK() OVER(
	PARTITION BY location
	ORDER BY CAST(new_deaths AS SIGNED) DESC, date) AS rank_deaths
FROM covid_project.coviddeaths_edit
WHERE continent != ""
)
SELECT location, date, deaths, rank_deaths
FROM worst_date_deaths
WHERE rank_deaths = 1;

DROP TABLE IF EXISTS temp_worst_date_deaths;
CREATE TEMPORARY TABLE temp_worst_date_deaths AS
WITH worst_date_deaths AS
(
SELECT location, date, CAST(new_deaths AS SIGNED) AS deaths,
RANK() OVER(
	PARTITION BY location
	ORDER BY CAST(new_deaths AS SIGNED) DESC, date) AS rank_deaths
FROM covid_project.coviddeaths_edit
WHERE continent != "" AND new_deaths != ""
)
SELECT location, date, deaths
FROM worst_date_deaths
WHERE rank_deaths = 1;

SELECT ca.location, ca.date AS wors_case_date, ca.cases, de.date AS wors_death_date, de.deaths
FROM temp_worst_date_cases ca
JOIN temp_worst_date_deaths de
	ON ca.location = de.location;

CREATE TABLE worst_dates AS
SELECT ca.location, ca.date AS wors_case_date, ca.cases, de.date AS wors_death_date, de.deaths
FROM temp_worst_date_cases ca
JOIN temp_worst_date_deaths de
	ON ca.location = de.location;

CREATE VIEW worst_dates_view AS 
SELECT *
FROM worst_dates;

-- global numbers

SELECT date, SUM(CAST(new_cases AS SIGNED)) AS sum_cases, SUM(CAST(new_deaths AS SIGNED)) AS sum_deaths, 
(SUM(CAST(new_deaths AS SIGNED))/SUM(CAST(new_cases AS SIGNED)))*100 as death_percent
FROM covid_project.coviddeaths_edit
WHERE continent != ""
GROUP BY date
ORDER BY death_percent DESC;

-- COVID VACCINATIONS

SELECT location, date, new_vaccinations, people_vaccinated, people_fully_vaccinated 
FROM covid_project.covidvaccinations_edit
WHERE new_vaccinations != "" OR people_vaccinated != "" OR people_fully_vaccinated != ""
ORDER BY 1, 2;

WITH infected_and_vaccinated_stats AS
(
SELECT de.location, de.date, de.new_cases, de.new_deaths, va.people_vaccinated, va.people_fully_vaccinated
FROM covid_project.coviddeaths_edit de
JOIN covid_project.covidvaccinations_edit va
	ON de.location = va.location
    AND de.date = va.date
)
SELECT *
FROM infected_and_vaccinated_stats
ORDER BY 1, 2;

CREATE VIEW infected_and_vaccinated_stats_view AS
WITH infected_and_vaccinated_stats AS
(
SELECT de.location, de.date, de.new_cases, de.new_deaths, va.people_vaccinated, va.people_fully_vaccinated
FROM covid_project.coviddeaths_edit de
JOIN covid_project.covidvaccinations_edit va
	ON de.location = va.location
    AND de.date = va.date
)
SELECT *
FROM infected_and_vaccinated_stats
ORDER BY 1, 2;

SELECT location, MAX(CAST(people_vaccinated AS SIGNED)) as vaccinated_people, 
MAX(CAST(people_fully_vaccinated AS SIGNED)) as fully_vaccinated_people
FROM covid_project.covidvaccinations_edit
GROUP BY location;

CREATE VIEW vaccinated_by_country AS
SELECT location, MAX(CAST(people_vaccinated AS SIGNED)) as vaccinated_people, 
MAX(CAST(people_fully_vaccinated AS SIGNED)) as fully_vaccinated_people
FROM covid_project.covidvaccinations_edit
GROUP BY location;





























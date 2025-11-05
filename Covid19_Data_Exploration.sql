-- Looking at all the data

SELECT * 
FROM covid19_project.covid_deaths;

SELECT * 
FROM covid19_project.covid_vaccinations;

-- Creating new tables for editing, so that the original ones stay untouched

CREATE TABLE covid_deaths_edit AS
SELECT *
FROM covid19_project.covid_deaths;

CREATE TABLE covid_vaccinations_edit AS
SELECT *
FROM covid19_project.covid_vaccinations;

-- PREPARING DATA

-- Changing all blank values to NULLs

UPDATE covid_deaths_edit
SET
	iso_code = NULLIF(iso_code, ""),
    continent = NULLIF(continent, ""),
    continent = NULLIF(continent, ""),
    `date` = NULLIF(`date`, ""),
    population = NULLIF(population, ""),
    total_cases = NULLIF(total_cases, ""),
    new_cases = NULLIF(new_cases, ""),
    new_cases_smoothed = NULLIF(new_cases_smoothed, ""),
    total_deaths = NULLIF(total_deaths, ""),
    new_deaths = NULLIF(new_deaths, ""),
    new_deaths_smoothed = NULLIF(new_deaths_smoothed, ""),
    total_cases_per_million = NULLIF(total_cases_per_million, ""),
    new_cases_per_million = NULLIF(new_cases_per_million, ""),
    new_cases_smoothed_per_million = NULLIF(new_cases_smoothed_per_million, ""),
    total_deaths_per_million = NULLIF(total_deaths_per_million, ""),
    new_deaths_smoothed_per_million = NULLIF(new_deaths_smoothed_per_million, ""),
    reproduction_rate = NULLIF(reproduction_rate, ""),
    icu_patients = NULLIF(icu_patients, ""),
    icu_patients_per_million = NULLIF(icu_patients_per_million, ""),
    hosp_patients = NULLIF(hosp_patients, ""),
    hosp_patients_per_million = NULLIF(hosp_patients_per_million, ""),
    weekly_icu_admissions = NULLIF(weekly_icu_admissions, ""),
    weekly_icu_admissions_per_million = NULLIF(weekly_icu_admissions_per_million, ""),
    weekly_hosp_admissions = NULLIF(weekly_hosp_admissions, ""),
    weekly_hosp_admissions_per_million = NULLIF(weekly_hosp_admissions_per_million, "");
    
UPDATE covid_vaccinations_edit
SET
	iso_code = NULLIF(iso_code, ""),
    continent = NULLIF(continent, ""),
    location = NULLIF(location, ""),
    `date` = NULLIF(`date`, ""),
    new_tests = NULLIF(new_tests, ""),
    total_tests = NULLIF(total_tests, ""),
    total_tests_per_thousand = NULLIF(total_tests_per_thousand, ""),
    new_tests_per_thousand = NULLIF(new_tests_per_thousand, ""),
    new_tests_smoothed = NULLIF(new_tests_smoothed, ""),
    new_tests_smoothed_per_thousand = NULLIF(new_tests_smoothed_per_thousand, ""),
    positive_rate = NULLIF(positive_rate, ""),
    tests_per_case = NULLIF(tests_per_case, ""),
    tests_units = NULLIF(tests_units, ""),
    total_vaccinations = NULLIF(total_vaccinations, ""),
    people_vaccinated = NULLIF(people_vaccinated, ""),
    people_fully_vaccinated = NULLIF(people_fully_vaccinated, ""),
    new_vaccinations = NULLIF(new_vaccinations, ""),
    new_vaccinations_smoothed = NULLIF(new_vaccinations_smoothed, ""),
    total_vaccinations_per_hundred = NULLIF(total_vaccinations_per_hundred, ""),
    people_vaccinated_per_hundred = NULLIF(people_vaccinated_per_hundred, ""),
    people_fully_vaccinated_per_hundred = NULLIF(people_fully_vaccinated_per_hundred, ""),
    new_vaccinations_smoothed_per_million = NULLIF(new_vaccinations_smoothed_per_million, ""),
    stringency_index = NULLIF(stringency_index, ""),
    population_density = NULLIF(population_density, ""),
    median_age = NULLIF(median_age, ""),
    aged_65_older = NULLIF(aged_65_older, ""),
    aged_70_older = NULLIF(aged_70_older, ""),
    gdp_per_capita = NULLIF(gdp_per_capita, ""),
    extreme_poverty = NULLIF(extreme_poverty, ""),
    cardiovasc_death_rate = NULLIF(cardiovasc_death_rate, ""),
    diabetes_prevalence = NULLIF(diabetes_prevalence, ""),
    female_smokers = NULLIF(female_smokers, ""),
    male_smokers = NULLIF(male_smokers, ""),
    handwashing_facilities = NULLIF(handwashing_facilities, ""),
    hospital_beds_per_thousand = NULLIF(hospital_beds_per_thousand, ""),
    life_expectancy = NULLIF(life_expectancy, ""),
    human_development_index = NULLIF(human_development_index, "");
    
-- Changing type for date values
UPDATE covid_deaths_edit
SET `date` = str_to_date(`date`, "%m/%d/%Y");
UPDATE covid_vaccinations_edit
SET `date` = str_to_date(`date`, "%m/%d/%Y");

-- deleting rows without continent data 
DELETE 
FROM covid_deaths_edit
WHERE continent IS NULL;

-- convert type of data from text to a numeric
ALTER TABLE covid_deaths_edit
MODIFY COLUMN total_deaths INT,
MODIFY COLUMN new_deaths INT;

/*
	Focusing first only on covid_death table
	1. taking out global numbers with percentage of cases with deadly outcome
	2. deviding by continent with percentage of cases with deadly outcome
    3. deviding by country with percentage of cases with deadly outcome and percentage of population infected, as well as those that died
	4. devided by counties, measuring percentages for every date
*/

-- 1. global numbers
	
SELECT 
	SUM(new_cases) as total_cases, 
	SUM(new_deaths) as total_deaths,
    ROUND((SUM(new_deaths) / SUM(new_cases)) * 100, 2) as death_percentage
FROM covid_deaths_edit;

-- 2. deviding by continents

SELECT 
	continent, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, 
    ROUND((SUM(new_deaths) / SUM(new_cases)) * 100, 2) as death_percentage
FROM covid_deaths_edit
GROUP BY continent;

-- 3. deviding by countries 

SELECT 
	location, population,
    MAX(total_cases) as total_cases,
    MAX(total_deaths) as total_deaths,
    ROUND((MAX(total_deaths) / MAX(total_cases)) * 100, 2) as death_case_percentage,
    ROUND((MAX(total_deaths) / population) * 100, 2) as death_population_percentage,
    ROUND((MAX(total_cases) / population) * 100, 2) as case_population_percentage
FROM covid_deaths_edit
GROUP BY location, population;

-- 4. percentages for every date

SELECT 
	location, date, population, new_cases, total_cases, new_deaths, total_deaths,
	(total_cases / population) * 100 as infected_population_percentage,
    (total_deaths / population) * 100 as deceased_population_percentage,
    (total_deaths / total_cases) * 100 as deceased_infected_percentage
FROM covid_deaths_edit
ORDER BY location, date;

/*
	Now taking in consideration vaccinations table:
    1. taking out global numbers for vaccinations
    2. vaccinated population percentage in every country
    3. with dates, putting side by side information about vaccinated population and infected population
*/	


-- quick look to check and understand data better
SELECT location, date, total_vaccinations, people_vaccinated, people_fully_vaccinated
FROM covid_vaccinations_edit
WHERE total_vaccinations IS NOT NULL OR people_vaccinated IS NOT NULL OR people_fully_vaccinated IS NOT NULL
ORDER BY location, date;

-- 1. global numbers

WITH group_on_location AS
(
SELECT 
	location, MAX(total_vaccinations) as total_vac, MAX(people_vaccinated) as people_vac, 
	MAX(people_fully_vaccinated) as people_fully_vac
FROM covid_vaccinations_edit
GROUP BY location
)
SELECT 
	SUM(total_vac) as total_vaccinations, 
    SUM(people_vac) as people_vaccinated, 
    SUM(people_fully_vac) as people_fully_vaccinated
FROM group_on_location;

-- 2. vaccinated population percentage in every country

WITH vaccinated_percentage AS
(
SELECT de.location, de.date, de.population, va.people_vaccinated, va.people_fully_vaccinated
FROM covid_deaths_edit de
JOIN covid_vaccinations_edit va
	ON de.location = va.location
	AND de.date = va.date
ORDER BY de.location, de.date
)
SELECT 
	location, population, 
    ROUND((MAX(people_vaccinated)/population) * 100, 3) as people_vaccinated_percentage,
    ROUND((MAX(people_fully_vaccinated)/population) * 100, 3) as people_fully_vaccinated_percentage
FROM vaccinated_percentage
GROUP BY location, population;

-- 3. vaccinated percentage + infected percentage through time

SELECT 
	de.location, de.date, de.population, de.new_cases, de.total_cases, de.new_deaths, de.total_deaths,
    va.total_vaccinations, va.people_vaccinated, va.people_fully_vaccinated,
    ROUND((va.people_vaccinated/de.population) * 100, 3) as people_vaccinated_percentage,
    ROUND((va.people_fully_vaccinated/de.population) * 100, 3) as people_fully_vaccinated_percentage,
    ROUND((de.total_cases/de.population) * 100, 3) as infected_population_percentage,
    ROUND((de.total_deaths/de.total_cases) * 100, 3) as deceased_infected_percentage
FROM covid_deaths_edit de
JOIN covid_vaccinations_edit va
	ON de.location = va.location
	AND de.date = va.date
ORDER BY de.location, de.date;







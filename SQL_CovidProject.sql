
SELECT *
FROM CovidProject_1..CovidDeaths
ORDER BY 3,4;

--Select *
--From CovidProject_1..CovidVaccines
--Order by 3,4

--Selecting the data that we will use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject_1..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- for most queries I will look specifically at the uk

-- Looking at Total Cases vs Total Deaths
-- Likelihood of dying if you contract covid at any given country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM CovidProject_1..CovidDeaths
WHERE location LIKE '%kingdom%' AND continent IS NOT NULL
ORDER BY 1,2;


-- Looking at Total Cases vs Population
-- Percentage of population contracting covid at any given country
SELECT location, date, population, total_cases,  (total_cases/population) * 100 as case_percentage
FROM CovidProject_1..CovidDeaths
WHERE location LIKE '%kingdom%' AND continent IS NOT NULL
ORDER BY 1,2;


-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as Highest_Infection_Count, MAX((total_cases/population))*100 as max_case_percentage
FROM CovidProject_1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY max_case_percentage DESC;


-- Looking at countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM CovidProject_1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;


-- Breaking figures down by continent

-- Showing contients with highest death count per population
SELECT continent, MAX(cast(total_deaths as INT)) as total_death_count
FROM CovidProject_1..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;



-- Global numbers

SELECT SUM(new_cases) as global_new_cases, SUM(new_deaths) as global_new_deaths, CASE WHEN SUM(new_cases) = 0 THEN NULL ELSE SUM(cast(new_deaths as INT))/SUM(new_cases)*100 END as death_percentage
FROM CovidProject_1..CovidDeaths 
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM CovidProject_1..CovidDeaths dea
JOIN CovidProject_1..CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--Using a CTE

WITH vaccination_percentage (continent, location, date, population, new_vaccinations, rolling_vaccinations)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM CovidProject_1..CovidDeaths dea
JOIN CovidProject_1..CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--order by 2,3
)
SELECT *, (rolling_vaccinations/population)*100
FROM vaccination_percentage

-- Using a temp table

DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)

INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM CovidProject_1..CovidDeaths dea
JOIN CovidProject_1..CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3;

SELECT *, (rolling_vaccinations/population)*100
FROM #percent_population_vaccinated


-- Creating View to store data for later visualisations

USE CovidProject_1

GO

CREATE VIEW percent_people_vaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM CovidProject_1..CovidDeaths dea
JOIN CovidProject_1..CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3;

SELECT *
FROM percent_people_vaccinated
SELECT *
FROM Portfolio..CovidDeaths
ORDER BY 3,4

SELECT *
FROM Portfolio..CovidVaccinations
ORDER BY 3,4


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio..CovidDeaths
ORDER BY 1,2

--turning columns from int to float
ALTER TABLE [dbo].[CovidDeaths]
ALTER column total_cases float
GO

ALTER TABLE [dbo].[CovidDeaths]
ALTER column total_deaths float
GO

-- Total Cases vs Total Deaths (What is the likelihood of deaths if you get Covid?)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL 
ORDER BY 1,2

--Total Cases vs Population (what percentage of population got Covid?)
SELECT location, date, population, total_cases, (total_cases/population) * 100 AS PopulationInfected
FROM Portfolio..CovidDeaths
--WHERE location LIKE '%states%'
ORDER BY 1,2

--What countries have the highest infection rate?
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PopulationInfected
FROM Portfolio..CovidDeaths
GROUP BY location, population
ORDER BY PopulationInfected DESC

--How many deaths occured per population by Country
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL --where continent was null, location was filled by terms like World, Asia, africa etc
GROUP BY location
ORDER BY TotalDeathCount DESC


--breaking things down by continent
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers
ALTER TABLE [dbo].[CovidDeaths]
ALTER column new_cases float
GO

ALTER TABLE [dbo].[CovidDeaths]
ALTER column new_deaths float
GO

-- by Date
SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1,2

-- Cumulative till date
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage
FROM Portfolio..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2

-- JOINING TABLES on Deaths & Vaccinations
SELECT * 
FROM Portfolio..CovidDeaths AS dea
JOIN Portfolio..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

--Rolling Total of Vaccinations done by Country
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationsByCountry --Now compare this with population
FROM Portfolio..CovidDeaths AS dea
JOIN Portfolio..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Total Population vs Vaccinations (Using CTEs)
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingVaccinationsByCountry) --have to be same as the SELECT query below
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationsByCountry 
FROM Portfolio..CovidDeaths AS dea
JOIN Portfolio..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3 
)
SELECT * , (RollingVaccinationsByCountry/CAST(population AS float))*100 AS PercentOfPopVaccinated
FROM PopVsVac


--Total Population vs Vaccinations (Using TEMP TABLES)
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinationsByCountry numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationsByCountry 
FROM Portfolio..CovidDeaths AS dea
JOIN Portfolio..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3 

SELECT * , (RollingVaccinationsByCountry/CAST(population AS float))*100 AS PercentOfPopVaccinated
FROM #PercentPopulationVaccinated

--Creating View to Store Data for Later Visualizations
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationsByCountry 
FROM Portfolio..CovidDeaths AS dea
JOIN Portfolio..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3 
SELECT * 
FROM PortafolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * 
--FROM PortafolioProject..CovidDeaths
--ORDER BY 3,4

-- Select Data that we are going to be using 

SELECT location, date, total_cases,new_cases, total_deaths, population
FROM PortafolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total cases Vs Total Death
-- Shows likehood of dying if you contract covid in your country
SELECT location, date,  total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percent
FROM PortafolioProject..CovidDeaths
WHERE location like '%state%' AND continent IS NOT NULL
ORDER BY 1,2

-- Looking at Total cases Vs population
-- Shows what percent of population got Covid
SELECT location, date, population, total_cases,  (total_cases/population)*100 AS population_percent
FROM PortafolioProject..CovidDeaths
--WHERE location LIKE '%pana%'
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at Countries with Highest infection Rate compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(total_cases/population)*100 AS max_percent_population_infected
FROM PortafolioProject..CovidDeaths
--WHERE location LIKE '%pana%'
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY max_percent_population_infected DESC

-- lET'S BREAKS THINGS BY LOCATION
SELECT location, MAX(CAST(total_deaths AS INT)) AS Total_death_count
FROM PortafolioProject..CovidDeaths
--WHERE location LIKE '%pana%'
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_death_count DESC

-- lET'S BREAKS THINGS BY CONTINENT
SELECT continent, MAX(CAST(total_deaths AS INT)) AS Total_death_count
FROM PortafolioProject..CovidDeaths
--WHERE location LIKE '%pana%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_death_count DESC

-- Showing continents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT )) AS	TotalDeath
FROM PortafolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeath desc

-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS Total_cases, SUM(CAST(new_deaths AS INT)) AS Total_death, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS Death_percentage
FROM PortafolioProject..CovidDeaths
--WHERE location like '%state%' AND 
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)  AS RollingPeopleVaccinated
--(RollingPeopleVaccinated / dea.population)*100
FROM PortafolioProject..CovidDeaths dea
JOIN PortafolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE	dea.continent IS NOT NULL
ORDER BY 2,3;


-- Looking at Total Population vs death
SELECT continent, location, date, population,new_deaths,
SUM(CAST(new_deaths  AS INT)) OVER (PARTITION BY location ORDER BY location) RollingPeopleDeath
FROM PortafolioProject..CovidDeaths
WHERE continent IS NOT NULL AND new_deaths IS NOT NULL

ORDER BY 2,3

;

WITH PopVsDea (Continet, Location, Date, Population, New_deaths,RollingPeopleDeath )
AS 
(
SELECT continent, location, date, population,new_deaths,
SUM(CAST(new_deaths  AS INT)) OVER (PARTITION BY location ORDER BY location) RollingPeopleDeath
FROM PortafolioProject..CovidDeaths
WHERE continent IS NOT NULL AND new_deaths IS NOT NULL

--ORDER BY 2,3
)
SELECT *
FROM PopVsDea;



-- USE CTE

WITH PopvsVac (Continent, Location, date, Population,New_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)  AS RollingPeopleVaccinated
--(RollingPeopleVaccinated / dea.population)*100
FROM PortafolioProject..CovidDeaths dea
JOIN PortafolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE	dea.continent IS NOT NULL
-- ORDER BY 2,3
)  

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent Nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)  AS RollingPeopleVaccinated
--(RollingPeopleVaccinated / dea.population)*100
FROM PortafolioProject..CovidDeaths dea
JOIN PortafolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date
--WHERE	dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating viwe to store data for later vizualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated;
GO
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)  AS RollingPeopleVaccinated
--(RollingPeopleVaccinated / dea.population)*100
FROM PortafolioProject..CovidDeaths dea
JOIN PortafolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE	dea.continent IS NOT NULL;
-- ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated

----------------------------------
DROP VIEW IF EXISTS Populationvsdeath;
CREATE VIEW Populationvsdeath AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)  AS RollingPeopleVaccinated
--(RollingPeopleVaccinated / dea.population)*100
FROM PortafolioProject..CovidDeaths dea
JOIN PortafolioProject..CovidVaccinations vac
ON dea.location = vac.location 
AND dea.date = vac.date
WHERE	dea.continent IS NOT NULL
--ORDER BY 2,3;

SELECT * 
FROM Populationvsdeath
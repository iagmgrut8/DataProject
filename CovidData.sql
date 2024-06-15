SELECT *
FROM dbo.CovidDeaths$
order by 3,4

--SELECT *
--FROM dbo.CovidVaccinations$
--order by 3,4


-- Select data

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths$
ORDER by 1,2

-- Create View of dbo.CovidDeaths$ by Location, date, total_cases, new_cases, total_deaths, population

CREATE VIEW DeathsView AS
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM dbo.CovidDeaths$
-- ORDER by 1,2


-- Percent of deaths from total cases by location and date

SELECT 
	Location, 
	date, 
	total_cases, 
	total_deaths, 
	(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS Percent_of_death_from_total_cases
FROM dbo.CovidDeaths$
-- WHERE location like '%Israel%'
ORDER by 1,2

-- Create view for Percent_of_death_from_total_cases

CREATE VIEW Percent_of_death_from_total_cases AS 
SELECT 
	Location, 
	date, 
	total_cases, 
	total_deaths, 
	(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS Percent_of_death_from_total_cases
FROM dbo.CovidDeaths$
-- WHERE location like '%Israel%'
-- ORDER by 1,2

-- Total cases vs population ; Percent of population with Covid

SELECT Location,
	date, 
	population, 
	total_cases, 
	(CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0))*100 AS PercentOfInfection
FROM dbo.CovidDeaths$
--WHERE location like '%Israel%'
ORDER by 1,2

-- Create view for; Percent of population with Covid

CREATE VIEW Percent_of_population_with_covid AS
SELECT Location,
	date, 
	population, 
	total_cases, 
	(CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0))*100 AS PercentOfInfection
FROM dbo.CovidDeaths$
--WHERE location like '%Israel%'
--ORDER by 1,2


-- Countries with highest infection rate

SELECT Location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX(CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0))*100 AS HighestInfectionRate
FROM dbo.CovidDeaths$
--WHERE location like '%Israel%'
GROUP by location, population
--ORDER by HighestInfectionRate DESC

-- Create view for ; Countries with highest infection rate

CREATE VIEW HightstInfectionRateByCountry AS
SELECT Location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX(CONVERT(float,total_cases)/NULLIF(CONVERT(float,population),0))*100 AS HighestInfectionRate
FROM dbo.CovidDeaths$
--WHERE location like '%Israel%'
GROUP by location, population

-- Total Death Count by country

SELECT Location, MAX(cast(total_deaths AS int)) AS TotalDeathCount 
FROM dbo.CovidDeaths$
--WHERE location like '%Israel%'
WHERE continent IS NOT NULL
GROUP by location
ORDER by TotalDeathCount DESC

-- Create view for ; TotalDeathCountByCountry

CREATE VIEW TotalDeathCountByCountry AS
SELECT Location, MAX(cast(total_deaths AS int)) AS TotalDeathCount 
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP by location

-- Death by Continent

SELECT 
	continent, 
	MAX(CONVERT(int,total_deaths)) AS TotalDeathCount
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP by continent
ORDER by TotalDeathCount DESC

-- Create view for ; Death by Continent

CREATE VIEW DeathByContinent AS
SELECT 
	continent, 
	MAX(CONVERT(int,total_deaths)) AS TotalDeathCount
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP by continent
--ORDER by TotalDeathCount DESC

-- Global numbers

SELECT
    SUM(CONVERT(int, new_cases)) AS total_cases,
    SUM(CONVERT(int, new_deaths)) AS total_deaths,
    SUM(CONVERT(int, new_deaths)) * 100.0 / NULLIF(SUM(CONVERT(int, new_cases)), 0) AS DeathPercentage
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

-- Create view for ; GlobalDeathPercentage

CREATE VIEW GlobalDeathPercentage AS
SELECT
    SUM(CONVERT(int, new_cases)) AS total_cases,
    SUM(CONVERT(int, new_deaths)) AS total_deaths,
    SUM(CONVERT(int, new_deaths)) * 100.0 / NULLIF(SUM(CONVERT(int, new_cases)), 0) AS DeathPercentage
FROM dbo.CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
--ORDER BY 1,2

-- Total vaccinated globally

SELECT
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,ISNULL(vac.new_vaccinations, 0))) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
	--(PeopleVaccinated/population)*100
	FROM CovidDeaths$ dea
	JOIN CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
		ORDER BY 2,3

-- CTE

WITH PopVSVac (Continent, Location, Date, Population, New_Vaccinations, PeopleVaccinated) AS
(
SELECT
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,ISNULL(vac.new_vaccinations, 0))) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
	--(PeopleVaccinated/population)*100
	FROM CovidDeaths$ dea
	JOIN CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
		--ORDER BY 2,3
		)
SELECT *, (PeopleVaccinated/Population)*100
FROM PopVSVAC


-- TEMP Table

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinated numeric,
	PeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *,
	CASE 
		WHEN Population > 0 THEN (CAST(PeopleVaccinated AS float)/Population)*100 
		ELSE NULL 
	END AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated


-- CREATE VIEW

CREATE VIEW PercentPopulationVaccinated AS 
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
--ORDER BY 2,3

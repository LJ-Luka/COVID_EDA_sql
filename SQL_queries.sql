/*An analysis of global covid data from 24/02/2020 to 30/04/2021. This analysis is for exploratory purpose*/

--COVID DEATHS

> SELECT *
FROM 
covid.covid_deaths    --Quick preview of the covid_deaths table
WHERE continent is not null
ORDER BY 3,4;


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid.covid_deaths
WHERE continent is not null
ORDER BY 1,2;


--total_cases vs total_deaths in NG
SELECT location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 AS death_percentage  --chance of dying as a result of contracting the virus
FROM covid.covid_deaths
WHERE location like '%Nigeria%' AND continent is not null
ORDER BY 1,2;


--total_cases vs population in NG 
SELECT location, date, total_cases, population, 
(total_cases/population)*100 AS percentage_contracted     --percentage of the population that got covid
FROM covid.covid_deaths
WHERE location like '%Nigeria%' AND continent is not null
ORDER BY 1,2;


--Continent with the highest count
SELECT location, MAX(total_deaths) AS total_death_continent
FROM covid.covid_deaths
WHERE continent is null
GROUP BY location
ORDER BY total_death_continent DESC;

SELECT continent, MAX(total_deaths) AS total_death_continent
FROM covid.covid_deaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_continent DESC;


--Country with the highest death count per population
SELECT location, MAX(total_deaths) AS total_death_count
FROM covid.covid_deaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC;


--Global scale. For tableau viz
--Query 1
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS global_death_percentage
FROM covid.covid_deaths
WHERE continent is not null
ORDER BY 1,2;

-- Query 2 (Deaths count)
SELECT location, SUM(cast(new_deaths as int)) AS total_death_count
FROM 
covid.covid_deaths
WHERE continent is null
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC;

--Query 3 (Percentage infections)
SELECT location, MAX(total_cases) AS highest_infection_count,
MAX((total_cases/population))*100 AS percentage_contracted   
FROM covid.covid_deaths
GROUP BY location, population
ORDER BY percentage_contracted DESC;

--Query 4
SELECT location, population, date, MAX(total_cases) AS highest_infection_count,
MAX((total_cases/population))*100 AS percentage_contracted    
FROM covid.covid_deaths
GROUP BY location, population, date
ORDER BY percentage_contracted DESC;


--COVID VACCINATIONS

SELECT *
FROM 
covid.covid_vaccinations    --Quick preview of the covid_vaccinations table
ORDER BY 3,4;


--Joined both tables
SELECT *
FROM
covid.covid_deaths AS deaths
JOIN 
covid.covid_vaccinations AS vaccinations ON
deaths.location = vaccinations.location
AND deaths.date = vaccinations.date;


--Total vaccinations vs population
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
SUM(vaccinations.new_vaccinations) OVER (partition by deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
FROM covid.covid_deaths AS deaths
JOIN 
covid.covid_vaccinations AS vaccinations ON
deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
order by 2,3;


--Created a CTE for population_vaccinated and percentage
WITH population_vaccinated AS (
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
SUM(vaccinations.new_vaccinations) OVER (partition by deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
FROM covid.covid_deaths AS deaths
JOIN 
covid.covid_vaccinations AS vaccinations ON
deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
order by 2,3
)
SELECT *, (rolling_people_vaccinated/population)*100 AS percentage_pop_vaccinated
FROM
population_vaccinated;


--Created temp table
CREATE TEMP TABLE percentage_population_vaccinated

(Continent STRING, 
Location STRING, 
Date datetime, 
Population numeric, 
New_vaccinations numeric,
Rolling_people_vaccinated numeric
);

INSERT INTO percentage_population_vaccinated
--SELECT *, (rolling_people_vaccinated/population)*100  AS percentage_pop_vaccinated,
 (SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
 SUM(vaccinations.new_vaccinations) OVER (partition by deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
 FROM covid.covid_deaths AS deaths
 JOIN 
 covid.covid_vaccinations AS vaccinations ON
 deaths.location = vaccinations.location
 AND deaths.date = vaccinations.date
 WHERE deaths.continent is not null
 )
 ;


--Created view for the temp table
CREATE VIEW covid.percentage_population_vaccinated AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,
SUM(vaccinations.new_vaccinations) OVER (partition by deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vaccinated
FROM covid.covid_deaths AS deaths
JOIN 
covid.covid_vaccinations AS vaccinations ON
deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
)


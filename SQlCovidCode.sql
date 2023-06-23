Select *
FROM CovidData.dbo.CovidDeath
order by 3,4

Select *
FROM CovidData.dbo.CovidVacinations
order by 3,4
ALTER TABLE CovidData..CovidDeath DROP COLUMN F62,F63,F64

ALTER TABLE CovidData..CovidVacinations DROP COLUMN F35,F36,F37,F38

Select location, date, total_cases,new_cases,total_deaths,population
FROM CovidData..CovidDeath
Order by 1,2

--Looking Death percentage in India
Select location, total_cases, total_deaths , (CAST(total_deaths AS decimal(12,2)) / CAST(total_cases AS decimal(12,2)))*100 as DeathPercentage
From CovidData..covidDeath
where location like 'India'
Order by 1,2

--Looking for percentage of people infected
Select location, total_cases, population , (CAST(total_cases AS decimal(12,2)) / CAST(population AS decimal(12,2)))*100 as InfectedPercentage
From CovidData..covidDeath
where location like 'India'
Order by 1,2

--Looking for infected percentage according to country
Select location, MAX(CAST(total_cases AS decimal(12,2))) as HighestCases, population , MAX(CAST(total_cases AS decimal(12,2)) / CAST(population AS decimal(12,2)))*100 as InfectedPercentage
From CovidData..covidDeath
WHERE continent is NOT NULL
Group by location,population
Order by 4 desc

--Cases according to continent
Select location, MAX(CAST(total_cases AS decimal(12,2))) as TotalDeathCount
From CovidData..covidDeath
WHERE continent is NOT NULL
Group by location
Order by TotalDeathCount desc

--Death according to continent
Select location, MAX(CAST(total_deaths AS decimal(12,2))) as TotalDeathCount
From CovidData..covidDeath
WHERE continent is NULL
Group by location
Order by TotalDeathCount desc

--Death percentage according to cotinent
-- We use nullif to check whether the term is zero and if it we output the total fuction zero
SELECT date, SUM(new_cases), SUM(new_deaths),SUM(CAST(new_deaths AS bigint))/nullif(SUM(new_cases),0)*100 as DeathPercentage
From CovidData..covidDeath
WHERE continent is not null
Group by date
ORDER by 1,2

--Looking at total population vs vacination
SELECT *
,SUM(CAST(Vac.new_vaccinations as bigint)) OVER (Partition by Dea.location ORDER by Dea.location,Dea.date) As RollingSum
FROM CovidData..CovidDeath Dea
JOIN CovidData..CovidVacinations Vac
 On Dea.location = Vac.location
 AND Dea.date = Vac.date
WHERE Dea.continent is not NULL
AND Dea.location like 'India'
Order by 2,3

--Use CTE
With PopvsVac (Continent,location,Date,population,new_vaccinations,RollingSum)
as(
SELECT Dea.continent,Dea.location,Dea.date,Dea.population,Vac.new_vaccinations
,SUM(CAST(Vac.new_vaccinations as bigint)) OVER (Partition by Dea.location ORDER by Dea.location,Dea.date) As RollingSum
FROM CovidData..CovidDeath Dea
JOIN CovidData..CovidVacinations Vac
   ON Dea.location = Vac.location
   AND Dea.date = Vac.date
WHERE Dea.continent is not NULL
AND Dea.location like 'India'
)
SELECT * ,(RollingSum/population)*100
FROM PopvsVac


--Using temp Teble
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.Date) as RollingPeopleVaccinated
From CovidData..CovidDeath dea
Join CovidData..CovidVacinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


--Creating View
Create View PercentPopulationVacinated As
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidData..CovidDeath dea
Join CovidData..CovidVacinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

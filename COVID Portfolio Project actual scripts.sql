Select *
From PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--Select *
--From PortfolioProject..CovidVaccinations
--order by 3, 4

-- Select data that we are going to be using

Select Location, Date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
where continent is not null
order by 1, 2

--Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country

Select Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where location like '%Vietnam%'
and continent is not null
order by 1, 2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select Location, Date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--where location like 'Vietnam'
order by 1, 2

-- Looking at Countries with Highest Infection Rate compared to Population?
Select Location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--where location like 'Vietnam'
Group by location, population
order by PercentPopulationInfected desc

-- Showing Countries with Highest Death Count per Population
Select Location, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like 'Vietnam'
where continent is not null
Group by location
order by TotalDeathCount desc


--LET'S BREAK THINGS DOWN BY CONTINENTS

Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like 'Vietnam'
where continent is not null
Group by continent
order by TotalDeathCount desc

-- Showing Continents with Highest Death Count per Population

Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--where location like 'Vietnam'
where continent is not null
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select sum(new_cases) as TotalNewCases, sum(cast(new_deaths as int)) as TotalNewDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
--where location like '%Vietnam%'
where continent is not null
--group by date
order by 1, 2

-- Explore Covid Vaccinations

-- Looking at Total Population vs Vaccinations

Select dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations
,sum(cast(vac.new_vaccinations as int)) OVER (partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- USE CTE
With PopvsVac (continent,location,date,population,new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations
,sum(cast(vac.new_vaccinations as int)) OVER (partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)
Select *, (RollingPeopleVaccinated/population)*100 as Percentage
From PopvsVac

---TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
Select dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations
,sum(cast(vac.new_vaccinations as int)) OVER (partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
--where dea.continent is not null
--order by 2, 3

Select *, (RollingPeopleVaccinated/population)*100 as Percentage
From #PercentPopulationVaccinated


--Creating View to store data for later visualization

CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations
,sum(cast(vac.new_vaccinations as int)) OVER (partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

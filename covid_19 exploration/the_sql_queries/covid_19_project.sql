--### this file includes some questions i got in my head about  this covid thing !!!


--Q1 : where all of this started :(

select distinct 
	location,
	date,
	new_cases
from 
	covid_19..covid_death
where 
	new_cases is not null 
and 
	new_cases >=1
order by  date,location


---- Q2 : what was the death chance per day since the beginning till now ?  

select 
	location,
	date,
	total_cases,
	total_deaths, 
	(total_deaths/total_cases)*100 as dieing_chance
from 
	covid_19..covid_death 
where 
	total_cases is not null
and 
	total_deaths is not null
and
	continent is not null
order by 2,1


---- Q3 : what is the percentages of infected population ? 

select 
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 as population_infected
from 
	covid_19..covid_death 
where 
	total_cases is not null
and
	continent is not null
order by 2,1


--Q4 : what is the total number of covid cases in each continent an globally ?

select distinct top 7
	location,
	max(total_cases) total_numbers
from covid_19..covid_death
where 
	continent is  null
and 
	location <> 'European Union'
group by location
order by total_numbers desc

-- Q5 : what is the number of infection for each country ?

select distinct 
	location,
	max(total_cases) as total 
from 
	covid_19..covid_death
where 
	continent is not null
group by location
having 
	max(total_cases) is not null
order by total desc


--Q6 : what is the total number of  death around the world ?

select distinct top 7
	location,
	max(cast(total_deaths as int)) total_death
from 
	covid_19..covid_death
where 
	continent is  null
and 
	location <> 'European Union'
group by location
order by total_death desc

--Q7 : what is the number of death per country ?

select distinct 
	location,
	max(cast(total_deaths as int)) as total_death 
from 
	covid_19..covid_death
where 
	continent is not null
group by location
having 
	max(total_cases) is not null
order by total_death desc

--Q8 : when & where did the vaccination thing started ?

select top 1 
	date,
	location,
	new_vaccinations
from 
	covid_19..covid_vaccine
where 
	continent is not null
and 
	new_vaccinations > 0
order by 1,3


--Q9 : how many vaccines were delivered/day ?

select distinct 
	cv.date,
	cd.location,
	cd.population,
	cv.new_vaccinations,
	sum(cast(cv.new_vaccinations as int)) 
	over(partition by cv.location order by cv.location,cv.date) as total_vaccine
from 
	covid_19..covid_death cd
join 
	covid_19..covid_vaccine cv
on 
	cd.location = cv.location
and 
	cd.date = cv.date
where 
	cd.continent is not null
and 
	cv.new_vaccinations >0
order by 1,2


--Q10 : what is the highest country that acquired the vaccine ?

with vaccines as (
	select 
		cd.location,
		sum(cast(cv.new_vaccinations as int)) 
		over(partition by cv.location order by cv.location,cv.date) as total_vaccines
	from 
			covid_19..covid_death cd
	join 
			covid_19..covid_vaccine cv
	on 
			cd.location = cv.location
	and 
			cd.date = cv.date
	where 
			cd.continent is not null
	and 
			cv.new_vaccinations >0
	)

select top 1  
	location,
	max(total_vaccines) number_of_vaccine
from 
	vaccines
group by location
order by 2 desc 

--Q11 : how many people / day got the vaccine and what is the total at last ?

select distinct  
	cd.date,
	cv.location,
	cd.population,
	cv.people_fully_vaccinated vaccination_per_day,
	sum(convert(float,cv.people_fully_vaccinated)) 
	over(partition by cv.location order by cv.location,cd.date) as total_people_vaccinated
from 
	covid_19..covid_death cd
join 
	covid_19..covid_vaccine cv
on 
	cd.location = cv.location
and 
	cd.date = cv.date
where 
	cv.people_fully_vaccinated>0
and 
	cd.continent is not null
order by 2,1


-- let's create TEMP TABLE for the percentage of people got the vaccine 

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
Select 
	cd.continent, 
	cd.location,
	cd.date, 
	cd.population, 
	cv.new_vaccinations, 
	SUM(CONVERT(int,cv.new_vaccinations)) 
	OVER (Partition by cd.Location Order by  cd.Date,cd.location) as RollingPeopleVaccinated
From
	covid_19..covid_death cd
Join 
	covid_19..covid_vaccine cv
On 
	cd.location = cv.location
and 
	cd.date = cv.date
where 
	cd.continent is not null 
and 
	cv.new_vaccinations >0

Select *,
	(RollingPeopleVaccinated/Population)*100 as percent_of_vaccinated
From 
	#PercentPopulationVaccinated



-- finally let's create some views for global cases/death and for fun 2 :)

Create View global_cases as
select distinct top 7
	location,
	max(total_cases) total_cases
from covid_19..covid_death
where 
	continent is  null
and 
	location <> 'European Union'
group by location
order by total_cases desc

--##################################################################3

Create View global_death as
select distinct top 7
	location,
	max(cast(total_deaths as int)) total_death
from covid_19..covid_death
where 
	continent is  null
and 
	location <> 'European Union'
group by location
order by total_death desc



/*

this is the optimized version of my sql queries, it's better not to see the version i worked on :)

First i start with the required data cleaning and making it suitable for later 
then  i will explore the data, answer some questions about the data and know some facts about covid in 2022 i didn't know about :)
last  showing the results in visualizations using tableau.

*/


-- at first i will take a quick look at the two datasets 
select top 5 * from coviddeath..cov_death;
select top 5 * from covidvaccinations..cov_vacc;


-- ### i will start with the "coviddeath" dataset ###

-- the location column suppose have the countries only so will remove the busted values from the location and the null values from continent
delete from coviddeath..cov_death
where continent is null
and location  in ('North America','Asia','Africa','Oceania','South America','Europe');


-- i'm not sure if "European Union" should be in the location column or not, but i will work as if it's fine for now
-- so, when filtering the data based on location equals "European Union" the continent values are nulls. so, will change them 
update coviddeath..cov_death
set continent = COALESCE(continent,'Europe') where location = 'European Union';


-- when i checked the data type of the columns i found that "total_deaths" data type isn't right it's suppose to be int 
ALTER TABLE coviddeath..cov_death
ALTER COLUMN total_deaths int;

-- and the same for "new_deaths"
ALTER TABLE coviddeath..cov_death
ALTER COLUMN new_deaths int;

-- when i check the null values in continent i find that all the values in location aren't countries names but they are classifications of 
-- humans income level like (Upper middle income, Low income, etc.) which makes no sense so, will have to remove them
delete from coviddeath..cov_death
where continent is null;

-- i'll check if the dataset has some duplicates
-- the dataset has many columns so, i'll use the most important columns 

with duplicates as (
	select *,
		ROW_NUMBER()
		over(partition by continent,location,date,total_cases,total_deaths,hosp_patients order by date) as duplicates_num
	from coviddeath..cov_death
	)

select 
	iso_code
	continent,
	location,
	date,
	total_cases,
	total_deaths,
	max(duplicates_num) as duplicates_number
from duplicates
group by 
	iso_code,
	continent,
	location,
	date,
	total_cases,
	total_deaths
having max(duplicates_num) > 1;

-- ** well that's great it's no duplicates so i think i can start working on the dataset




--Q1 : where & when all of this started :(

select distinct top(1)  
	location,
	date,
	total_cases
from 
	coviddeath..cov_death
where
	total_cases is not null
order by  date,location;


-- Q2 : what was the death chance per day since the beginning till now ?
-- which shows ur death chance in each country for each day till the last date in this dataset for every country out of the infected

select 
	location,
	date,
	total_cases,
	total_deaths,
	round((total_deaths/total_cases)*100,2) as death_percentage
from coviddeath..cov_death
order by 1,2;

-- Q3 : what is the percentages of infected population over time ? 

select 
	location,
	date,
	population,
	total_cases,
	round((total_cases/population)*100,2) as infection_percentage
from coviddeath..cov_death
order by 1,2;

--Q4 : what's the infection rate per country ?

select
	location,
	population,
	MAX(total_cases) as	highest_infection_number,
	round((MAX(total_cases)/population)*100,2) as infection_percentage
from coviddeath..cov_death
group by location,population
order by infection_percentage desc;


--Q5 : what is the death cases per country ?

select
	location,
	MAX(total_deaths) as death_number
from coviddeath..cov_death
where location <> 'European Union'
group by location
order by death_number desc;



--Q5 : what is the total number of covid cases in each continent ?

with total_cases as (select 
		continent,
		location,
		max(total_cases) as total_cases
	from coviddeath..cov_death
	where location <> 'European Union'
	group by continent,location)

select 
	continent,
	SUM(total_cases) as total_cases
from total_cases
group by continent
order by total_cases desc;

--Q6 : what is the death cases per continent ?
select 
	continent,
	SUM(total_deaths) as number_of_death
from 
	(
	select 
		continent,
		location,
		max(total_deaths) as total_deaths
	from coviddeath..cov_death
	where location <> 'European Union'
	group by continent,location
	) sub

group by continent
order by number_of_death desc;



--Q7 : what is the infection percentage globally ?
with infection as (
select
	location,
	max(population) as the_population,
	max(total_cases) as total_cases
from coviddeath..cov_death
where location <> 'European Union'
group by location
)
select 
	SUM(the_population) as the_population,
	SUM(total_cases) as death_globally,
	round(SUM(total_cases)/SUM(the_population)*100,2) as global_infection_percentage
from infection;


--Q8 : what is the death percentage globally ?
with totals as (
select
	location,
	max(population) as the_population,
	max(total_deaths) as total_death
from coviddeath..cov_death
where location <> 'European Union'
group by location
)
select 
	SUM(the_population) as the_population,
	SUM(total_death) as death_globally,
	round(SUM(total_death)/SUM(the_population)*100,2) as [global death percentage]
from totals;


									/* now it's time for the second dataset,
					    		i'll pretty much do the same cleaning as the first one,
					make the two datasets suitable for joining process and further investigations */


-- at first i'll start with the location and continent columns as the previous dataset
delete from covidvaccinations..cov_vacc
where continent is null
and location  in ('North America','Asia','Africa','Oceania','South America','Europe');

-- then replacing specific continent null values with "Europe"
update covidvaccinations..cov_vacc
set continent = COALESCE(continent,'Europe') where location = 'European Union';


-- then removing the null values from cintinent
delete from covidvaccinations..cov_vacc
where continent is null;

-- fixing the columns dtype
ALTER TABLE covidvaccinations..cov_vacc
ALTER COLUMN new_vaccinations BIGINT;


-- now questions time
--Q9 : when & where did the vaccination thing started ?

select top 1 
	date,
	location,
	new_vaccinations as [vacc number]
from 
	covidvaccinations..cov_vacc
where 
	new_vaccinations > 0
order by 1,3


--Q9 : how many vaccines were delivered/day ?

select distinct 
	cv.date,
	cd.location,
	cd.population,
	cv.new_vaccinations,
	sum(cv.new_vaccinations) 
	over(partition by cv.location order by cv.location,cv.date) as total_vaccine
from 
	coviddeath..cov_death cd
join 
	covidvaccinations..cov_vacc cv
on 
	cd.location = cv.location
and 
	cd.date = cv.date
where 
	cv.new_vaccinations >0
order by 2,1;


--Q10 : what is the Total Population vs Vaccinations?
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

with vaccinations as (
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
    SUM(vac.new_vaccinations) 
	OVER (Partition by dea.Location Order by dea.location, dea.Date) as [people vaccinated per day]
From coviddeath..cov_death dea
Join covidvaccinations..cov_vacc vac
	On dea.location = vac.location
	and dea.date = vac.date
)

select *, 
	round(([people vaccinated per day]/Population)*100,2) as [percentage of vacinated]
from vaccinations;




-- && comparing between the percentage of people died before & after the vaccination process
-- this comparison isn't to say if the vaccines are good or not,"it has nothing to do with the vaccines efficiency at all", it's just a comparison.  


with before as (										
select
		dea.location as country,
		dea.date as [the date],
		dea.population [the population],
		MAX(dea.total_deaths) as [death number before]															
	from coviddeath..cov_death dea
	JOIN covidvaccinations..cov_vacc vacc
	on 
		dea.location = vacc.location
	and 
		dea.date = vacc.date
	where dea.location <> 'European Union'            -- *********u may want to check china u will be surprised***********
	/*and 
	vacc.new_vaccinations <1*/
	and
	dea.date < '2021-12-08 00:00:00.000' and dea.date >= '2020-01-22 00:00:00.000'
	group by 
		dea.location,
		dea.date,
		dea.population),

after as (
select
		dea.location as country,
		dea.date as [the date],
		dea.population [the population],
		MAX(dea.total_deaths) as [death number after]
	from coviddeath..cov_death dea
	join covidvaccinations..cov_vacc vacc
	on 
		dea.location = vacc.location
	and 
		dea.date = vacc.date
	where dea.location <> 'European Union'
	and 
	vacc.new_vaccinations >0
	and
	dea.date >= '2020-12-08 00:00:00.000' and  dea.date < '2021-12-08 00:00:00.000'
	group by 
		dea.location,
		dea.date,
		dea.population
)

select 
	a.country, 
	b.[the population], 
	b.[the date] as [the date before], 
	max(round(b.[death number before]/b.[the population]*100,2)) as [death percentage before vacc], 
	a.[the date] as [the date after], 
	max(round(a.[death number after]/a.[the population]*100,2)) as [death percentage after vacc] 
from
	before b 
FULL OUTER JOIN 
	after a
on 
	a.country = b.country
where a.country = 'Egypt' -- to reduce the running time  
group by 
	a.country, 
	b.[the population], 
	b.[the date],
	a.[the date]
order by 
	a.country,
	b.[the date],
	a.[the date];



--Q11 : is covid related to population density ?

select *
from(
select *,
rank()
over(order by [covid cases] desc ) as [infection rank]

from
(
select 
	location,
	population,
	SUM(new_cases) [covid cases]
from coviddeath..cov_death
where location <> 'European Union'
group by location,population
) sub  ) sub2
order by 
	(case 
		when [infection rank] = 118 then 0 
		when [infection rank] = 87 then 1
		else 2 end), -- i'll make china & Egypt alwayse at the top then sort the rest of the countries normally 
	[infection rank]; -- i'd to make a nested query above to use the "[infection rank]" column name instead of using the entire rank()over() query XD.




--Q12 : is there a relation between GDP and death rate ?

select  *,
rank()
over(order by [death rate] desc ) as [death rank]

from (
select distinct 
	dea.location,
	dea.population,
	vacc.gdp_per_capita as GDP,
	round(SUM(dea.new_deaths)/dea.population*100,2) as [death rate] 
from 
coviddeath..cov_death dea
join
covidvaccinations..cov_vacc vacc
on
dea.location = vacc.location
and
dea.date = vacc.date
where dea.location <> 'European Union'
group by 
	dea.location,
	vacc.gdp_per_capita,
	dea.population
) t1
order by GDP desc;






												/* i'll create some TEMP/Views  */

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
	dea.continent, 
	dea.location,
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
   SUM(vac.new_vaccinations) 
   OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From coviddeath..cov_death dea
Join covidvaccinations..cov_vacc vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.location <> 'European Union';

Select *, round((RollingPeopleVaccinated/Population)*100,2) as [percent of people vaccinated]
From #PercentPopulationVaccinated;


                                            -- *********** views for later visualizations ***********--
drop view if exists Percent_of_people_Vaccinated;

Create View Percent_of_people_Vaccinated as
with vaccinations as (
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
    SUM(vac.new_vaccinations) 
	OVER (Partition by dea.Location Order by dea.location, dea.Date) as [people vaccinated per day]
From coviddeath..cov_death dea
Join covidvaccinations..cov_vacc vac
	On dea.location = vac.location
	and dea.date = vac.date
)

select *, 
	round(([people vaccinated per day]/Population)*100,2) as [percentage of vacinated]
from vaccinations;


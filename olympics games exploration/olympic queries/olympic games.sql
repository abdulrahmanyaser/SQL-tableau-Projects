-- at first let's look at the data to see if the columns needs some adjustments (hope not ) before exploring & playing a little bit with it  
select  * from olympic_games..athletes_event_results

-- crap :( ,... it needs some . 
-- ok first i will adjust the sex column's values for male an female just for an easy read :)
UPDATE olympic_games..athletes_event_results
set Sex = case when Sex = 'M' then 'male'
when Sex = 'F' then 'female'
end;

-- now let's specify the players by their age 
alter table olympic_games..athletes_event_results
add age_group varchar(50);

update olympic_games..athletes_event_results
set age_group = case when age <14 then 'kid'
when age between 14 and 18 then 'teen'
when age between 19 and 65 then 'youth'
else 'old'
end;

-- now let's modify the games column and split it into 2 columns for an easy read/use later
alter table olympic_games..athletes_event_results
add year int,
season nvarchar(250);

UPDATE olympic_games..athletes_event_results
set year = left(Games,CHARINDEX(' ',games)-1),
season = right(games,CHARINDEX(' ',games)+1);

-- there is no use for the games column now , so let's drop it 
alter table olympic_games..athletes_event_results
drop column games ;

-- now let's update Medal column replacing NA with understandable data
UPDATE olympic_games..athletes_event_results
set Medal = case when Medal = 'NA' then 'no luck'
else Medal
end;


-- it's time to remove the duplicates from the data
with duplicates as (
	select *,
		ROW_NUMBER()
		over(partition by 
			id,
			name,
			sex,
			year,
			season,
			city,
			event,
			medals  
		order by 
			id,
			name,
			sex,
			year,
			season,
			city,
			event,
			medals ) as duplicates_num
	from olympic_games..athletes_event_results
	)
delete from duplicates
where duplicates_num >1;

-- ***********************************************************

-- now let's start playing with the data 
-- let's see how many players do we 've per age 
select distinct 
	age,
	age_group , 
	count(age_group) 
	over(partition by age order by age) as number_of_players_per_age
from olympic_games..athletes_event_results
where age is not null 
order by age;

-- and the same for age group
select distinct 
	age_group , 
	count(age) over(partition by age_group order by age_group) as number_of_players_per_age_group
from olympic_games..athletes_event_results
where age is not null 
order by age_group;

-- are the olumpics for men as claimed ?
select 
	sex,
	count(sex) gender_number 
from olympic_games..athletes_event_results
group by sex;
-- well it's not that "for men" :)


-- showing the number & type of medal each player achieved

select 
	name,
	Medals,
	count(medals) num_of_medals 
from olympic_games..athletes_event_results
where medals <> 'no luck'
group by name,Medals ;

-- showing the player name who achieved the most medals

with medals as (
select 
	name,
	Medal,
	count(medal) num_of_medals 
from olympic_games..athletes_event_results
where medal <> 'no luck'
group by name,Medal)

select top(1) 
	name,
	max(num_of_medals) as medals 
from medals
group by Name
order by max(num_of_medals)  desc;

-- what is the most achieved medal 
select 
	medals, 
	count(medals) medals_number 
from olympic_games..athletes_event_results
where medals <> 'no luck'
group by medals
order by medals_number desc;


-- how many games each city hosted per an olympic  ? 
select distinct 
	city,
	count(City) host_times 
from olympic_games..athletes_event_results
group by City
order by count(City) ;

-- which city hosted the olympics the most ? 
select top(1) 
	city,
	count(city) host_times 
from olympic_games..athletes_event_results
group by City
order by count(city) desc ;  -- am actually shocked it's not athina WOW

-- where did the first olympic happend ?
select top(1) 
	city,
	year  
from olympic_games..athletes_event_results
order by year ;


-- now let's see how each event performed during the olympics history 
select  
	event,
	count(medals) medals_achieved 
from olympic_games..athletes_event_results
where medals <> 'no luck'
group by Event
order by  medals_achieved desc ; 


-- number of medals every country achieved through the olympics history 

with the_medals as (
select  
	nation_code,
	Medals,
	count(Medals) medals_achieved 
from olympic_games..athletes_event_results
where medals <> 'no luck'
group by nation_code,Medals
)

select 
	nation_code,
	sum(medals_achieved) total_medals
from the_medals
group by nation_code
order by total_medals desc;


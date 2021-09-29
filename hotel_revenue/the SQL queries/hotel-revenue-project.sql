-- at first let's check our tables 
-- we have 3 tables we will work on , so let's join them into one table :) 

select * from hotel_revenue..['2018']
union
select * from hotel_revenue..['2019']
union
select * from hotel_revenue..['2020']


-- this is good but annoying to work on ,so let's make a table to work on 

create table hotel_revenue..three_years(
hotel nvarchar(255),
is_canceled float,
lead_time float,
arrival_date_year float,
arrival_date_month nvarchar(255),
arrival_date_week_number float,
arrival_date_day_of_month float,
stays_in_weekend_nights float,
stays_in_week_nights float,
adults float,
children float,
babies float,
meal nvarchar(255),
country nvarchar(255),
market_segment nvarchar(255),
distribution_channel nvarchar(255),
is_repeated_guest float,
previous_cancellations float,
previous_bookings_not_canceled float,
reserved_room_type nvarchar(255),
assigned_room_type nvarchar(255),
booking_changes float,
deposit_type nvarchar(255),
agent float,
company nvarchar(255),
days_in_waiting_list float,
customer_type nvarchar(255),
adr float,
required_car_parking_spaces float,
total_of_special_requests float,
reservation_status nvarchar(255),
reservation_status_date datetime);

-- inserting the data into the new table

insert into hotel_revenue..three_years 
select * from hotel_revenue..['2018']
union
select * from hotel_revenue..['2019']
union
select * from hotel_revenue..['2020'];

-- now let's check it again 
select * from hotel_revenue..three_years;

-- now we can start with our data , i will first ceck the columns and see if any needs some adjustments
-- the reservation_status_date column doesn't use the time so we'll remove it and use only the dates

alter table hotel_revenue..three_years
add the_reservation_status_date date;

update  hotel_revenue..three_years
set the_reservation_status_date =  CAST(reservation_status_date as date) ;

alter table hotel_revenue..three_years
DROP COLUMN reservation_status_date ;

-- as we can see in the company column 94595 out of 100k+ are nulls so really this column has no use ,so will drop it 
select  company,count(company) counts from hotel_revenue..three_years
where company = 'null'
group by company;

alter table hotel_revenue..three_years
DROP COLUMN company ;

-- now let's answer some questions starting with : is our hotel revenue growing by year and what hotel achieved more revenue ?
/* 
at first i added 2 columns total_nights  that represents all  the reserved days / week 
and week_revenue that contain all the revenue / week
*/

alter table hotel_revenue..three_years
add total_nights float,
week_revenue float;


update  hotel_revenue..three_years
set total_nights =  stays_in_week_nights + stays_in_weekend_nights,
week_revenue = total_nights *average_daily_revenue;


/*
then we have 3 tables the three_years 
and the market_segmentation that contain discounts for the residents 
and the meal_cost table that contain the prices the residents paied for each meal they ate
*/
-- hotel revenue by year 
select 
	t.hotel,
	t.arrival_date_year,
	round(sum(t.week_revenue*(1-m.discount)),0) year_revenue 
from  hotel_revenue..three_years as t
join hotel_revenue..market_segment as m
on t.market_segment = m.market_segment
group by 
	t.hotel,
	t.arrival_date_year
order by 
	t.hotel,
	year_revenue;

-- which hotel achieved more money
select 
	t.hotel,
	round(sum(t.week_revenue*(1-m.discount)),0) year_revenue 
from  hotel_revenue..three_years as t
join hotel_revenue..market_segment as m
on t.market_segment = m.market_segment
group by t.hotel
order by year_revenue desc;

-- the second question is should we increase our parking lot size 
-- at first let's check how many parking lots do we have per hotel
select 
	hotel,
	sum(required_car_parking_spaces)as total_parking 
from hotel_revenue..three_years
where required_car_parking_spaces >0
group by hotel;

-- let's see if they increase by time or not 
select 
	hotel,
	arrival_date_year,
	sum(required_car_parking_spaces)as total_parking 
from hotel_revenue..three_years
where required_car_parking_spaces >0 
group by 
	hotel,
	required_car_parking_spaces,
	arrival_date_year
order by 
	hotel,
	arrival_date_year,
	total_parking;
/*
unfortunately the dataset doesn't has any other data to help us decide if we need an increase or not 
yes the total parking is increasing per year but there are not enough evidence to tell if the hotels managed to deal with it or not 
but the temporary answer is no due to covid 19 that affected 2020 results 
*/



-- question 3 what room type affected the revenue the most ?

select  
	t.arrival_date_year,
	t.hotel,
	reserved_room_type , 
	count(reserved_room_type) total_reservation,
	round(sum(t.week_revenue*(1-m.discount)),0) year_revenue
from hotel_revenue..three_years t
join hotel_revenue..market_segment as m
on 
	t.market_segment = m.market_segment
group by 
	reserved_room_type,
	t.hotel,
	t.arrival_date_year
order by 
	t.arrival_date_year,
	t.hotel,
	total_reservation;
	
-- question 4 what is the best month to focus on ?
select  
arrival_date_year,
arrival_date_month,
hotel,
count(arrival_date_month) as total_arrivals
from hotel_revenue..three_years
group by arrival_date_month,arrival_date_year,hotel
order by arrival_date_year,hotel,total_arrivals desc;


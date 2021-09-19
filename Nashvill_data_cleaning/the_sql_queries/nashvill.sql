
-- firstly let's see how our dataset looks like
select top(20) * from Nashvill_housing..nashvill;



-- let's see if there are any duplicate data !!!!
-- the only columns that i know based on the reality of the dataset's columns can show us the duplicates is uniqueid column 
-- any column else can have the same data
with duplicates as (
	select *,
		ROW_NUMBER()
		over(partition by uniqueid order by uniqueid) as duplicates_num
	from Nashvill_housing..nashvill
)

select 
	uniqueid,
	legalreference,
	OwnerName,
	max(duplicates_num) duplicates_number
from duplicates
where OwnerName is not null
group by 
	uniqueid,
	legalreference,
	OwnerName
having max(duplicates_num)>1;


--now let's check saledate column we can see that the hours/min/... are not usable in here 

select top(18) saledate 
from Nashvill_housing..nashvill;


-- now let's fix the saledate column
--i will make a new column to store the new format of the saledate
alter table Nashvill_housing..nashvill
add the_sale_date date;

--then will add it to the data base with the new format
update Nashvill_housing..nashvill
set the_sale_date = convert(date , SaleDate);

-- removing the old column
ALTER TABLE Nashvill_housing..nashvill
DROP COLUMN saledate;


-- let's now work on propertyaddress columns 
select 
	propertyaddress,
	count([UniqueID]) 
from Nashvill_housing..nashvill
where propertyaddress is null
group by propertyaddress;

-- as shown above there are 29 null value , one way to fill them is by parcelid column . but first what is it ??
-- parcelID : is a unique identifier for a unit of land. It is assigned by your local municipality

select *,
		ROW_NUMBER()
		over(partition by parcelid order by parcelid) as duplicates_num
from Nashvill_housing..nashvill;

-- as shown above we can self join the dataset and fill the missing values from peopertyaddress with the same parcelid but different uniqueid
select 
	a.[UniqueID],
	a.ParcelID,
	a.PropertyAddress,
	b.[UniqueID],
	b.ParcelID,
	isnull(b.PropertyAddress,a.PropertyAddress) modified_property_address
from Nashvill_housing..nashvill a
join Nashvill_housing..nashvill b
on 
	a.ParcelID = b.ParcelID
and 
	a.[UniqueID] <> b.[UniqueID]
where
	b.PropertyAddress is null;
	
update b
set PropertyAddress = isnull(b.PropertyAddress,a.PropertyAddress)
from Nashvill_housing..nashvill a
join Nashvill_housing..nashvill b
on 
	a.ParcelID = b.ParcelID
and 
	a.[UniqueID] <> b.[UniqueID]
where
	b.PropertyAddress is null;

-- now let's check the updated PropertyAddress
select PropertyAddress 
from Nashvill_housing..nashvill
where PropertyAddress is  null;




-- while checking the data i noticed that propertyaddress column consist of 2 values the address and the city separated by a delimiter
-- so i splitted 'em into two columns as follow 

select 
	propertyaddress ,
	left(propertyaddress,charindex(',',propertyaddress)-1) as property_address , 
	right(propertyaddress ,len(propertyaddress) - charindex(',' ,propertyaddress))  as property_city
from Nashvill_housing..nashvill;


-- lets add the 2 new columns :)

alter table Nashvill_housing..nashvill
add 
property_address nvarchar(250),
property_city nvarchar(250);

update Nashvill_housing..nashvill
set property_address =  left(propertyaddress,charindex(',',propertyaddress)-1),
property_city =  right(propertyaddress ,len(propertyaddress) - charindex(',' ,propertyaddress));

select * from Nashvill_housing..nashvill

--now let's remove property address ... 
ALTER TABLE Nashvill_housing..nashvill
DROP COLUMN propertyaddress;


-- for the owneraddress column it's acrtually the same as propertyaddress  but it has 2 delimiters instead of 1 
-- so let's split it also 

alter table Nashvill_housing..nashvill
add 
	the_owner_address nvarchar(250),
	the_owner_city nvarchar(250),
	the_owner_state nvarchar(250)

update Nashvill_housing..nashvill
set 
	the_owner_address =  PARSENAME(replace(OwnerAddress,',','.'),3),
	the_owner_city =  PARSENAME(replace(OwnerAddress,',','.'),2),
	the_owner_state = PARSENAME(replace(OwnerAddress,',','.'),1);

-- now let's check the new columns :)
select top(10) 
	the_owner_address , 
	the_owner_city , 
	the_owner_state 
from Nashvill_housing..nashvill;

-- let's remove OwnerAddress column ...
ALTER TABLE Nashvill_housing..nashvill
DROP COLUMN OwnerAddress;


-- now let's solve the SoldAsVacant Y & N values 
-- at first let's see SoldAsVacant value counts
select 
	SoldAsVacant,
	count(SoldAsVacant) 
from Nashvill_housing..nashvill
group by SoldAsVacant;

-- now let's update the SoldAsVacant column
update Nashvill_housing..nashvill
set SoldAsVacant = case when SoldAsVacant ='N' then 'No'
when SoldAsVacant = 'Y' then 'Yes'
else SoldAsVacant
end;

-- let's check if it worked 
select 
	SoldAsVacant,
	count(SoldAsVacant) 
from Nashvill_housing..nashvill
group by SoldAsVacant;


--by checking the_owner_state column most of the data is TN and the rest is null
--so let's fill 'em with TN

update Nashvill_housing..nashvill
set 
the_owner_state = case when the_owner_state ='TN' then 'TN'
else the_owner_state
end

/*
ok i know it's confused i'm replacing TN with TN 
apparently TN in the dataset is not the same as just writting TN so if i wanna replace the null values 
i must take a copy of the TN  in the column to avoid having 2 TN with different count number 
when trying to count the values in the_owner_state that i didn't notice before doing it 
 so i 'd to replace it to have one TN only 
*/




-----------------------------------------------------------------------------------------
----------------------------- Housing Data Analysis (SQL) -------------------------------
-----------------------------------------------------------------------------------------

-- Getting a look on out data's properties
describe housing;

-- First look on data
Select * from housing;

-- Maximun, Minimum and Avergae prices for all houses sold.
Select max(Price) as Max_Price, min(price) as Min_price, round(avg(Price),2) as Avg_price from housing;

-- Affect on selling price(average) by number of bedrooms in the house
select round(avg(price), 2) as Avg_price,BEDROOMS from housing group by bedrooms order by 1 desc;

-- Year wise average selling price of houses.
select extract(year from sale_date) as Sale_year, round(avg(price), 2) as Avg_price 
from housing where extract(year from sale_date) <> 2019 group by extract(year from sale_date) order by 1;

-- Affect on prices based on if the house was occupied at the time of sale
select round(avg(price), 2) as Avg_price, soldasvacant from housing group by soldasvacant;

-- Studying prices on every based on the age of the strucuture built
select distinct YEARBUILT from housing order by 1;

Alter table housing add Age_years int;

-- Bucketing ages into groups as (100+, 70+ , 50+, >30) years old 
select yearbuilt, ( case
     when YEARBUILT <=1900  then 100
     when YEARBUILT>1900 and YEARBUILT <= 1950 then 70
     when YEARBUILT>1950 and YEARBUILT <= 2000 then 50
     when YEARBUILT>2000 and YEARBUILT < 2023 then 30
     else YEARBUILT
     END) as dta from housing where yearbuilt is not null order by 1;

update housing set Age_years =
( case
     when YEARBUILT <=1900  then 100
     when YEARBUILT>1900 and YEARBUILT <= 1950 then 70
     when YEARBUILT>1950 and YEARBUILT <= 2000 then 50
     when YEARBUILT>2000 and YEARBUILT < 2023 then 30
     else YEARBUILT
     END) where yearbuilt is not null;
commit;

-- Getting Count for the each age group
select count(1), Age_years from housing group by Age_years;

-- Querying Average prices for each age group.
select round(avg(price), 2) as Avg_price, year_built from housing group by Age_years;


-----------------------------------------------------------------------------------------
----------------------------- END of Housing Data Analysis (SQL) -------------------------------
-----------------------------------------------------------------------------------------

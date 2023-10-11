
-----------------------------------------------------------------------------------------
------------------------------- SQL DATA CLEANING PROJECT -------------------------------
-----------------------------------------------------------------------------------------

-- In this project we will be cleaning our data which can further be used for analysis, ETL etc.

-- Getting a first look on our data
select * from housing where rownum<100;

--------------------------------------------------------------------------
----------------------- Fixing Column Names ------------------------------
--Fixing Column Names to increase readabilty and usability of columns
ALTER TABLE housing RENAME COLUMN uniqueid_ TO Unique_id;
ALTER TABLE housing RENAME COLUMN parcelid TO parcel_id;
ALTER TABLE housing RENAME COLUMN landuse TO land_use;
ALTER TABLE housing RENAME COLUMN propertyaddress TO Address;
ALTER TABLE housing RENAME COLUMN saledate TO sale_date;
ALTER TABLE housing RENAME COLUMN saleprice TO price;


--------------------------------------------------------------------------
----------------------- Fixing Column Datatype ------------------------------
--Standarize date format for SaleDate Column to timestamp format

select sale_date,Cast(Sale_date as TIMESTAMP) as Date_of_Sale from housing;

--------------------------------------------------------------------------
---------------- Populating Null Values for Address Column --------------- 
--Populate Missing Property Adress Data

-- Counting total Nulls for Property Address
select h.*,h.parcel_id from housing h where address is null; -- Initial rows: 29 rows found
select count(*) from housing where address is null; -- Initial Count: 29


-- Creating two temp tables for refernce and to fix data
create table ps as  -- Creaing table with no null values in address column
select distinct parcel_id,address from testdata where address is not null;

create table ps2 as -- Creaing table with only null values in address column
select distinct parcel_id,address from testdata where address is null;

-- Fixing address column in 'ps' table to regularize the values and remove extra spaces
update ps set address = replace(address, '  ', ' ');


-- Deleting duplicates to store only unique 'PARCEL_ID' values in order to merge the data successfully

 Delete from ps a
WHERE
  a.rowid >
   ANY (
     SELECT
        B.rowid
     FROM
        ps B
     WHERE
        A.parcel_id = B.parcel_id
     AND
        A.address = B.address
        );
 
 
-- Merging data from temp table 'PS' into table 'PS2' to poulate address field in table "PS2"

merge into ps2
using ps
on ( ps2.parcel_id = ps.parcel_id)
when matched then update set
    ps2.address = coalesce(ps2.address, ps.address);

-- Merging data from temp table 'PS2' into table 'Housing' to poulate address field in table "Housing"

merge into Housing
using ps2
on ( Housing.parcel_id = ps2.parcel_id)
when matched then update set
    Housing.address = ps2.address
    where Housing.address is null;


select count(*) from housing where address is null;  --  Current Count: 0 Rows



--------------------------------------------------------------------------
----------------------- Splitting Address Column -------------------------

-- Splitting Address into ('Address','City','State') and adding them to HOUSING table

create table SplitAddress as
Select unique_id, 
SUBSTR(housing.address, 1, INSTR(housing.address, ',')-1) AS Prop_Address,
replace(SUBSTR(housing.address, INSTR(housing.address, ',')+1), ' ') AS City,
SUBSTR(housing.owneraddress, -2, INSTR(housing.owneraddress, ',')+1) AS Prop_State
from housing;


Alter table housing add( 
 Prop_address varchar2(128),
 City varchar(50),
 Prop_State varchar2(10)
);


UPDATE 
(SELECT a.City as citytemp,a.prop_address as neww,a.prop_state as statetemp,a.unique_id, b.unique_id,b.prop_address as oldd,
b.city as citytemp_nw, b.prop_state as tmp_state
 FROM SplitAddress a
 INNER JOIN housing b
 ON a.unique_id = b.unique_id
 WHERE a.unique_id <> 0
) t
SET t.oldd = t.neww, 
t.citytemp_nw = t.citytemp,
t.tmp_state = t.statetemp;

commit;

-- The splitting method would be more efficient if data was from different states.
--Since all our Data is for Tennesse only, we will update all Nulls for state Column as 'TN'

select count(*) from housing where prop_state is null; -- Total Count : 30,462 rows rows

update housing set prop_state = 'TN' where prop_state  is null;
Commit;

select count(*) from housing where prop_state is null; -- Total Count : 0 rows

--------------------------------------------------------------------------
----------------------- Making SoldASVacant Binary -----------------------

select count(1),soldasvacant
from housing group by soldasvacant;

Select soldasvacant,
case when soldasvacant = 'Y' then 'YES'
     when soldasvacant = 'N' then 'NO'
     else soldasvacant
End
from housing;

Select soldasvacant,
case when soldasvacant = 'Y' then 'YES'
     when soldasvacant = 'N' then 'NO'
     else soldasvacant
End
from housing;

-- Updating Values to Yes for Y and NO for N
update housing set soldasvacant = 'Yes' where soldasvacant = 'Y';
update housing set soldasvacant = 'No' where soldasvacant = 'N';

--Another Method

Update Housing
set soldasvacant = case when soldasvacant = 'Y' then 'YES'
     when soldasvacant = 'N' then 'NO'
     else soldasvacant
     end;

commit;


-----------------------------------------------------------------------
------------------- Removing duplicates from Data ---------------------

--Retrieving all duplicated data from housing table
select parcel_id, address,price,sale_date,count(1) as countt 
from housing group by parcel_id,address,price,sale_date having count(1)>1;

--Creating temp table for all duplicity found
create table datatemp11 as
select parcel_id, address,price,sale_date,count(1) as countt 
from housing group by parcel_id,address,price,sale_date having count(1)>1;

-- We have multiple records with same data, but with unique_id is a unique for each row, hence we take max(unique_id) for the rows for each duplicate data
-- This gives a single instance for each duplicate row stored in duplicatd table
create table duplicatd as  
select max(UNIQUE_ID) as u_id from  housing b where (PARCEL_ID,ADDRESS,SALE_DATE,Price) 
 in (select PARCEL_ID,ADDRESS,SALE_DATE,Price  from datatemp11 a);

-- By referencing both temp tables created above we delete all mutiple records without deleting the rows with max(unique_id)
-- For every multiple records present in data
delete from housing where parcel_id in (select parcel_id from datatemp11) and unique_id not in (select u_id from duplicatd);


--OR
-- This method will only remove duplicity of 2, above method will remove multiple rows
delete from housing where UNIQUE_ID not in (select max(UNIQUE_ID) from  housing b where (PARCEL_ID,ADDRESS,SALE_DATE,Price) 
 in (select PARCEL_ID,ADDRESS,SALE_DATE,Price  from datatemp11 a) and parcel_id in (select parcel_id from datatemp11)
 group by PARCEL_ID);

commit;

-----------------------------------------------------------------------
------------------- Removing Redundant Colummns -----------------------

describe housing;

alter table housing drop (LEGALREFERENCE,ownername,owneraddress);

----------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------- End of Data Cleaning Project -------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--Setup_ASA_Migration_User_Sample.sql 
--
----------------------------------------------------------------------------------------------

--###########################################################################

-- Document on ASA best practices and T-SQL Scripts to create users 
-- https://docs.microsoft.com/en-us/azure/sql-data-warehouse/guidance-for-loading-data

-- Tutorial: Load data to Azure SQL Data Warehouse
-- https://docs.microsoft.com/en-us/azure/sql-data-warehouse/load-data-wideworldimportersdw

-- Create Login as SQLDW admin 
-- Connect to master
	CREATE LOGIN Migration WITH PASSWORD = 'Str0ng_password!';
-- ALTER LOGIN Migration WITH PASSWORD = 'NewPassword'; -- Change password 
   
-- Create User 
-- Connect to the database
   CREATE USER Migration FOR LOGIN Migration;
   GRANT CONTROL ON DATABASE::[yourazuresqldwdbname] to Migration; --yourazuresqldwdbname: your actual db name 

-- Migration User needs below previlledges
-- CREATE/DROP SCHEMA 
-- CREATE/DROP TABLE 
-- CREATE/DROP DATABASE SCOPED CREDENTIAL 
-- CREATE/DROP CREATE EXTERNAL DATA SOURCE
-- CREATE/DROP CREATE EXTERNAL FILE FORMAT


-- Assign Resource Classes for user 
-- Reference on Resource Classes: 
-- https://docs.microsoft.com/en-us/azure/sql-data-warehouse/resource-classes-for-workload-management
-- Connect to the database
-- EXEC sp_addrolemember 'staticrc80', 'Migration';
   EXEC sp_addrolemember 'largerc', 'Migration';


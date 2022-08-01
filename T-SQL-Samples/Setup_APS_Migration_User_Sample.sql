
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Setup_APS_Migration_User_Sample.sql 
--
----------------------------------------------------------------------------------------------
--###############################################################################
-- Check current member roles  
-- connect to master 
SELECT sys.server_role_members.role_principal_id, role.name AS RoleName,   
    sys.server_role_members.member_principal_id, member.name AS MemberName  
FROM sys.server_role_members  
JOIN sys.server_principals AS role  
    ON sys.server_role_members.role_principal_id = role.principal_id  
JOIN sys.server_principals AS member  
    ON sys.server_role_members.member_principal_id = member.principal_id;
---------------------------------------------------------------------------------


--###############################################################################
-- Set up Migration User in APS 
-- Add roles permissions to the Migration User 
-- https://docs.microsoft.com/en-us/sql/analytics-platform-system/pdw-permissions?view=aps-pdw-2016-au7#fixed-database-roles

-- Migration User needs below previlledges
-- CREATE/DROP SCHEMA 
-- CREATE/DROP TABLE 
-- CREATE/DROP DATABASE SCOPED CREDENTIAL 
-- CREATE/DROP CREATE EXTERNAL DATA SOURCE
-- CREATE/DROP CREATE EXTERNAL FILE FORMAT


--###############################################################################
-- Create Login at SQL Server level 
-- Connect to master database and create a login
CREATE LOGIN Migration WITH PASSWORD = 'Str0ng_password!';
-- ALTER LOGIN Migration WITH PASSWORD = 'NewPassword'; -- Change password 

-- Create database user (Migration User) at DB Level 
-- Connect to particular DB such as AdventureWorks
CREATE USER Migration FOR LOGIN Migration;  
 
-- Example Resource Classes: smallrc, mediumrc, largerc, xlargerc
ALTER SERVER ROLE largerc ADD MEMBER Migration;  

-- Grant DB control previledges 
--https://docs.microsoft.com/en-us/sql/analytics-platform-system/grant-permissions?view=aps-pdw-2016-au7
USE AdventureWorks;  -- replace "AdventureWorks" with your actual APS DB name 
GO  
GRANT CONTROL ON DATABASE::AdventureWorks TO Migration;  

-- or 
EXEC sp_addrolemember 'db_owner', 'Migration'

-- If db_owner can be granted, need below permissions 
EXEC sp_addrolemember 'db_ddladmin', 'Migration'
EXEC sp_addrolemember 'db_datareader', 'Migration'
EXEC sp_addrolemember 'db_datawriter', 'Migration'



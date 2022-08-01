
--##########################################################
-- Setup Polybase for APS export 
--##########################################################

--#################################################################################
-- APS 2016 or Later 
--#################################################################################

-- Modify ‘Hadoop Connectivity’ PDW configuration option to enable BLOB connectivity 
-- APS Documentations for PDW 2016-AU 7 
--https://docs.microsoft.com/en-us/sql/analytics-platform-system/polybase-configure-azure-blob-storage?view=aps-pdw-2016-au7

-- use a login that is member of sysadmin role and execute the following query:

SELECT @@VERSION -- 7.5 

--USE master 
-- Example: value 7 stands for Hortonworks HDP 2.1 to 2.6 on Linux,
-- 2.1 to 2.3 on Windows Server, and Azure Blob storage  
sp_configure @configname = 'hadoop connectivity', @configvalue = 7;
GO

RECONFIGURE
GO

-- Restart PDW Region 
Restart PDW Region -- Need PFE to help with this. Instruction below: 
--   Launch the Configuration Manager in Analytics Platform System
--https://docs.microsoft.com/en-us/sql/analytics-platform-system/launch-the-configuration-manager?view=aps-pdw-2016-au7


-- connect to master 
-- Create a Master Key on the database (if not already done)
-- Check to see if the master key is encrypted by the service master key 
-- SELECT name, is_master_key_encrypted_by_server FROM sys.databases
-- Use this query to create a database master key in the master database. They key is encrypted by this password  
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssword!23';
-- or open the key if the above step is already performed. 
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'P@ssword!23'  -- you can try password for 'sa' account 


--#################################################################################
-- Pre APS 2016 
--#################################################################################

-- Step 01
-- Modify core-site.xml file on PDW control node to add Azure BLOB storage credentials
------ This file is available under C:\Program Files\Microsoft SQL Server Parallel Data Warehouse\100\Hadoop\conf\
/* 
Add/Modify the following property node in this file with the Azure storage credentials. 
<property>
  <name>fs.azure.account.key.<your storage account name>.blob.core.windows.net</name>
  <value><your storage account access key></value>
</property>
*/

-- Step 02
--Modify ‘Hadoop Connectivity’ PDW configuration option to enable BLOB connectivity
-- Ex: EXEC sp_configure 'hadoop connectivity', 4; 
-- RECONFIGURE;

EXEC sp_configure 'hadoop connectivity', 7; -- value 4 works as well 
--EXEC sp_configure 'hadoop connectivity', @configvalu=7;
GO

RECONFIGURE;
GO

RESTART PDW REGION 
-- Step 03: Restart PDW region
-- 

-- Rest of the steps are the same as APS 2016 or later 
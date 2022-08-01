---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--Setup_ASA_Import_Sample.sql 
--
---------------------------------------------------------------------------------------------
-- SQLDW Setup for Importing Data from Azure Blob Storage 

--##########################################################################################
-- Reference 
--https://docs.microsoft.com/en-us/azure/sql-data-warehouse/guidance-for-loading-DATA
--https://docs.microsoft.com/en-us/azure/sql-data-warehouse/load-data-wideworldimportersdw
--##########################################################################################

-- Step 0 - Perform this only if it is needed 
-- You only need to do this once. 
 CREATE MASTER KEY 
-- or
 CREATE MASTER KEY [ ENCRYPTION BY PASSWORD ='Str0ngPassword!' ]
-- or 
--OPEN MASTER KEY DECRYPTION BY PASSWORD 'Str0ngPassword!'


--##########################################################################################
-- Step 1. CREATE DATABASE SCOPED CREDENTIAL
-- create using admin or migration user, connect to azure sql DB 

CREATE DATABASE SCOPED CREDENTIAL credentialname
WITH IDENTITY = 'Blob Storage',  
SECRET = 'SampleSampleSampleSampleSampleSample5akd1wpWw==' --Storage Access Key



--##########################################################################################
-- Step 2. Create External Data Source Pointing to Azure Blob Storage Account 
-- Create using admin migration user, connected to azure sql DB 

CREATE EXTERNAL DATA SOURCE datasourcename with (  
    	TYPE = HADOOP,
        	LOCATION = 'wasbs://pocmigrations@blobaccountname.blob.core.windows.net',  -- blobaccountname: replace w actual name
        	CREDENTIAL = credentialname --This name must match the database scoped credential name 
				)

				
--##########################################################################################
-- Step 3. Create File Format (Matching the Data Files Stored in Azure Blob Storage) 
-- Connected to azure sql DB 

-- Parquet Format 
CREATE EXTERNAL FILE FORMAT ParquetFile
WITH (  
    FORMAT_TYPE = PARQUET,  
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'  
);

-- Text Delimited, No Zip 
CREATE EXTERNAL FILE FORMAT DelimitedNoDateNoZip
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = '|#|',
          STRING_DELIMITER = '"',
          DATE_FORMAT = '',
          USE_TYPE_DEFAULT = False)
	)

-- Text Delimited, Zipped
CREATE EXTERNAL FILE FORMAT DelimitedNoDateZip
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = '|#|',
          STRING_DELIMITER = '"',
          DATE_FORMAT = '',
          USE_TYPE_DEFAULT = False),
      DATA_COMPRESSION = 'org.apache.hadoop.io.compress.GzipCodec'
	)

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Step 4. Create External Tables in Azure SQL DW and Export Data Into Azure Blob Storage
-- Connected to azure sql DB 


CREATE SCHEMA poc_migrations_text

CREATE SCHEMA poc_migrations_parquet


CREATE external TABLE [poc_migrations_text].[customer] (
   [c_custkey] [bigint] NULL,
	[c_name] [varchar](25) NULL,
	[c_address] [varchar](40) NULL,
	[c_nationkey] [int] NULL,
	[c_phone] [char](15) NULL,
	[c_acctbal] [decimal](15, 2) NULL,
	[c_mktsegment] [char](10) NULL,
	[c_comment] [varchar](117) NULL
)
WITH (  
                LOCATION='/text/tbl_customer/',
                DATA_SOURCE = datasourcename,  
                FILE_FORMAT = DelimitedNoDateNoZip

)
--Test external data
--SELECT * FROM [poc_migrations_text].[customer]
--
-- Create Internal Table to hold the imported data 
CREATE TABLE [dbo].[customer]
(
	[c_custkey] [bigint] NULL,
	[c_name] [varchar](25) NULL,
	[c_address] [varchar](40) NULL,
	[c_nationkey] [int] NULL,
	[c_phone] [char](15) NULL,
	[c_acctbal] [decimal](15, 2) NULL,
	[c_mktsegment] [char](10) NULL,
	[c_comment] [varchar](117) NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED INDEX
	(
		[c_custkey] ASC
	)
)


-- Import the data from external table into internal table
INSERT INTO adw_dbo.customer
  SELECT * FROM [poc_migrations_text].[customer] 
	Option(Label = 'Import_Table_adw_dbo.customer')

-- Test Import Results
-- Select * from adw_dbo.customer

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
-- Step 5. Optinal 
-- Test exporting to blob from ASA 
CREATE EXTERNAL TABLE [poc_migrations_text].[customer_exported]
WITH (
	  LOCATION='/text/tbl_customer_export_from_asa/',
      DATA_SOURCE = datasourcename,
      FILE_FORMAT = DelimitedNoDateNoZip,
      REJECT_TYPE = VALUE,
      REJECT_VALUE = 0
)
AS
SELECT * from [dbo].[customer] 



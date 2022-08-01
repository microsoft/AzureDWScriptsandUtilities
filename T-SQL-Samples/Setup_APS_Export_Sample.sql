---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--Setup_APS_Export_Sample.sql 
--
----------------------------------------------------------------------------------------------

--######################################################################################################
-- Step 1: Create Database Scoped Credential (linked to Azure Blob Storage Account) 
--######################################################################################################

-- connect to a particular db
-- Create a database scoped credential
CREATE DATABASE SCOPED CREDENTIAL credentialname
WITH IDENTITY = 'Blob Storage',  
SECRET = 'SampleSampleSampleSampleSampleSample5akd1wpWw=='   --Storage Access Key


--######################################################################################################
-- Step 2: Create External Data Source (Link to a particular container of the Azure Blob Storage Account)
--######################################################################################################

--SELECT * FROM sys.external_data_sources

-- Connect to particialr APS DB
CREATE EXTERNAL DATA SOURCE datasourcename with (  
    	TYPE = HADOOP,
        	LOCATION = 'wasbs://pocmigrations@blobaccountname.blob.core.windows.net',  -- blobaccountname: replace w actual name
        	CREDENTIAL = credentialname --This name must match the database scoped credential name 
				)


--######################################################################################################
-- Step 3: Create External File Format
--######################################################################################################

--SELECT * FROM sys.external_file_formats

-- Connect to particular APS DB 
CREATE EXTERNAL FILE FORMAT ParquetFile
WITH (  
    FORMAT_TYPE = PARQUET,  
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'  
);


CREATE EXTERNAL FILE FORMAT DelimitedNoDateZip
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = '|#|',
          STRING_DELIMITER = '"',
          DATE_FORMAT = '',
          USE_TYPE_DEFAULT = False),
      DATA_COMPRESSION = 'org.apache.hadoop.io.compress.GzipCodec'
	)

CREATE EXTERNAL FILE FORMAT DelimitedNoDateNoZip
WITH (FORMAT_TYPE = DELIMITEDTEXT,
      FORMAT_OPTIONS(
          FIELD_TERMINATOR = '|#|',
          STRING_DELIMITER = '"',
          DATE_FORMAT = '',
          USE_TYPE_DEFAULT = False)
	)


--######################################################################################################
-- Step 4: Export Data 
--######################################################################################################

--SELECT * from sys.schemas

CREATE SCHEMA poc_migrations_text
CREATE SCHEMA poc_migrations_parquet


--Text Format 
-- Table 1
CREATE EXTERNAL TABLE [poc_migrations_text].[orders]
WITH (LOCATION='/text/tbl_orders/',
	  DATA_SOURCE = datasourcename,
      FILE_FORMAT = DelimitedNoDateNoZip,
      REJECT_TYPE = VALUE,
      REJECT_VALUE = 0
)
As Select * from [tpch].[dbo].[orders]
-- Table 2
CREATE EXTERNAL TABLE [poc_migrations_text].[customer]
WITH (LOCATION='/text/tbl_customer/',
	  DATA_SOURCE = datasourcename,
      FILE_FORMAT = DelimitedNoDateNoZip,
      REJECT_TYPE = VALUE,
      REJECT_VALUE = 0
)
As Select * from [tpch].[dbo].[customer]


--Parquet Format 
-- Table 1
CREATE EXTERNAL TABLE [poc_migrations_parquet].[orders]
WITH (LOCATION='/parquet/tbl_orders/',
	  DATA_SOURCE = datasourcename,
      FILE_FORMAT = ParquetFile,
      REJECT_TYPE = VALUE,
      REJECT_VALUE = 0
)
As Select * from [tpch].[dbo].[orders]
-- Table 2
CREATE EXTERNAL TABLE [poc_migrations_parquet].[customer]
WITH (LOCATION='/parquet/tbl_customer/',
	  DATA_SOURCE = datasourcename,
      FILE_FORMAT = ParquetFile,
      REJECT_TYPE = VALUE,
      REJECT_VALUE = 0
)
As Select * from [tpch].[dbo].[customer]


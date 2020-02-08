#
# RunDSQLScriptsDriver.ps1
#
# FileName: RunDSQLScriptsDriver.ps1
# =================================================================================================================================================
# Scriptname: RunDSQLScriptsDriver.ps1
# 
# Change log:
# Created: Jan 24, 2017
# Author: Andy Isley
# Company: 
# 
# =================================================================================================================================================
# Description:
#       Driver run a .sql or .dsql script against a SQL/SQLDW/APS Server
#
# =================================================================================================================================================


# =================================================================================================================================================
# REVISION HISTORY
# =================================================================================================================================================
# Date: 
# Issue:  Initial Version
# Solution: 
# 
# =================================================================================================================================================

# =================================================================================================================================================
# FUNCTION LISTING
# =================================================================================================================================================
# Function:
# Created:
# Author:
# Arguments:
# =================================================================================================================================================
# Purpose:
#
# =================================================================================================================================================
#
# Notes: 
#
# =================================================================================================================================================
# SCRIPT BODY
# =================================================================================================================================================

function Display-ErrorMsg($ImportError, $ErrorMsg)
{
	Write-Host $ImportError
}

Function GetPassword($securePassword)
{
       $securePassword = Read-Host "PDW Password" -AsSecureString
       $P = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
       return $P
}

Function GetDropStatement
{ [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$SchemaName, 
    [Parameter(Position=1, Mandatory=$false)] [string]$ObjectName,
    [Parameter(Position=2, Mandatory=$true)] [string]$ObjectType
    ) 

    if($ObjectType.TOUpper() -eq "TABLE")
    {
		$Query = "If Exists(Select 1 From sys.tables t Where t.name = '" + $ObjectName + "' and schema_name(schema_id) = '" + $SchemaName + "') drop table [" + $SchemaName + "].[" + $ObjectName + "]"
    }
    elseif($ObjectType.TOUpper() -eq "VIEW")
    {
        $Query = "If Exists(Select 1 From sys.views t Where t.name = '" + $ObjectName + "' and schema_name(schema_id) = '" + $SchemaName + "') drop View [" + $SchemaName + "].[" + $ObjectName + "]"
    }
    elseif($ObjectType.TOUpper() -eq "SP")
    {
        $Query = "If Exists(Select 1 From sys.Objects t Where t.type = 'P' and t.name = '" + $ObjectName + "' and schema_name(schema_id) = '" + $SchemaName + "') drop Proc [" + $SchemaName + "].[" + $ObjectName + "]"
    }
    elseif($ObjectType.TOUpper() -eq "SCHEMA")
    {
        $Query = "If Exists(Select 1 From sys.schemas t Where t.name = '" + $ObjectName + "' and schema_name(schema_id) = '" + $SchemaName + "') drop schema [" + $SchemaName + "]"       
	}
	elseif($ObjectType.TOUpper() -eq "EXT")
    {
        $Query = "If Exists(Select 1 From sys.Objects t Where t.name = '" + $ObjectName + "' and schema_name(schema_id) = '" + $SchemaName + "') drop external Table [" + $SchemaName + "].[" + $ObjectName + "]"    
	}
	##elseif($ObjectType.TOUpper() -eq "STAT")
	##{
	##	$Query = "If Exists(Select 1 From sys.schemas t Where t.name = '" + $ObjectName + "' and schema_name(schema_id) = '" + $SchemaName + "') drop schema [" + $SchemaName + "]"
	##}
	else {$Query = ""}

    #write-host $query

	return $Query
		
}


Function GetSchemaStatement
{ [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$SchemaName, 
    [Parameter(Position=1, Mandatory=$false)] [string]$SchemaAuth
    ) 

	$Query = "IF NOT EXISTS(SELECT * FROM [INFORMATION_SCHEMA].[SCHEMATA] WHERE [SCHEMA_NAME] = '" + $SchemaName + "') 
                BEGIN
	                EXEC('CREATE SCHEMA " + $SchemaName

	If($SchemaAuth -ne "")
		{
			$Query = $Query + " AUTHORIZATION [" +  $SchemaAuth + "]"
		}

    $Query = $Query + "') END"
	
	return $Query
		
}

Function GetTruncateStatement
{ [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$SchemaName, 
    [Parameter(Position=1, Mandatory=$false)] [string]$ObjectName,
    [Parameter(Position=2, Mandatory=$true)] [string]$ObjectType
    ) 

    if($ObjectType.TOUpper() -eq "TABLE")
    {
		$Query = "If Exists(Select 1 From sys.tables t Where t.name = '" + $ObjectName + "' and schema_name(schema_id) = '" + $SchemaName + "') Truncate table [" + $SchemaName + "].[" + $ObjectName + "]"
    }
 	else {$Query = ""}

    #write-host $query

	return $Query
		
}

$ReturnValues = @{}


$error.Clear()

##############################################################
# Config File Input 
#############################################################


$defaultScriptsToRunDriverFile = "C:\Temp\SqldwImportData.csv"

$ScriptsToRunDriverFile = Read-Host -prompt "Enter the name of the ScriptToRun csv File or Press 'Enter' to accept default: [$defaultScriptsToRunDriverFile]"
	if($ScriptsToRunDriverFile -eq "" -or $ScriptsToRunDriverFile -eq $null)
	{$ScriptsToRunDriverFile = $defaultScriptsToRunDriverFile}

$ConnectToSQLDW = Read-Host -prompt "How do you want to connect to SQL(ADPass, ADInt, WinInt, SQLAuth)?"
	#if($ConnectToSQLDW.ToUpper() -ne "YES") 
	#{$UseIntegrated = Read-Host -prompt "Enter Yes to connect with integrated Security."
	#	if($UseIntegrated.ToUpper() -eq "" -or $UseIntegrated -eq $null) {$UseIntegrated = "YES"}
	#}
$ConnectToSQLDW = $ConnectToSQLDW.ToUpper()
If($ConnectToSQLDW.ToUpper() -eq "SQLAUTH" -or $ConnectToSQLDW.ToUpper() -eq "ADPASS")
{
	$UserName = Read-Host -prompt "Enter the UserName if not using Integrated."
		if($UserName -eq "" -or $UserName -eq $null) {$UserName = "sqladmin"}
	$Password = GetPassword
		if($Password -eq "") {Write-Host "A password must be entered"
							break}
}
$StatusLogPath = Read-Host -prompt "Enter the name of the Output File Directory."
	if($StatusLogPath -eq "" -or $StatusLogPath -eq $null) {$StatusLogPath =  "C:\temp"}
$StatusLog = Read-Host -prompt "Enter the name of the status file."
	if($StatusLog -eq "" -or $StatusLog -eq $null) {$StatusLog = "CreateExtInsert_V1.csv"}


$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
. "$ScriptPath\RunSQLScriptFile.ps1"  ##use this if using Powershell ver 2
#. "$PSCommandPath\RunSQLStatementExportCSV.ps1" ##use this if using Powershell ver 3+

if (!(test-path $StatusLogPath))
	{
		New-item "$StatusLogPath\" -ItemType Dir | Out-Null
	}

$StatusLogFile = $StatusLogPath + "\" + $StatusLog 

#Try{
$csvFile = Import-Csv $ScriptsToRunDriverFile
#}
#Catch [System.IO.DirectoryNotFoundException]{
#	Display-ErrorMsg("Unable to import PreAssessment csv File: " + $APSPreAssessmentDriverFile)
#}

#Get the header Row
$HeaderRow = "Active","ServerName","DatabaseName","FilePath","CreateSchema","SchemaAuth","ObjectType","ObjectName","FileName","DropTruncateIfExists","SchemaName","Variables","Status","RunDurationSec"
$HeaderRow  -join ","  >> $StatusLogFile

$StartDateBegin=(Get-Date)

ForEach ($S in $csvFile ) 
{
    $StartDate=(Get-Date)
	$Active = $S.Active
	$RunStatement = 1
    if($Active -eq '1') 
	{
        $ServerName = $S.ServerName
		$DatabaseName = $S.DatabaseName
		$FilePath = $S.FilePath
		$FileName = $S.FileName
		$DropTruncateIfExists = $S.DropTruncateIfExists.TOUpper()
		$SchemaName = $S.SchemaName
		$ObjectName = $S.ObjectName
        $CreateSchema = $S.CreateSchema
        $SchemaAuth = $S.SchemaAuth
        $ObjectType = $S.ObjectType
		$Variables = $S.Variables
		
		
		
		$ScriptToRun = $FilePath + "\" +$FileName
		
		if($DropTruncateIfExists -eq 'DROP')
		{
            $Query = GetDropStatement -SchemaName $SchemaName -objectName $ObjectName -ObjectType $ObjectType
            
            $ReturnValues = RunSQLScriptFile -ServerName $ServerName -Username $UserName -Password $Password -SQLDWADIntegrated $ConnectToSQLDW -Database $DatabaseName -Query $Query #-SchemaName $SchemaName -TableName $TableName -DropIfExists $DropIfExists -StatusLogFile $StatusLogFile
		}
		elseif($DropTruncateIfExists -eq 'TRUNCATE')
		{
			$Query = GetTruncateStatement -SchemaName $SchemaName -objectName $ObjectName -ObjectType $ObjectType

			$ReturnValues = RunSQLScriptFile -ServerName $ServerName -Username $UserName -Password $Password -SQLDWADIntegrated $ConnectToSQLDW -Database $DatabaseName -Query $Query 
		}
        #elseif($DropTruncateIfExists -eq '' -or [string]::IsNullOrEmpty($DropTruncateIfExists))
		else        
		{
			$RunStatement = 0
		}

        if($ReturnValues.Get_Item("Status") -eq 'Success' -or $RunStatement -eq 0)
		{
            If($CreateSchema -eq 1) 
            {
                #$ScriptToRun = $(resolve-path $ScriptToRun).path 
                #$Query =  [System.IO.File]::ReadAllText("$ScriptToRun")
				$Query = GetSchemaStatement -SchemaName $SchemaName -SchemaAuth $SchemaAuth
				             
                #Create schema:             
                $ReturnValues = RunSQLScriptFile -ServerName $ServerName -Username $UserName -Password $Password -SQLDWADIntegrated $ConnectToSQLDW -Database $DatabaseName -Query $Query -Variables $Variables #-SchemaName $SchemaName -TableName $TableName -DropIfExists $DropIfExists -StatusLogFile $StatusLogFile
                
                #Create object:
                $ReturnValues = RunSQLScriptFile -ServerName $ServerName -Username $UserName -Password $Password -SQLDWADIntegrated $ConnectToSQLDW -Database $DatabaseName -InputFile $ScriptToRun -Variables $Variables #-SchemaName $SchemaName -TableName $TableName -DropIfExists $DropIfExists -StatusLogFile $StatusLogFile
             
            }
            else
            {
		        $ReturnValues = RunSQLScriptFile -ServerName $ServerName -Username $UserName -Password $Password -SQLDWADIntegrated $ConnectToSQLDW -Database $DatabaseName -InputFile $ScriptToRun -Variables $Variables #-SchemaName $SchemaName -TableName $TableName -DropIfExists $DropIfExists -StatusLogFile $StatusLogFile
            }
		}

		if($ReturnValues.Get_Item("Status") -eq 'Success')
		{
            $EndDate=(Get-Date)
            $Timespan = (New-TimeSpan -Start $StartDate -End $EndDate)
            $DurationSec = ($Timespan.seconds + ($Timespan.Minutes * 60) + ($Timespan.Hours * 60 * 60))
            $Message = "Process Completed for File: " + $FileName + " Duration: " + $DurationSec
	  		Write-Host $Message -ForegroundColor White -BackgroundColor Black
			$Status = $ReturnValues.Get_Item("Status")

			$HeaderRow = 0,$ServerName,$DatabaseName,$FilePath,$CreateSchema,$SchemaAuth,$ObjectType,$ObjectName,$FileName,$DropTruncateIfExists,$SchemaName,$Variables,$Status,$DurationSec
			$HeaderRow  -join ","  >> $StatusLogFile
	   	}
    	else
    	{
             $EndDate=(Get-Date)
             $Timespan = (New-TimeSpan -Start $StartDate -End $EndDate)
             $DurationSec = ($Timespan.seconds + ($Timespan.Minutes * 60) + ($Timespan.Hours * 60 * 60))
             $ErrorMsg = "Error running Script for File: " + $FileName + "Error: " + $ReturnValues.Get_Item("Msg") + "Duration: " + $DurationSec + " Seconds"
    		 Write-Host $ErrorMsg -ForegroundColor Red -BackgroundColor Black
			 $Status = "Error: " + $ReturnValues.Get_Item("Msg")
			 $Status = $Status.Replace("`r`n", "")
			 $Status = '"' + $Status.Replace("`n", "") + '"'
			 $HeaderRow = $Active,$ServerName,$DatabaseName,$FilePath,$CreateSchema,$SchemaAuth,$ObjectType,$ObjectName,$FileName,$DropTruncateIfExists,$SchemaName,$Variables,$Status,$DurationSec
			 $HeaderRow  -join ","  >> $StatusLogFile
			 $Status = ""
    	}
	}
	else
	{       
		$ServerName = $S.ServerName
		$DatabaseName = $S.DatabaseName
		$FilePath = $S.FilePath
		$FileName = $S.FileName
		$DropTruncateIfExists = $S.DropTruncateIfExists.TOUpper()
		$SchemaName = $S.SchemaName
		$ObjectName = $S.ObjectName
		$ObjectType = $S.ObjectType
		$CreateSchema = $S.CreateSchema
        $SchemaAuth = $S.SchemaAuth
		$Variables = $S.Variables
		
        $EndDate=(Get-Date)
        $Timespan = (New-TimeSpan -Start $StartDate -End $EndDate)
    	$DurationSec = ($Timespan.seconds + ($Timespan.Minutes * 60) + ($Timespan.Hours * 60 * 60))
		if($Active -eq 2)
		{
			$Status = 'Status = ' + $Active + ' Process skipped.'
		}
		else 
		{
			$Status = 'Status = ' + $Active + ' Process did not run.'	
		}
		$Status = 'Status = ' + $Active + ' Process did not run.'
		$HeaderRow = $Active,$ServerName,$DatabaseName,$FilePath,$CreateSchema,$SchemaAuth,$ObjectType,$ObjectName,$FileName,$DropTruncateIfExists,$SchemaName,$Variables,$Status,$DurationSec
		$HeaderRow  -join ","  >> $StatusLogFile
	}

}
$EndDate=(Get-Date)
$DurationMin = (New-TimeSpan -Start $StartDateBegin -End $EndDate).Min
Write-Host "Duration in Min: " + $DurationMin
$DurationHours = (New-TimeSpan -Start $StartDateBegin -End $EndDate).Hours
Write-Host "Duration in Hours: " + $DurationHours


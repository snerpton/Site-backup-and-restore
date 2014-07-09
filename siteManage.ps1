# This is the final script... maybe
# Author: Chris Ashton
# Company: Blueprint Web Tech
# Date: 18 July 2013
#
# Following comments taken from previous iterations...
#
#
# Idea taken from:
#http://learningpcs.blogspot.co.uk/2012/01/powershell-v2-unzip-files-without.html
#
# http://andrewmorgan.ie/2011/12/14/backup-and-restore-sql-databases-using-powershell/
# import-module c:\sql.backup.psm1
# restore-SQLdatabase -SQLServer "TAMARYN_PC" -SQLDatabase "SafetySystemsUmbraco" -Path "C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\SafetySystemsUmbraco_db_201304121355.BAK" -TrustedConnection
#
# Requires modules:
# - Pscx-2.1.1

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$configFile,
	
   [Parameter(Mandatory=$True)]
   [string]$command
)

# Stop on first error!
$ErrorActionPreference = "Stop"

#param([String[]] $configFile, $cmds)

# -----------------------------------------------------------------------------
# START: configuration
# -----------------------------------------------------------------------------

#$domainStart = "brit-thoracic"
#$domainEndRmt = "blueprintwebtech.com"
#$domainEndLocal = "local"
#
#$bkupFilesSrcDir = "C:\inetpub\wwwSites\$domainStart.$domainEndLocal"  # Directory we are backing up. e.g. C:\inetpub\wwwSites\somedomain.local
#$bkupFilesTargetFileZip = "C:\tmp\$domainStart.$domainEndLocal.zip"    # Directory the backup will be placed e.g. C:\tmp 
#$bkupDbSrcDb = "$domainStart.$domainEndLocal"                          # Database we are backing up
#$bkupDbTargetDir = "C:\tmp"
#$bkupDbTargetFile = "$bkupDbSrcDb.bak"
#
#$restoreFilesSrcFileZip = "C:\tmp\$domainStart.$domainEndLocal.zip"    # Zip file containing the website files we are going to restore.
#$restoreFilesTargetDir = "C:\inetpub\$domainStart.$domainEndRmt"
#$restoreDbSrcDbZip = "C:\tmp\$domainStart.$domainEndLocal.bak.zip"
#$restoreDbTargetDir = "C:\tmp\"
#$restoreDbNewName = "$domainStart.$domainEndRmt"
# -----------------------------------------------------------------------------
# END: configuration
# -----------------------------------------------------------------------------



##### Utility functions #####

function UnZipMe($zipfilename,$destination) 
{ 
    $shellApplication = new-object -com shell.application 
    $zipPackage = $shellApplication.NameSpace($zipfilename) 
    $destinationFolder = $shellApplication.NameSpace($destination) 
    Write-Host "zipPackage: $zipPackage"
    Write-Host "destinationFolder: $destinationFolder"
    #$destinationFolder.CopyHere($zipPackage.Items(),20)
    #   4 = Do not display a progress dialog box. 
    #  16 = Respond with "Yes to All" for any dialog box that is displayed.
    # 256 = Display a progress dialog box but do not show the file names.
    $destinationFolder.CopyHere($zipPackage.Items(),272)
} 



function ZipMe($src,$zipFile)
{
    Write-Host "Zipping files..."
    Import-Module PSCX
    #Get-ChildItem C:\inetpub\lyonswilson-solicitors.co.uk\* | Write-Zip -OutputPath C:\tmp\lyonswilson-solicitors.co.uk.zip
    gci $src -rec | Write-Zip -EntryPathRoot $src -OutputPath $zipFile
}



function CreateDirIfNeeded($dir)
{
    # Create folder if it doesn't exist 
     if (!(Test-Path -path $dir)) {
        Write-Host "Creating $dir"
        New-Item $dir -Type Directory
        Write-Host "Created $dir"
     }
}



##### Actual functions we use in main #####
function CreateBackupFiles($srcDir, $destZip)
{
    Write-Host "Backing up files..."
    Write-Host "srcDir: $srcDir"
    Write-Host "destZip: $destZip"
    ZipMe -src $srcDir -zipFile $destZip
}

function CreateBackupDb($database, $targetDir, $targetFile)
{
    Write-Host "Backing up database..."
    Write-Host "Backing up database: $database"
    Write-Host "Dir destination: $targetDir"
    Write-Host "File (.bak) destination: $targetFile"
    DbBackup -database $database -targetDir $targetDir -targetFile $targetFile
}

function RestoreFiles()
{
    Write-Host "--> Restoring website files..."
    $zipFile = gi -Path $restoreFilesSrcFileZip
    $destinationDir = gi -Path $restoreFilesTargetDir
    Write-Host "--> src:  $zipFile"
    Write-Host "--> dest: $destinationDir"
    UnZipMe –zipfilename $zipFile.FullName -destination $destinationDir.Fullname
}

function RestoreDb($dbSrcFileDir, $dbSrcFileBak, $dbNewName)
{
    Write-Host "Restoring database..."
    Write-Host "dbSrcFileDir: $dbSrcFileDir"
    Write-Host "dbSrcFileBak: $dbSrcFileBak"
    Write-Host "dbNewName: $dbNewName"
    DbRestoreNewName -srcDir $dbSrcFileDir -scrFile $dbSrcFileBak -dbNewName $dbNewName
}


##### Main program #####

function Help()
{
    Write-Host "--> Backup commands:"
    Write-Host "-->     BackupWebsite    Full backup of the website files and database."
    Write-Host "-->     BackupDatabase   Backup database only."
    Write-Host "-->     BackupFiles      Backup files only."
    Write-Host "--> "
    Write-Host "--> Restore commands:"
    Write-Host "-->     RestoreWebsite   Restore both website files and database."
    Write-Host "-->     RestoreFiles     Restore file only."
    Write-Host "-->     RestoreDatabase  Restore database only."
    Write-Host "-->     RestoreDatabase  Restore database only."
    Write-Host "--> "
    Write-Host "--> Other commands:"
    Write-Host "-->     GenerateSampleConfig    Generates a sample script configuration file."
    Write-Host "-->     Help                    This help function."
    Write-Host "--> "
    Write-Host "    "
}


function GenerateSampleConfig()
{
'
###############################################################################
### Some general settings #####################################################
###############################################################################
# Full domain of the backedup website files and database.
# e.g "company-dev.some-domain.com"
$bkupDomain = "company-dev.some-domain.com"

# Full domain of restored website files and database.
# e.g "some-domain.local"
$restoreDomain = "some-domain.local"

# Date-time stamp
$dateTime = get-date -format "yyMMdd-hhmmss"

###############################################################################
# Backup settings #############################################################
###############################################################################
# The directory we are backing up. 
# e.g "C:\inetpub\www-dev\$restoreDomain"
#  or "C:\inetpub\www-dev\somedomain.local"
$bkupFilesSrcDir = "C:\inetpub\www-dev\$restoreDomain"

# Directory the backup will be placed.
# e.g. "C:\tmp"
#   or "C:\tmp\$dateTime"
#   or "C:\tmp\$dateTime $restoreDomain"
$bkupDbTargetDir = "C:\tmp\$dateTime $restoreDomain"

# Destination path and file for the zipped website files.
# e.g. "$bkupDbTargetDir\$restoreDomain.zip" 
#  or  "C:\tmp\some-domain.local.zip".
$bkupFilesTargetFileZip = "$bkupDbTargetDir\$restoreDomain.zip"    

# Database we are backing up.
# e.g. "$restoreDomain"
#  or  "some-domain.local"
$bkupDbSrcDb = "$restoreDomain" 

# Destination file for the database. No path.
# e.g. "$bkupDbSrcDb.bak"
#  or  "some-domain.local.bak"
$bkupDbTargetFile = "$bkupDbSrcDb.bak"



###############################################################################
# Restore settings ############################################################
###############################################################################
# Base directory containing the zipped files and database we will restore.
# e.g. "C:\tmp\"
$restoreDbTargetDir = "C:\tmp\"

# Zip file and path containing the website files we want to restore
# e.g. "$restoreDbTargetDir\$bkupDomain.zip"
#  or  "C:\tmp\some-domain.local.zip"
$restoreFilesSrcFileZip = "$restoreDbTargetDir\$bkupDomain.zip"    

# Destination for the restored website files.
# e.g. "C:\inetpub\www-dev\$restoreDomain"
#  or  "C:\inetpub\www-dev\some-domain.co.uk"
$restoreFilesTargetDir = "C:\inetpub\www-dev\$restoreDomain"

# Zip file and path containing the database we want to restore.
# e.g. "$restoreDbTargetDir\$bkupDomain.bak.zip"
#  or  "C:\tmp\company-dev.some-domain.com.bak.zip"
$restoreDbSrcDbZip = "C:\tmp\$bkupDomain.bak.zip"

# File name of database backup we are restoring from
# e.g. $domainStart.$domainEndLocal.bak
#  or  company-dev.some-domain.com.bak
$restoreDbOldName = "$bkupDomain.bak"


# Destination database
# e.g. "$domainStart.$domainEndRestored"
#  or  "some-domain.co.uk"
$restoreDbNewName = "$restoreDomain"
#
#
#
' | Out-File -Encoding utf8 config-DOMAIN-SITE-BKUP.ps1

}


###
function BackupWebsite()
{
    BackupWebsiteDatabase
    BackupWebsiteFiles
}

function BackupWebsiteDatabase()
{
    # Database must be backed up before files... script error otherwise. Not sure why.
    Write-Host "Backing up database: $bkupDbSrcDb"
    Write-Host "Dir destination: $bkupDbTargetDir"
    CreateDirIfNeeded -dir $bkupDbTargetDir
    Write-Host "File (.bak) destination: $bkupDbTargetFile"
    CreateBackupDb -database $bkupDbSrcDb -targetDir $bkupDbTargetDir -targetFile $bkupDbTargetFile
    # I'm unable to add the .bak file to the root of the zip archive, so we put it in its own archive.
    Write-Zip -Path "$bkupDbTargetDir\$bkupDbTargetFile" -OutputPath "$bkupDbTargetDir\$bkupDbTargetFile.zip"
    Remove-Item "$bkupDbTargetDir\$bkupDbTargetFile"
}

function BackupWebsiteFiles()
{
    CreateDirIfNeeded -dir $bkupDbTargetDir
    CreateBackupFiles -srcDir $bkupFilesSrcDir -destZip $bkupFilesTargetFileZip
}


###
function RestoreWebsite()
{
    RestoreWebsiteDatabase
    RestoreWebsiteFiles
}

function RestoreWebsiteFiles()
{
    RestoreFiles
    Copy-Item "$restoreFilesTargetDir\website\Web.ConnectionStrings.bwtAmazon.config" -Destination "$restoreFilesTargetDir\website\Web.ConnectionStrings.config"
}

function RestoreWebsiteDatabase()
{
    Write-Host "Unzipping database backup..."
    Write-Host "--> src:  $restoreDbSrcDbZip"
    Write-Host "--> dest: $restoreDbTargetDir"
    UnZipMe -zipfilename $restoreDbSrcDbZip -destination $restoreDbTargetDir
    RestoreDb -dbSrcFileDir $restoreDbTargetDir -dbSrcFileBak $restoreDbOldName -dbNewName $restoreDbNewName
}

cls
# Reduce script priority. Script is often run on live servers and we don't want
# to degrade site performace whilst script is running.
# Available priority values: Lowest, BelowNormal, Normal, AboveNormal, Highest
[System.Threading.Thread]::CurrentThread.Priority = 'Lowest'


#Import required modules
$env:PSModulePath = $env:PSModulePath + ";" + "$HOME\Documents\bin\Modules"
Import-Module Pscx 
Import-Module BwtDbMng



Write-Host "domainStart: $domainStart"


#CreateLocalBackup
#RestoreLocalBackupToRemote

if (!$command.ToLower().CompareTo("help")) {
    Help
}
elseif (!$command.ToLower().CompareTo("generatesampleconfig"))
{
    GenerateSampleConfig
}
else
{
    . .\$configFile
    Write-Host "domainStart: $domainStart"

    Write-Host "Executing the command: $cmd"
    switch ($command)
    {
        "BackupWebsite" 
        { 
            BackupWebsite 
        }
        "BackupDatabase" 
        { 
            BackupWebsiteDatabase 
        }
        "BackupFiles" 
        { 
            BackupWebsiteFiles 
        }
        "RestoreWebsite" 
        { 
            RestoreWebsite 
        }
        "RestoreFiles" 
        { 
            RestoreWebsiteFiles 
        }
        "RestoreDatabase" 
        { 
            RestoreWebsiteDatabase 
        }                      
        default 
        { 
            Write-Host "Invalid command"
            Write-Host "Use -cmd help to get help."
            Write-Host "Exiting"
            Write-Host
            exit 0
        }
    }
}


Import-Module Pscx
Remove-Module BwtDbMng





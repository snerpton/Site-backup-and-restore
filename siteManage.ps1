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



##### Actual functions we use in main #####
function CreateBackupFiles($srcDir, $destZip)
{
    Write-Host "Backing up files..."
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
# Bare domain, used on both local and remote environments. 
# e.g. "some-domain"
$domainStart = "some-domain"

# The part of the domain higher than the bare domain, typically "com", "co.uk". 
# Note the absence of the leading ".".
$domainEndRmt = "co.uk"

# The part of the domain higher than the bare domain on the local machine, 
# typically "local". Note the absence of the leading ".".
$domainEndLocal = "local"


###############################################################################
# Backup settings #############################################################
###############################################################################
# The directory we are backing up. 
# e.g "C:\inetpub\wwwSites\$domainStart.$domainEndLocal"
#  or "C:\inetpub\wwwSites\somedomain.local"
$bkupFilesSrcDir = "C:\inetpub\wwwSites\$domainStart.$domainEndLocal"

# Directory the backup will be placed.
# e.g. "C:\tmp"
$bkupDbTargetDir = "C:\tmp"

# Destination path and file for the zipped website files.
# e.g. "$bkupDbTargetDir\$domainStart.$domainEndLocal.zip" 
#  or  "C:\tmp\some-domain.local.zip".
$bkupFilesTargetFileZip = "$bkupDbTargetDir\$domainStart.$domainEndLocal.zip"    

# Database we are backing up.
# e.g. "$domainStart.$domainEndLocal"
#  or  "some-domain.local"
$bkupDbSrcDb = "$domainStart.$domainEndLocal" 


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
# e.g. "$restoreDbTargetDir\$domainStart.$domainEndLocal.zip"
#  or  "C:\tmp\some-domain.local"
$restoreFilesSrcFileZip = "$restoreDbTargetDir\$domainStart.$domainEndLocal.zip"    

# Destination for the restored website files.
# e.g. "C:\inetpub\$domainStart.$domainEndRmt"
#  or  "C:\inetpub\some-domain.co.uk"
$restoreFilesTargetDir = "C:\inetpub\$domainStart.$domainEndRmt"

# Zip file and path containing the database we want to restore.
# e.g. "$restoreDbTargetDir\$domainStart.$domainEndLocal.bak.zip"
#  or  "C:\tmp\$domainStart.$domainEndLocal.bak.zip"
$restoreDbSrcDbZip = "C:\tmp\$domainStart.$domainEndLocal.bak.zip"

# Destination database
# e.g. "$domainStart.$domainEndRmt"
#  or  "some-domain.co.uk"
$restoreDbNewName = "$domainStart.$domainEndRmt"
#
#
#
' | Out-File config-MACHINE-DOMAIN-SAMPLE.ps1

}


###
function BackupWebsite()
{
    BackupDatabase
    BackupFiles
}

function BackupDatabase()
{
    # Database must be backed up before files... script error otherwise. Not sure why.
    Write-Host "Backing up database: $bkupDbSrcDb"
    Write-Host "Dir destination: $bkupDbTargetDir"
    Write-Host "File (.bak) destination: $bkupDbTargetFile"
    CreateBackupDb -database $bkupDbSrcDb -targetDir $bkupDbTargetDir -targetFile $bkupDbTargetFile
    # I'm unable to add the .bak file to the root of the zip archive, so we put it in its own archive.
    Write-Zip -Path "$bkupDbTargetDir\$bkupDbTargetFile" -OutputPath "$bkupDbTargetDir\$bkupDbTargetFile.zip"
    Remove-Item "$bkupDbTargetDir\$bkupDbTargetFile"
}

function BackupFiles()
{
    CreateBackupFiles -srcDir $bkupFilesSrcDir -destZip $bkupFilesTargetFileZip
}


###
function RestoreWebsite()
{
    RestoreFiles
    RestoreDatabase
}

function RestoreFiles()
{
    RestoreFiles
    Copy-Item "$restoreFilesTargetDir\website\Web.ConnectionStrings.bwtAmazon.config" -Destination "$restoreFilesTargetDir\website\Web.ConnectionStrings.config"
}

function RestoreDatabase()
{
    Write-Host "Unzipping database backup..."
    Write-Host "--> src:  $restoreDbSrcDbZip"
    Write-Host "--> dest: $restoreDbTargetDir"
    UnZipMe -zipfilename $restoreDbSrcDbZip -destination $restoreDbTargetDir
    RestoreDb -dbSrcFileDir $restoreDbTargetDir -dbSrcFileBak $bkupDbTargetFile -dbNewName $restoreDbNewName
}

cls
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
            BackupDatabase 
        }
        "BackupFiles" 
        { 
            BackupFiles 
        }
        "RestoreWebsite" 
        { 
            RestoreWebsite 
        }
        "RestoreFiles" 
        { 
            RestoreFiles 
        }
        "RestoreDatabase" 
        { 
            RestoreDatabase 
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





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


# -----------------------------------------------------------------------------
# START: configuration
# -----------------------------------------------------------------------------
#$domainStart = "brit-thoracic"
#$domainEndRmt = ".blueprintwebtech.com"
#$domainEndLocal = ".local"
#$repoName = "safetysystemsuk-dev"

#$pathToZip = "C:\tmp\" + $domainStart + $domainEndLocal + ".zip"
#$targetDir = "C:\inetpub\" + $domainStart + $domainEndRmt

#$webRootArchive = $pathToZip
#$webRootDestDir = "$targetDir" # This is really the project root, as this dir contains the repo including the web root

#$hgRepoUser = "chrisashton"
#$hgRepoPass = "Chr1sA5hton"
#$hgRepoSrc = "https://$hgRepoUser" + ":$hgRepoPass@bitbucket.org/collaborate_dev/" + $repoName
#$hgRepoDest = $targetDir

#$webConfigFile = "$targetDir\website\web.config"

#$dbBkupFilePrefix = "$targetDir\" + $domainStart + $domainEndLocal  + "_20130717183041" + $domainEnd
#$dbRestoreDir = "C:\tmp\"

#$ErrorActionPreference = "Stop" # Stop script on first error

#####
$domainStart = "brit-thoracic"
$domainEndRmt = "blueprintwebtech.com"
$domainEndLocal = "local"

$bkupFilesSrcDir = "C:\inetpub\wwwSites\$domainStart.$domainEndLocal"  # Directory we are backing up. e.g. C:\inetpub\wwwSites\somedomain.local
$bkupFilesTargetFileZip = "C:\tmp\$domainStart.$domainEndLocal.zip"    # Directory the backup will be placed e.g. C:\tmp 
$bkupDbSrcDb = "$domainStart.$domainEndLocal"                          # Database we are backing up
$bkupDbTargetDir = "C:\tmp"
$bkupDbTargetFile = $bkupDbSrcDb

$restoreFilesSrcFileZip = "C:\tmp\$domainStart.$domainEndLocal.zip"    # Zip file containing the website files we are going to restore.
$restoreFilesTargetDir = "C:\inetpub\$domainStart.$domainEndRmt"
$restoreDbSrcDbZip = "C:\tmp\$domainStart.$domainEndLocal.bak.zip"
$restoreDbSrcDb = "C:\tmp\"
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

function RestoreDb($dbSrc)
{
    Write-Host "db src: $dbSrc"

}


##### Main program #####

function CreateLocalBackup()
{
    # Database must be backed up before files... script error otherwise. Not sure why.
    CreateBackupDb -database $bkupDbSrcDb -targetDir $bkupDbTargetDir -targetFile $bkupDbTargetFile
    # I'm unable to add the .bak file to the root of the zip archive, so we put it in its own archive.
    Write-Zip -Path "$bkupDbTargetDir\$bkupDbTargetFile.bak" -OutputPath "$bkupDbTargetDir\brit-thoracic.local.bak.zip"
    Remove-Item "$bkupDbTargetDir\$bkupDbTargetFile.bak"
    #CreateBackupFiles -srcDir $bkupFilesSrcDir -destZip $bkupFilesTargetFileZip
    
}

function RestoreLocalBackupToRemote()
{
    #RestoreFiles
    Write-Host "Unzipping database backup..."
    Write-Host "--> src:  $restoreDbSrcDbZip"
    Write-Host "--> dest: $restoreDbSrcDb"
    UnZipMe -zipfilename $restoreDbSrcDbZip -destination $restoreDbSrcDb
    RestoreDb -dbSrc $bkupDbSrcDb
   
}

cls
$env:PSModulePath = $env:PSModulePath + ";" + "$HOME\Documents\bin\Modules"
Import-Module BwtDbMng

CreateLocalBackup
#RestoreLocalBackupToRemote


Remove-Module BwtDbMng




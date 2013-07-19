# Chris Ashton

function DbBackup($database, $targetDir, $targetFile)
{
    #============================================================
    # Backup a Database using PowerShell and SQL Server SMO
    # Script below creates a full backup
    # http://www.sswug.org/articlesection/default.aspx?TargetID=44909
    #============================================================

    #specify database to backup
    #ideally this will be an argument you pass in when you run
    #this script, but let's simplify for now
    #$dbToBackup = "brit-thoracic.local"
    $dbToBackup = $database
     
    #clear screen
    #cls
     
    #load assemblies
    #note need to load SqlServer.SmoExtended to use SMO backup in SQL Server 2008
    #otherwise may get this error
    #Cannot find type [Microsoft.SqlServer.Management.Smo.Backup]: make sure
    #the assembly containing this type is loaded.

    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

    #create a new server object
    $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") "(local)"
    #$backupDirectory = $server.Settings.BackupDirectory
    $backupDirectory = "$targetDir" 
     
    #display default backup directory
    "Default Backup Directory: " + $backupDirectory
     
    $db = $server.Databases[$dbToBackup]
    $dbName = $db.Name
     
    $timestamp = Get-Date -format yyMMddHHmmss
    $smoBackup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
     
    #BackupActionType specifies the type of backup.
    #Options are Database, Files, Log
    #This belongs in Microsoft.SqlServer.SmoExtended assembly
     
    $smoBackup.Action = "Database"
    $smoBackup.BackupSetDescription = "Full Backup of " + $dbName
    $smoBackup.BackupSetName = $dbName + " Backup"
    $smoBackup.Database = $dbName
    $smoBackup.MediaDescription = "Disk"
    #$smoBackup.Devices.AddDevice($backupDirectory + "\" + $dbName + "_" + $timestamp + ".bak", "File")
    $smoBackup.Devices.AddDevice($backupDirectory + "\" + $targetFile + ".bak", "File")
    $smoBackup.SqlBackup($server)

    #let's confirm, let's list list all backup files
    $directory = Get-ChildItem $backupDirectory
    #list only files that end in .bak, assuming this is your convention for all backup files
    $backupFilesList = $directory | where {$_.extension -eq ".bak"}
    $backupFilesList | Format-Table Name, LastWriteTime

    #See more at: http://www.sswug.org/articlesection/default.aspx?TargetID=44909#sthash.YMwxs7lz.dpuf
}

function
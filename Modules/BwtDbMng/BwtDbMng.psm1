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

function DbRestore()
{
    #============================================================
    # Restore a Database using PowerShell and SQL Server SMO
    # Restore to the same database, overwrite existing db
    # http://www.sswug.org/articlesection/default.aspx?TargetID=44909
    #============================================================
     
    #clear screen
    cls
     
    #load assemblies
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

    #Need SmoExtended for backup
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
    [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
    [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null
     
    #get backup file
    #you can also use PowerShell to query the last backup file based on the timestamp
    #I'll save that enhancement for later
    $backupFile = "C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\brit-thoracic.local.bak"
                  
    #we will query the db name from the backup file later
     
    $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") "(local)"
    $backupDevice = New-Object ("Microsoft.SqlServer.Management.Smo.BackupDeviceItem") ($backupFile, "File")
    $smoRestore = new-object("Microsoft.SqlServer.Management.Smo.Restore")
     
    #settings for restore
    $smoRestore.NoRecovery = $false;
    $smoRestore.ReplaceDatabase = $true;
    $smoRestore.Action = "Database"
     
    #show every 10% progress
    $smoRestore.PercentCompleteNotification = 10;
     
    $smoRestore.Devices.Add($backupDevice)
     
    #read db name from the backup file's backup header
    $smoRestoreDetails = $smoRestore.ReadBackupHeader($server)
     
    #display database name
    "Database Name from Backup Header : " + $smoRestoreDetails.Rows[0]["DatabaseName"]
     
    $smoRestore.Database = $smoRestoreDetails.Rows[0]["DatabaseName"]
     
    #restore
    $smoRestore.SqlRestore($server)
     
    "Done"
    #See more at: http://www.sswug.org/articlesection/default.aspx?TargetID=44909#sthash.YMwxs7lz.dpuf
}

function DbRestoreNewName($scrFile)
{
    #============================================================
    # Restore a Database using PowerShell and SQL Server SMO
    # Restore to the a new database name, specifying new mdf and ldf
    # http://www.sswug.org/articlesection/default.aspx?TargetID=44909
    #============================================================
     
    #clear screen
    cls
     
    #load assemblies
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

    #Need SmoExtended for backup
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
    [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
    [Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null
     
    #$backupFile = 'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Backup\brit-thoracic.local.bak'
    $backupFile = $scrFile 
     
    #we will query the database name from the backup header later
    $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") "(local)"
    $backupDevice = New-Object("Microsoft.SqlServer.Management.Smo.BackupDeviceItem") ($backupFile, "File")
    $smoRestore = new-object("Microsoft.SqlServer.Management.Smo.Restore")
     
    #restore settings
    $smoRestore.NoRecovery = $false;
    $smoRestore.ReplaceDatabase = $true;
    $smoRestore.Action = "Database"
    $smoRestorePercentCompleteNotification = 10;
    $smoRestore.Devices.Add($backupDevice)
     
    #get database name from backup file
    $smoRestoreDetails = $smoRestore.ReadBackupHeader($server)
     
    #display database name
    "Database Name from Backup Header : " +$smoRestoreDetails.Rows[0]["DatabaseName"]
     
    #give a new database name
    $smoRestore.Database =$smoRestoreDetails.Rows[0]["DatabaseName"] + "_Copy"
    $smoRestore.Database = "new-database-name" 
     
    #specify new data and log files (mdf and ldf)
    $smoRestoreFile = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile")
    $smoRestoreLog = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile")
     
    #the logical file names should be the logical filename stored in the backup media
    $smoRestoreFile.LogicalFileName = $smoRestoreDetails.Rows[0]["DatabaseName"]
    $smoRestoreFile.PhysicalFileName = $server.Information.MasterDBPath + "\" + $smoRestore.Database + "_Data.mdf"
    $smoRestoreLog.LogicalFileName = $smoRestoreDetails.Rows[0]["DatabaseName"] + "_Log"
    $smoRestoreLog.PhysicalFileName = $server.Information.MasterDBLogPath + "\" + $smoRestore.Database + "_Log.ldf"
    $smoRestore.RelocateFiles.Add($smoRestoreFile)
    $smoRestore.RelocateFiles.Add($smoRestoreLog)
     
    #restore database
    $smoRestore.SqlRestore($server)
    # See more at: http://www.sswug.org/articlesection/default.aspx?TargetID=44909#sthash.YMwxs7lz.dpuf
}
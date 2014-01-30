
###############################################################################
### Some general settings #####################################################
###############################################################################
# Bare domain, used on both local and remote environments. 
# e.g. "some-domain"
$domainStart = "brit-thoracic"

# The part of the domain higher than the bare domain, typically "com", "co.uk". 
# Note the absence of the leading ".".
$domainEndRestored = "blueprintwebtech.com"

# The part of the domain higher than the bare domain on the local machine, 
# typically "local". Note the absence of the leading ".".
$domainEndBackedup = "local"


###############################################################################
# Backup settings #############################################################
###############################################################################
# The directory we are backing up. 
# e.g "C:\inetpub\wwwSites\$domainStart.$domainEndLocal"
#  or "C:\inetpub\wwwSites\somedomain.local"
$bkupFilesSrcDir = "C:\inetpub\$domainStart.$domainEndRestored"

# Directory the backup will be placed.
# e.g. "C:\tmp"
$bkupDbTargetDir = "C:\tmp"

# Destination path and file for the zipped website files.
# e.g. "$bkupDbTargetDir\$domainStart.$domainEndLocal.zip" 
#  or  "C:\tmp\some-domain.local.zip".
$bkupFilesTargetFileZip = "$bkupDbTargetDir\$domainStart.$domainEndRestored.zip"    

# Database we are backing up.
# e.g. "$domainStart.$domainEndBackedup"
#  or  "some-domain.local"
$bkupDbSrcDb = "$domainStart.$domainEndRestored" 

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
# e.g. "$restoreDbTargetDir\$domainStart.$domainEndBackedup.zip"
#  or  "C:\tmp\some-domain.local"
$restoreFilesSrcFileZip = "$restoreDbTargetDir\$domainStart.$domainEndBackedup.zip"    

# Destination for the restored website files.
# e.g. "C:\inetpub\$domainStart.$domainEndRestored"
#  or  "C:\inetpub\some-domain.co.uk"
$restoreFilesTargetDir = "C:\inetpub\$domainStart.$domainEndRestored"

# Zip file and path containing the database we want to restore.
# e.g. "$restoreDbTargetDir\$domainStart.$domainEndBackedup.bak.zip"
#  or  "C:\tmp\$domainStart.$domainEndLocal.bak.zip"
$restoreDbSrcDbZip = "C:\tmp\$domainStart.$domainEndBackedup.bak.zip"

# File name of database backup we are restoring from
# e.g. $domainStart.$domainEndLocal.bak
#  or  some-domain.co.uk.bak
$restoreDbOldName = "$domainStart.$domainEndBackedup.bak"


# Destination database
# e.g. "$domainStart.$domainEndRestored"
#  or  "some-domain.co.uk"
$restoreDbNewName = "$domainStart.$domainEndRestored"
#
#
#
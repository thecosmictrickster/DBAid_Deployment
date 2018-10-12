#######################################################################
# This script backs up existing DBAid files & database
#######################################################################

### set variables
$hostname = $env:computername

# determine installed instances of SQL Server
[string[]]$SQLinstances = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" -Name "InstalledInstances").InstalledInstances

# for systems that don't have DBAid on C: drive, we'll be moving it to keep things standardised
$collector_curr_dest = "C:\DBAid"
$configg_curr_dest = 'C:\Datacom'
$checkmk_curr_dest = "${env:ProgramFiles(x86)}\check_mk\local"

# set source & backup folders for DBAid files
$TempFolder = "C:\temp"
$DBAid_backup = "$TempFolder\DBAidbackup"
$DBAid_checkmk_backup = "$DBAid_backup\checkmk"


#####################################
#                                   #
#  Check provided paths             #
#                                   #
#####################################
Write-Host "Checking provided paths..." -ForegroundColor Yellow

if (!(Test-Path -Path $checkmk_curr_dest)) {
  Write-Host "Error! Folder $checkmk_curr_dest does not exist (dbaid.checkmk folder)" -ForegroundColor Red
  Exit
} 

if (!(Test-Path -Path $DBAid_checkmk_backup)) {
  Write-Host "Error! Folder $DBAid_checkmk_backup does not exist (dbaid.checkmk backup folder)" -ForegroundColor Red
  Exit
}   

if (!(Test-Path -Path $DBAid_checkmk_backup\$checkmk_config)) {
  Write-Host "Error! Folder $DBAid_checkmk_backup\$checkmk_config does not exist (dbaid.checkmk backup folder)" -ForegroundColor Red
  Exit
} 

if (!(Test-Path -Path $checkmk_curr_dest\$checkmk_config)) {
  Write-Host "Error! Folder $checkmk_curr_dest\$checkmk_config does not exist (dbaid.checkmk folder)" -ForegroundColor Red
  Exit
} 


#####################################
#                                   #
#  Backup existing files            #
#                                   #
#####################################
Write-Host "Backing up existing files..." -ForegroundColor Yellow

try {
  Copy-Item $checkmk_curr_dest "$DBAid_backup\checkmk" -Recurse -Force
  Copy-Item $collector_curr_dest "$DBAid_backup\collector" -Recurse -Force
  Copy-Item $configg_curr_dest "$DBAid_backup\configg" -Recurse -Force
}
catch {
  Write-Host "Some sort of terminating error doing file backups" -ForegroundColor Red
  $error
  Exit
}


#####################################
#                                   #
#  Backup databases                 #
#                                   #
#####################################
Write-Host "Backup up existing DBAid database..." -ForegroundColor Yellow

try {
  foreach ($instance in $SQLinstances)
  {
    if ($instance -eq 'MSSQLSERVER')
    {
      $SQLserver = $hostname
    }
    else
    {
      $SQLserver = $hostname + "\" + $instance
    }
    # backup existing _dbaid database to default backup folder for the instance
    sqlcmd -S $SQLServer -E -Q "BACKUP DATABASE [_dbaid] TO DISK = '_dbaid_dbbackup_before_upgrade.bak' WITH INIT;"
  }
}
catch {
  Write-Host "Some sort of terminating error doing database backup" -ForegroundColor Red
  $error
  Exit
}
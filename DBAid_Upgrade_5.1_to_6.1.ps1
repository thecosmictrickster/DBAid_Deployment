#######################################################################
# Copy DBAid files to C:\Temp\DBAid_6.1.0_DIA
# This script moves collector & configg to C: drive and upgrades all.
#######################################################################

### set variables
$move_configg = 0      # Are we moving existing config genie files? 1 = Yes, 0 = No
$move_collector = 0    # Are we moving existing collector files? 1 = Yes, 0 = No

$upgrade_configg = 1   # Are we upgrading config genie? Only required for first run. 1 = Yes, 0 = No
$upgrade_collector = 1 # Are we upgrading collector? Only required for first run. 1 = Yes, 0 = No
$upgrade_checkmk = 1   # Are we upgrading check_mk plugin? Only required for first run. 1 = Yes, 0 = No

$hostname = $env:computername # If this is a clustered SQL instance, change this to $hostname = "<VNN of SQL instance>"
$SQLInstance = "MSSQLSERVER"  # SQL instance to deploy to. MSSQLSERVER = default instance.

# determine installed instances of SQL Server - maybe later, if option to upgrade all is desired
#[string[]]$SQLinstances = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" -Name "InstalledInstances").InstalledInstances

# for systems that don't have DBAid on C: drive, we'll be moving it to keep things standardised
# see also options above for disabling move of collector & config genie
$collector_curr_dest = "D:\DBAid"
$configg_curr_dest = 'D:\Datacom'

# set standard destination folders
$dest_root = "C:"
$collector_dest = "$dest_root\DBAid"
$configg_dest = "$dest_root\Datacom"
$checkmk_dest = "${env:ProgramFiles(x86)}\check_mk\local"

# set source & backup folders for DBAid files
$SourceRootFolder = "C:\temp"                                              # Folder in which source DBAid folder structure is in
$DBAidnew_source = "$SourceRootFolder\DBAid-build_6.1.0\"                  # Source files for new version of DBAid
$DBAidnew_collector_src = "$DBAidnew_source\DBAid"                         # Subfolder for dbaid.collector files.
$DBAidnew_checkmk_source = "$DBAidnew_source\check_mk\dbaid.checkmk.exe"
$DBAidold_backup = "$SourceRootFolder\DBAidoldbackup"                      # Folder existing DBAid collector, config genie, and check_mk will be backed up to
$DBAidold_checkmk_backup = "$DBAidold_backup\checkmk"
$DBAidold_collector_backup = "$DBAidold_backup\collector"

$collector_exe = "dbaid.collector.exe"           # Collector executable.
$collector_config = "dbaid.collector.exe.config" # Config file for dbaid.collector.
$checkmk_exe = "dbaid.checkmk.exe"               # Check_MK plugin executable.
$checkmk_config = "dbaid.checkmk.exe.config"     # Config file for CheckMK plugin.
$configg_exe = "dbaid.configg.exe"               # Config Genie executable.


#####################################
#                                   #
#  Check provided paths             #
#                                   #
#####################################
Write-Host "Checking provided paths..." -ForegroundColor Yellow

if (!(Test-Path -Path $collector_curr_dest)) {
  Write-Host "Error! Folder $collector_curr_dest does not exist (current DBAid collector folder)" -ForegroundColor Red
  Exit
} 

if (!(Test-Path -Path $configg_curr_dest)) {
  Write-Host "Error! Folder $configg_curr_dest does not exist (current DBAid config genie folder)" -ForegroundColor Red
  Exit
} 

if (!(Test-Path -Path $checkmk_dest)) {
  Write-Host "Error! Folder $checkmk_dest does not exist (current dbaid.checkmk folder)" -ForegroundColor Red
  Exit
} 

if (!(Test-Path -Path $checkmk_dest\$checkmk_config)) {
  Write-Host "Error! File $checkmk_dest\$checkmk_config does not exist (current dbaid.checkmk configuration)" -ForegroundColor Red
  Exit
} 



#####################################
#                                   #
#  Backup existing files            #
#                                   #
#####################################
Write-Host "Backing up existing files..." -ForegroundColor Yellow

try {
  Copy-Item $checkmk_dest "$DBAidold_backup\checkmk" -Recurse -Force
  Copy-Item $collector_curr_dest "$DBAidold_backup\collector" -Recurse -Force
  Copy-Item $configg_curr_dest "$DBAidold_backup\configg" -Recurse -Force
}
catch {
  Write-Host "Some sort of terminating error doing file backups" -ForegroundColor Red
  Exit
}


#####################################
#                                   #
#  Backup databases                 #
#                                   #
#####################################
Write-Host "Backup up existing DBAid database..." -ForegroundColor Yellow

try {
  if ($SQLInstance -eq 'MSSQLSERVER')
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
catch {
  Write-Host "Some sort of terminating error doing database backup" -ForegroundColor Red
  Exit
}




#####################################
#                                   #
#  Upgrade Collector                #
#                                   #
#####################################
Write-Host "Upgrading collector..." -ForegroundColor Yellow

try {
  # check if collector needs to be moved to another drive
  if ($move_collector -eq 1) {
    Remove-Item $collector_curr_dest -Recurse -Force  # we've got a backup to copy configuration from, so just delete this. New version will be copied to new location
  }

  # check version of executable that's there
  # if this is installation of a second instance, we just need to add connection info, not copy stuff
  $current_ver = (Get-ChildItem $collector_curr_dest\$collector_exe).VersionInfo.ProductVersion
  $new_ver = (Get-ChildItem $DBAidnew_source\DBAid\$collector_exe).VersionInfo.ProductVersion

  if ($current_ver -ne $new_ver) {
    Write-Host "Versions are different. Upgrade required..." -ForegroundColor Yellow

    Copy-Item $DBAidnew_collector_src $collector_dest -Recurse -Force
    $Acl = Get-Acl $collector_dest
    $Acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($collector_svc,"Modify","ContainerInherit, ObjectInherit","None","Allow")))
    (Get-Item $collector_dest).SetAccessControl($Acl)

    # copy configuration
    [xml]$oldfile = Get-Content "$DBAidold_collector_backup\$collector_config" -Raw
    [xml]$newfile = Get-Content "$collector_dest\$collector_config" -Raw
    
    # remove default connection strings from new config file
    $node = $newfile.SelectSingleNode("/configuration/connectionStrings/add")

    while ($node -ne $null) {
      $node.ParentNode.RemoveChild($node) | Out-Null
      $node = $newfile.SelectSingleNode("/configuration/connectionStrings/add")
    }



  }
  else {
    Write-Host "Version match. Upgrade already done. Adding connection string..." -ForegroundColor Yellow
    
    # add connection string
    if ($SQLInstance -eq "MSSQLSERVER") {
      $servername = $hostname
      $connectionstring = "Server=$hostname;Database=$dbaid_db_name;Trusted_Connection=True;Application Name=DBAid Collector;"
    }
    else {
      $servername = "$hostname@$SQLInstance"
      $connectionstring = "Server=$hostname\$SQLInstance;Database=$dbaid_db_name;Trusted_Connection=True;Application Name=DBAid Collector;"
    }
    
    if (Test-Path -Path $collector_dest\$collector_config) {
      # read existing config file
      [xml]$config = Get-Content "$collector_dest\$collector_config" -Raw
      
      # add new connection string
      if ($config.configuration.connectionStrings.add.name -ine $servername) {
        $newconnection = $config.CreateElement("add")
        $newconnection.SetAttribute("name", $servername)
        $newconnection.SetAttribute("connectionString", $connectionstring)
        $config.configuration.connectionStrings.AppendChild($newconnection) | Out-Null
        # save changes to new config file
        $config.Save("$collector_dest\$collector_config")
      } 
    }

  }
  
  
  
  
  
  

}
catch {
  Write-Host "Some sort of terminating error upgrading collector" -ForegroundColor Red
  $error
  Exit
}


#####################################
#                                   #
#  Transfer configuration data      #
#                                   #
#####################################
Write-Host "Transferring configuration data to new files..." -ForegroundColor Yellow

try {
  [xml]$oldfile = Get-Content "$DBAid50_checkmk_backup\$checkmk_config" -Raw
  [xml]$newfile = Get-Content "$checkmk_dest\$checkmk_config" -Raw

  $node = $newfile.SelectSingleNode("/configuration/connectionStrings/add")

  while ($node -ne $null) {
    $node.ParentNode.RemoveChild($node)
    $node = $newfile.SelectSingleNode("/configuration/connectionStrings/add")
  }

  # copy connection strings across
  foreach ($connection in $oldfile.configuration.connectionStrings.add) {
    $instancename = $connection.GetAttribute("name")
    $connectionString = $connection.GetAttribute("connectionString")
    
    if ($connectionString -inotcontains "Application Name") {
      $connectionString = -join $connectionString, "Application Name=Check_MK;"
    }
    
    if ($newfile.configuration.connectionStrings.add.name -inotcontains $instancename) {
      $NewConnection = $newfile.CreateElement("add")
      $NewConnection.SetAttribute("name", $instancename)
      $NewConnection.SetAttribute("connectionString", $connectionString)
      $newfile.configuration.connectionStrings.AppendChild($NewConnection) | Out-Null
    }
  }
  
  # copy other settings
  foreach ($oldsetting in $oldfile.configuration.appSettings.add) {
    $oldkey = $oldsetting.GetAttribute("key")
    $oldvalue = $oldsetting.GetAttribute("value")
    if ($newfile.configuration.appSettings.add.key -icontains $oldkey) {
      $newsetting = $newfile.SelectSingleNode("/configuration/appSettings/add[@key='$oldkey']")
      $newsetting.SetAttribute("value", $oldvalue)
    }
  }

  $newfile.Save("$checkmk_dest\$checkmk_config")
}
catch {
  Write-Host "Some sort of error occurred" -ForegroundColor Red
}
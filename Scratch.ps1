$hostname = $env:computername # If this is a clustered SQL instance, change this to $hostname = "<VNN of SQL instance>"
$SQLInstance = "MSSQLSERVER"  # SQL instance to deploy to. MSSQLSERVER = default instance.
$collector_curr_dest = "D:\DBAid"

# set standard destination folders
$dest_root = "C:"
$collector_dest = "$dest_root\DBAid"
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



# copy configuration
[xml]$oldfile = Get-Content "$DBAidold_collector_backup\$collector_config" -Raw
[xml]$newfile = Get-Content "$collector_dest\$collector_config" -Raw

# remove default connection strings from new config file
$node = $newfile.SelectSingleNode("/configuration/connectionStrings/add")

while ($node -ne $null) {
  $node.ParentNode.RemoveChild($node) | Out-Null
  $node = $newfile.SelectSingleNode("/configuration/connectionStrings/add")
}

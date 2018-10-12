#######################################################################
# DBAid removal script
#
# Not tested with clusters. Intended for standalone instances.
#
#######################################################################

# set variables
$remove_collector = 1
$remove_configg = 1
$remove_checkmk_plugin = 1
$hostname = $env:computername                # If this is a clustered SQL instance, change this to $hostname = "<VNN of SQL instance>"
$SQLInstance = "MSSQLSERVER"                 # SQL instance to deploy to. MSSQLSERVER = default instance.
$dbaid_db_name = "_dbaid"                    # Name of database to deploy dbaid to
$dest_root = "C:"                            # Root drive dbaid executables are deployed to.
$checkmk_svc = "NT AUTHORITY\SYSTEM"         # Service account to use for CheckMK plugin (should be same as Check_MK_Agent Windows service)
$collector_svc = "NT AUTHORITY\SYSTEM"       # Service account to use for dbaid.collector. Only required if not running dbaid.collector from SQL Agent.
# set standard destination folders
$collector_dest = "$dest_root\DBAid"                       # Folder for dbaid.collector.
$configg_dest = "$dest_root\Datacom"                       # Folder for config genie.
$checkmk_dest = "${env:ProgramFiles(x86)}\check_mk\local"  # Folder for CheckMK agent.
$collector_config = "dbaid.collector.exe.config"           # Config file for dbaid.collector.
$checkmk_config = "dbaid.checkmk.exe.config"               # Config file for CheckMK plugin.
[string]$dbaid_db_name_sa = -join $dbaid_db_name,"_sa"     # Name of dbaid login
$dbaid_db_name_sa = $dbaid_db_name_sa -Replace("\s", "")   # -join puts a space in, remove it



#####################################
#                                   #
#  Remove files/folders             #
#                                   #
#####################################
Write-Host "Removing files & folders..." -ForegroundColor Yellow

if ((Test-Path -Path $checkmk_dest) -and ($remove_checkmk_plugin -eq 1)) {
  Remove-Item "$checkmk_dest\dbaid*" -Force
}

if ((Test-Path -Path $collector_dest) -and ($remove_collector -eq 1)) {
  Remove-Item "$collector_dest" -Force -Recurse
}

# if Datacom-managed server, Datacom folder may be shared with the likes of Server Team, so just remove DBAid stuff
if ((Test-Path -Path $configg_dest) -and ($remove_configg -eq 1)) {
  Remove-Item "$configg_dest\dbaid*" -Force -Recurse
}




#####################################
#                                   #
#  Remove SQL Agent jobs            #
#                                   #
#####################################
Write-Host "Removing SQL Agent jobs..." -ForegroundColor Yellow

try {
  # set common parameters
  $command = "sqlcmd"
  $arg1 = "-S"
  if ($SQLInstance -ieq "MSSQLSERVER") {
    $arg2 = "$hostname"
  }
  else {
    $arg2 = "$hostname\$SQLInstance"
  }
  $arg3 = "-E"
  $arg4 = "-Q"

  # remove system backups
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_backup_system_full') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_backup_system_full', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove user backups
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_backup_user_full') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_backup_user_full', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove log backups
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_backup_user_tran') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_backup_user_tran', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove config genie
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_config_genie') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_config_genie', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove system index optimisations
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_index_optimise_system') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_index_optimise_system', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove user index optimisations
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_index_optimise_user') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_index_optimise_user', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove system integrity checks
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_integrity_check_system') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_integrity_check_system', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove user integrity checks
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_integrity_check_user') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_integrity_check_user', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove capacity logging
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_log_capacity') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_log_capacity', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove history cleanup
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_maintenance_history') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_maintenance_history', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5

  # remove login processing
  $arg5 = "`"IF EXISTS (SELECT 1 FROM msdb..sysjobs WHERE name = '_dbaid_process_login') EXEC msdb.dbo.sp_delete_job @job_name=N'_dbaid_process_login', @delete_unused_schedule=1;`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
}
catch {
  Write-Host "Error removing SQL Agent jobs" -ForegroundColor Red
  $error
  Exit
}

# remove db users
Write-Host "Removing database users..." -ForegroundColor Yellow
try {
  $arg5 = "`"IF EXISTS (SELECT 1 FROM sys.databases WHERE name = '$dbaid_db_name') BEGIN USE [$dbaid_db_name]; IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$checkmk_svc') DROP USER [$checkmk_svc]; END`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
  $arg5 = "`"IF EXISTS (SELECT 1 FROM sys.databases WHERE name = '$dbaid_db_name') BEGIN USE [$dbaid_db_name]; IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$collector_svc') DROP USER [$collector_svc]; END`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
  $arg5 = "`"USE [master]; IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$checkmk_svc') DROP USER [$collector_svc];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
  $arg5 = "`"USE [master]; IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$collector_svc') DROP USER [$collector_svc];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
  $arg5 = "`"USE [msdb]; IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$checkmk_svc') DROP USER [$collector_svc];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
  $arg5 = "`"USE [msdb]; IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = '$collector_svc') DROP USER [$collector_svc];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
}
catch {
  Write-Host "Error removing database users" -ForegroundColor Red
  $error
  Exit
}


# remove dbaid database
Write-Host "Removing DBAid database..."

try {
  $arg5 = "`"EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'$dbaid_db_name';`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
  $arg5 = "`"IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'$dbaid_db_name') DROP DATABASE [$dbaid_db_name];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
}
catch {
  Write-Host "Error removing DBAid database" -ForegroundColor Red
  $error
  Exit
}

# remove dbaid roles from other databases
Write-Host "Removing DBAid roles..."

try {
  $arg5 = "`"USE [master]; IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$dbaid_db_name' AND type = 'R') DROP ROLE [$dbaid_db_name];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
  $arg5 = "`"USE [msdb]; IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$dbaid_db_name' AND type = 'R') DROP ROLE [$dbaid_db_name];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
}
catch {
  Write-Host "Error removing DBAid roles" -ForegroundColor Red
  $error
  Exit
}

# remove dbaid login
Write-Host "Removing DBAid logins..." -ForegroundColor Yellow

try {
  $arg5 = "`"USE [master]; IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '$checkmk_svc') AND EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'$dbaid_db_name_sa') REVOKE IMPERSONATE ON LOGIN::[$dbaid_db_name_sa] TO [$checkmk_svc] AS [$dbaid_db_name_sa];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
  $arg5 = "`"USE [master]; IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = '$collector_svc') AND EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'$dbaid_db_name_sa') REVOKE IMPERSONATE ON LOGIN::[$dbaid_db_name_sa] TO [$collector_svc] AS [$dbaid_db_name_sa];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
  $arg5 = "`"USE [master]; IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'$dbaid_db_name_sa') DROP LOGIN [$dbaid_db_name_sa];`""
  & $command $arg1 $arg2 $arg3 $arg4 $arg5
}
catch {
  Write-Host "Error removing DBAid logins" -ForegroundColor Red
  $error
  Exit
}


# Would drop checkmk and collector service accounts but may still be required/in use by other things. 
# Comment out the next line if not the case.
<#
$arg5 = "`"USE [master]; IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'$checkmk_svc') DROP LOGIN [$checkmk_svc];`""
& $command $arg1 $arg2 $arg3 $arg4 $arg5
$arg5 = "`"USE [master]; IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'$collector_svc') DROP LOGIN [$collector_svc];`""
& $command $arg1 $arg2 $arg3 $arg4 $arg5
#>

Write-Host "DBAid removal complete" -ForegroundColor Green

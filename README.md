# DBAid_Deployment
PowerShell scripts to deploy, upgrade, or remove DBAid

Not all of these are complete. Ones that are:

### deployDBAid_6.1.ps1
Script to deploy DBAid 6.1.0 to an instance. If it has already been deployed to an existing instance (e.g. you're deploying to a new, second instance), existing config files will have new connection strings added. You still need to edit this script to put in desired service accounts, public key etc.

### fn_Get-IsCluster.ps1
Function to determine if the machine it's being executed on is in a cluster or not. Returns 0|1.

### fn_Get-ClusterWindowsName.ps1
Expands on fn_Get-IsCluster.ps1 by returning the Windows cluster name or "NotClustered".

### fn_GetClusterSQLVNNs.ps1
Relies on fn_Get-ClusterWindowsName.ps1. Function to return a list of clustered SQL Server instances if the machine it is executed on is clustered and has clustered SQL Server instances. If no SQL clustered instances are detected, returns "NotSQLCluster". If machine is not clustered, returns "NotClustered".

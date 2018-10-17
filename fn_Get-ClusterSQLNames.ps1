<#  
 .Synopsis 
  Queries WMI to see if the current machine is in a cluster and returns the Windows cluster name.
 
 .Description 
  This function takes the Windows cluster name and queries WMI to retrieve SQL cluster VNN(s). 
 
 .Example 
  Get-ClusterSQLNames
#>

function Get-ClusterSQLNames {
  [string]$clusterwindowsname
  [object[]]$sqlinstances
  
  $clusterwindowsname = Get-ClusterWindowsName

  if ($clusterwindowsname -ine "NotClustered") {
    Import-Module FailoverClusters
    $sqlinstances = Get-ClusterResource -cluster $clusterwindowsname | ? { $_.ResourceType -like "SQL Server"} | Get-ClusterParameter -cluster $clusterwindowsname VirtualServerName,InstanceName | Group-Object ClusterObject | Select @{ Name = "SQLInstance";Expression = { [string]::join("\",($_.Group | Select -expandproperty Value)) } }
  }
  else {
    Write-Output "This is not a cluster"
    #$sqlinstances
  }
  return $sqlinstances.sqlinstance
}


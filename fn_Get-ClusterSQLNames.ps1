<#  
 .Synopsis 
  Queries WMI to see if the current machine is in a cluster and returns the Windows cluster name.
 
 .Description 
  This function takes the Windows cluster name and queries WMI to retrieve SQL cluster VNN(s). 
 
 .Example 
  Get-ClusterSQLVNNs
#>

function Get-ClusterSQLVNNs {
  [string]$clusterwindowsname = ""
  [string[]]$sqlinstancenames = ""
  
  $clusterwindowsname = Get-ClusterWindowsName

  if ($clusterwindowsname -ine "NotClustered") {
    Import-Module FailoverClusters
    $sqlinstancenames = Get-ClusterResource -cluster $clusterwindowsname | ? { $_.ResourceType -like "SQL Server"} | Get-ClusterParameter -cluster $clusterwindowsname VirtualServerName,InstanceName | Group-Object ClusterObject | Select @{ Name = "SQLInstance";Expression = { [string]::join("\",($_.Group | Select -expandproperty Value)) } } | Out-String
    if ($sqlinstancenames[0] -ieq "") {
      $sqlinstancenames[0] = "NotSQLCluster"
    }
  }
  else {
    $sqlinstancenames[0] = "NotClustered"
  }
  return $sqlinstancenames
}


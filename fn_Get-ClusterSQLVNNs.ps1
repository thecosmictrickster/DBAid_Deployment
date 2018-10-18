<#  
 .Synopsis 
  Queries WMI via custom function to see if the current machine is in a cluster and returns SQL Virtual Network Names (VNNs).
 
 .Description 
  This function gets the Windows cluster name via the custom function Get-ClusterWindowsName and uses PowerShell FailoverCluster functions to retrieve SQL cluster VNN(s). 
  If the server is not clustered, return result will advise so.
  If the server is clustered but no clustered instances of SQL Server are detected, (e.g. AlwaysOn AG scenario), return result will advise so.
 
 .Example 
  Get-ClusterSQLVNNs
#>

function Get-ClusterSQLVNNs {
  [string]$clusterwindowsname = ""
  [string[]]$sqlinstancenames = ""
  
  $clusterwindowsname = Get-ClusterWindowsName

  if ($clusterwindowsname -ine "NotClustered") {
    Import-Module FailoverClusters
    # need to split custom object gets split into a string array. Otherwise you get a list of instances in a single variable. Filter out headers & blank lines as well.
    $sqlinstancenames = (Get-ClusterResource -cluster $clusterwindowsname | ? { $_.ResourceType -like "SQL Server"} | Get-ClusterParameter -cluster $clusterwindowsname VirtualServerName,InstanceName | Group-Object ClusterObject | Select @{ Name = "SQLInstance";Expression = { [string]::join("\",($_.Group | Select -expandproperty Value)) } } | Out-String).Split("`n") | ? { ($_ -like "[a-zA-Z0-9]*") -and ($_ -notlike "SQLInstance*") }
    if ($sqlinstancenames.Count -lt 1) {
      $sqlinstancenames = "NotSQLCluster"
    }
  }
  else {
    $sqlinstancenames = "NotClustered"
  }
  return $sqlinstancenames
}


<#  
 .Synopsis 
  Queries WMI to see if the current machine is in a cluster and returns the Windows cluster name.
 
 .Description 
  This function takes the computername environment variable and queries WMI to see if it is part of a cluster. 
  Function can be adjusted to allow for running on local machine only or connecting to remote machine.
  If the machine is part of a cluster, the Windows cluster name is returned. If not, "NotClustered" is returned.
 
 .Parameter servername 
  Name of the server to query (future functionality)
 
 .Example 
  Get-ClusterWindowsName 
#> 
function Get-ClusterWindowsName {
  # switch comment between the next two lines depending on if you want to specify a computer name or just pick up local machine name.
  #param([string]$servername)
  [string]$servername = $env:computername
  [string]$clustername = ""

  $s = Get-WmiObject -Class Win32_SystemServices -ComputerName $servername
  if ($s | select PartComponent | where {$_ -like "*ClusSvc*"}) { 
    Import-Module FailoverClusters
    $cluster = Get-Cluster
    $clustername = $cluster.Name
  } 
  else { 
    $clustername = "NotClustered"
  } 
  return $clustername
}

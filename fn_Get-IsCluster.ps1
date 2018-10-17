<#  
 .Synopsis 
  Queries WMI to see if the current machine is in a cluster.
 
 .Description 
  This function takes the computername environment variable and queries WMI to see if it is part of a cluster. 
  Function can be adjusted to allow for running on local machine only or connecting to remote machine.
 
 .Parameter server 
  Name of the server to query (future functionality)
 
 .Example 
  Get-IsCluster 
#> 
function Get-IsCluster {
  # switch comment between the next two lines depending on if you want to specify a computer name or just pick up local machine name.
  #param([string]$server)
  [string]$server = $env:computername
  [bool]$isclustered = 2

  $s = Get-WmiObject -Class Win32_SystemServices -ComputerName $server
  if ($s | select PartComponent | where {$_ -like "*ClusSvc*"}) { 
    $isclustered = 1 
  } 
  else { 
    $isclustered = 0
  } 
  return $isclustered
}

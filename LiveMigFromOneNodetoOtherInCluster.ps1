# Loops through all of the VMs on a server and migrates them to another host

# Input: SourceServer
# Input: DestinationServer

$source = "NE-VS-CL07N01"
$destination = "NE-VS-CL07N04"
$cluster = "NE-VS-CL07"

# import the commands for clustering
import-module FailoverClusters

# Get all of the VMs currently running on this server
$vms = Get-ClusterGroup -cluster $cluster| Where-Object {$_.OwnerNode -like $source}

foreach ($vm in $vms){
    Get-Cluster $cluster | Move-ClusterVirtualMachineRole -Name $vm -node $destination
}
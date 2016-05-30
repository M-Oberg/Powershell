[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

    $computer = [Microsoft.VisualBasic.Interaction]::InputBox("Enter host node name", "Computer", "$env:COMPUTERNAME")
    $cluster = get-cluster
    $clustername = [Microsoft.VisualBasic.Interaction]::InputBox("Enter cluster name", "Cluster", "$cluster")
    $VirtualMachine = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Virtual machine name", "VM Name", "")
    Update-ClusterVirtualMachineConfiguration -name $VirtualMachine -ComputerName $computer  -Cluster $cluster 

    #get-vm $computer
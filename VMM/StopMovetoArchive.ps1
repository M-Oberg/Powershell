#Find-Module Azure*

Find-Module virtual*

Import-Module SC

Get-SCVirtualMachine

Get-Credential = $Cred
#Enter-PSSession -ComputerName xxxxx -Credential $Cred
#Import-Module xxxxxxxxx -ErrorAction Stop 

$VM = "Input box"

# Connect to the VMM server.

Get-VMMServer –ComputerName “ne-tst-scvmm01” -Credential $Cred

# Get the virtual machine.

$VM = Get-SCVirtualMachine | where { $_.Name -eq "$VM" -and $_.LibraryServer -eq "FileServer01.Contoso.com"}

# Get the host.

#$VMHost = Get-VMHost -ComputerName "VMHost01.Contoso.com"

# Specify the path on the host.

#$VMPath = $VMHost.VMPaths[0]

# Deploy the virtual machine.

Move-VM -VM $VM -VMHost $VMHost -Path $VMPath


Get-Credential = $Cred
#Enter-PSSession -ComputerName xxxxx -Credential $Cred
#Import-Module xxxxxxxxx -ErrorAction Stop 

$VM = "Input box"

# Connect to the VMM server.

Get-VMMServer –ComputerName “NE-TST-SCVMM01”

# Get the host that you want to move the virtual machine to.

$VMHost = Get-VMHost –ComputerName “VMHost01.Contoso.com”

#Get the virtual machine.

$VM = Get-VM -Name "VM01"

#Shutdown VM

#Disconnect NIC of VM


# Specify the path on the host.

$VMPath = $VMHost.VMPaths[0]

# Migrate the virtual machine.

Store-VM “VM01” –LibraryServer “LibServer01.Contoso.com” –SharePath "\\FileServer01.Contoso.com\MyLibrary1\VMs"

To store a virtual machine in the library, you use the Store-VM cmdlet instead of the Move-VM vmdlet. The following command stores the virtual machine we just moved in the above script to the library. 



<#
.SYNOPSIS
    The scripts creates and configures virtual machines in Microsoft Azure based on an input CSV file.
.EXAMPLE
   .\CreateO365AzureEnvironment.ps1 -InputFile '.\AzureMachines.csv' -Verbose
.NOTES
    File Name: CreateO365AzureEnvironment.ps1
    Author   : Johan Dahlbom, johan[at]dahlbom.eu
    Blog     : 365lab.net
    The script are provided “AS IS” with no guarantees, no warranties, and they confer no rights.
    Requires PowerShell Version 3.0!
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param (
  [Parameter(Mandatory=$false)][string]$AffinityGroup = '365lab-affinitygroup',
  [Parameter(Mandatory=$false)][string]$DomainName = '365lab.internal',
  [Parameter(Mandatory=$false)][string]$DomainShort = '365lab',
  [Parameter(Mandatory=$false)][string]$ImageFamily = 'Windows Server 2012 R2 Datacenter',
  [Parameter(Mandatory=$false)][string]$VnetName = '365lab-azure',
  [Parameter(Mandatory=$false)][string]$AdminUsername = '365_admin',
  [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]$DomainJoinCreds = (Get-Credential -Message 'Please enter credentials to join the server to the domain'),
  [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]$VMCredentials = (Get-Credential -Message 'Please enter the local admin password for the servers' -UserName $AdminUsername),
  [Parameter(Mandatory=$false)][ValidateScript({Import-Csv -Path $_})]$InputFile =  '.\AzureMachines.csv'
)
#Check that script is running in an elevated command prompt
if (-not([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("S-1-5-32-544")) {
  Write-Warning "You need to have Administrator rights to run this script!`nPlease re-run this script as an Administrator in an elevated powershell prompt!"
  break
}
#region functions
function Connect-Azure {
  begin {
      try {
          Import-Module Azure 
      } catch {
          throw "Azure module not installed"
      } 
  } process {
    if (-not(Get-AzureSubscription -ErrorAction Ignore).IsCurrent -eq $true) {
      try { 
        Add-AzureAccount -WarningAction stop -ErrorAction Stop 
      } catch {
        throw "No connection to Azure"
      }
    } 
  } end {
    $AzureSubscription = Get-AzureSubscription -Default -ErrorAction Ignore
    Set-AzureSubscription -SubscriptionId $AzureSubscription.SubscriptionId -CurrentStorageAccountName (Get-AzureStorageAccount -WarningAction Ignore).StorageAccountName
    Write-Verbose "Connected to Azure"
  }
}
function Configure-JDAzureVM {
  [CmdletBinding(SupportsShouldProcess=$true)]
  Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Role, 
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()]$VMCredentials,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$VM,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$CloudService,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$VMUri,
    [Parameter(Mandatory=$false)][ValidateNotNullOrEmpty()][string]$InternalLBIP,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Subnet
  )
  begin {
    Write-Verbose "Starting to configure $VM..."
  } 
  process {
    #Install mandatory features
    $AzureVM = Get-AzureVM -ServiceName $CloudService -Name $VM
    #Establish a PS Session to the AzureVM
    $SessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck
    $VMSessionConfig = @{
        ConnectionUri = $VMUri 
        SessionOption = $SessionOptions
        Credential = $VMCredentials
    }
    $VMSession = New-PSSession @VMSessionConfig -ErrorAction Stop
     
    Write-Verbose "Installing mandatory features on $VM"
    Invoke-Command -Session $VMSession -ScriptBlock {
      #Install the MOST IMPORTANT FEATURE of them all!
      Add-WindowsFeature -Name Telnet-Client -IncludeManagementTools -WarningAction Ignore
    } 
    #Install features per role
    Write-Verbose "$VM is $Role."
    switch ($Role) {
    'Domain Controller' {
      #Add additional data disk to the domain controller, with host caching disabled
      if (-not(Get-AzureDataDisk -VM $AzureVM)) {
        Write-Verbose "Adding additional data disk..."
        Add-AzureDataDisk -CreateNew -DiskSizeInGB 60 -DiskLabel "ADDB" -HostCaching None -LUN 0 -VM $AzureVM | Update-AzureVM -ErrorAction Stop
      }
      Write-Verbose "Installing role 'AD-Domain-Services'"
      Invoke-Command -Session $VMSession -ScriptBlock {
        #Initialize and format additional disks     
        Get-Disk | Where-Object {$_.PartitionStyle -eq 'raw'} | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel "ADDB" -Confirm:$false
        #Install Role specific features 
        Add-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -WarningAction Ignore
      }
    } 'ADFS Server' {
      #Create Internal Load Balancer for the ADFS farm if not already created  
      if (-not(Get-AzureInternalLoadBalancer -ServiceName $CloudService) -and $InternalLBIP) {
        Write-Verbose "Creating/adding $vm to Internal Load Balancer $($AzureVM.AvailabilitySetName) ($InternalLBIP)"
        Add-AzureInternalLoadBalancer -ServiceName $CloudService -InternalLoadBalancerName $azurevm.AvailabilitySetName -SubnetName $Subnet -StaticVNetIPAddress $InternalLBIP
      }
      #Add the server to the Internal Load Balanced set and add 443 as endpoint
      if (-not((Get-AzureEndpoint -VM $AzureVM).InternalLoadBalancerName -eq $AzureVM.AvailabilitySetName)) {
        Write-Verbose "Adding Internal Load Balanced endpoint on port 443 to $VM"
        Add-AzureEndpoint -Name HTTPS -Protocol tcp -LocalPort 443 -PublicPort 443 -LBSetName $AzureVM.AvailabilitySetName -InternalLoadBalancerName $AzureVM.AvailabilitySetName -VM $AzureVM -DefaultProbe | Update-AzureVM -ErrorAction Stop
      }
      Write-Verbose "Installing role 'ADFS-Federation'"
      Invoke-Command -Session $VMSession -ScriptBlock {
        #Install Role specific features
        Add-WindowsFeature -Name ADFS-Federation -IncludeManagementTools -WarningAction Ignore
      }
    } 'Web Application Proxy' {
      #Add the server to the Cloud Service Load Balanced set and add 443 as endpoint
      if (-not((Get-AzureEndpoint -VM $AzureVM).LBSetName -eq $AzureVM.AvailabilitySetName)) {
        Write-Verbose "Adding Load Balanced endpoint on port 443 to $CloudService.cloudapp.net"
        Add-AzureEndpoint -Name HTTPS -Protocol tcp -LocalPort 443 -PublicPort 443 -LBSetName $AzureVM.AvailabilitySetName -VM $AzureVM -DefaultProbe -LoadBalancerDistribution sourceIP | Update-AzureVM -ErrorAction Stop
      } 
      Write-Verbose "Installing role 'Web-Application-Proxy'"
      Invoke-Command -Session $VMSession -ScriptBlock {
        #Install Role specific features
        Add-WindowsFeature -Name Web-Application-Proxy -IncludeManagementTools -WarningAction Ignore
      } 
    } 
   }
  } 
  end {
    Write-Verbose "Finished configuring $VM"
     
  }
}
function New-JDAzureVM {
  [CmdletBinding(SupportsShouldProcess=$true)]
  Param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$VMName = '',
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$CloudService,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$IPAddress,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Size,
    $VMCredentials,
    $DomainJoinCreds,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$SubnetName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$OperatingSystem,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$VnetName,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$AvailabilitySet,
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$AffinityGroup
  )
   
  if (-not(Get-AzureVM -ServiceName $CloudService -Name $VMName -WarningAction Ignore))  {
    #region VM Configuration 
    #Get the latest VM image based on the operating system choice
    $ImageName = (Get-AzureVMImage | Where-Object {$_.ImageFamily -eq $OperatingSystem} | Sort-Object -Property PublishedDate -Descending | Select-Object -First 1).ImageName
    #Construct VM Configuration
    $VMConfigHash = @{
      Name =  $VMName
      InstanceSize = $Size 
      ImageName = $ImageName
    }
    if ($AvailabilitySet -ne 'None') {
      $VMConfigHash["AvailabilitySetName"] = $AvailabilitySet
    }
    #VM Provisioning details
    $VMProvisionHash = @{ 
      AdminUsername = $VMCredentials.UserName
      Password = $VMCredentials.GetNetworkCredential().Password
      JoinDomain = $DomainName
      DomainUserName = $DomainJoinCreds.UserName.split("\")[1]
      DomainPassword = $DomainJoinCreds.GetNetworkCredential().Password
      Domain = $DomainShort
    }
    #Create VM configuration before deploying the new VM
    $VMConfig = New-AzureVMConfig @VMConfigHash | Add-AzureProvisioningConfig @VMProvisionHash -WindowsDomain -NoRDPEndpoint |
                    Set-AzureStaticVNetIP -IPAddress $IPAddress | Set-AzureSubnet -SubnetNames $SubnetName |
                        Set-AzureVMBGInfoExtension -ReferenceName 'BGInfo'
    #endregion VM Configuration
    #region Create VM
    Write-Verbose "Creating $VMName in the Cloud Service $CloudService"
    $AzureVMHash = @{
      ServiceName = $CloudService
      VMs = $VMConfig
      VnetName = $VnetName
      AffinityGroup  = $AffinityGroup
    }
    New-AzureVM @AzureVMHash -WaitForBoot -ErrorAction Stop -WarningAction Ignore
    #endregion Create VM
  } else {
    Write-Warning "$VMName do already exist..."
  }
}
 #endregion functions
 #Connect with Azure PowerShell
  Connect-Azure
  $AzureMachines = Import-Csv -Path $InputFile
  Write-Verbose "Starting deployment of machines at: $(Get-date -format u)"
foreach ($Machine in $AzureMachines) {
  Write-Verbose "Starting to process $($Machine.Name)"
  #Create VM Configuration hashtable based on input from CSV file
  $VirtualMachine = @{
    VMName = $Machine.Name
    CloudService = $Machine.CloudService
    IPAddress = $Machine.IP
    VMCredentials = $VMCredentials
    DomainJoinCreds = $DomainJoinCreds
    SubnetName = $Machine.SubnetName
    AvailabilitySet = $Machine.AvailabilitySet
    AffinityGroup = $AffinityGroup
    Size = $Machine.Size
    VnetName = $VnetName
    OperatingSystem = $ImageFamily
  }
  try {
    #Create virtual machine
    New-JDAzureVM @VirtualMachine -ErrorAction Stop
    #Wait for machine to get to the state "ReadyRole" before continuing.
    while ((Get-AzureVM -ServiceName $Machine.CloudService -Name $Machine.Name).status -ne "ReadyRole") {
      Write-Verbose "Waiting for $($Machine.Name) to start..."
      Start-Sleep -Seconds 15
    }
    $VMUri = Get-AzureWinRMUri -ServiceName $machine.CloudService -Name $Machine.Name
    #Create VM Role configuration
    $VMRoleConfiguration = @{
      Role = $Machine.Role
      VMUri = $VMUri
      VMCredentials = $VMCredentials
      VM = $Machine.Name
      CloudService = $Machine.CloudService 
      Subnet = $machine.SubnetName
    }
    #Add internal load balancer IP to the role configuration
    if ($Machine.InternalLB) {
      $VMRoleConfiguration["InternalLBIP"] = $Machine.InternalLB
    }
    #Role specific configuration of the virtual machine
    Configure-JDAzureVM @VMRoleConfiguration -ErrorAction Stop
  } catch {
    Write-Warning $_
  }
}
Write-Verbose "Finished deployment of machines at: $(Get-date -format u)"

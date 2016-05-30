function Get-VMdata{  

 <# 
 

03 .SYNOPSIS  

04 Get the configuration data of the VMs in Hyper-V via SCVMM 2012  

05     

06 .DESCRIPTION  

07 Use this function to get all VMs configuration in case of disaster or just statistics  

08     

09 .PARAMETER  xyz   

10     

11 .NOTES  

12 Author: Niklas Akerlund / RTS  

13 Date: 2012-02-13  

14 #>  

 param (  

    $VMHostGroup = "SE-DataCenter",  

    [Parameter(ValueFromPipeline=$True)][Alias('ClusterName')]  

    $VMHostCluster = $null,  

    $VMHost = $null,  

     [string]$CSVFile = "VMdata.csv",  

     [string]$HTMLReport = "VMdata.html" 

     )  

        

     $report = @()  

     if ($VMHostCluster -eq $null){  

         $VMHosts = (Get-SCVMHostGroup -Name $VMhostGroup).AllChildHosts  

     }else{  

             $VMHosts = (Get-SCVMHostCluster -Name $VMHostCluster).Nodes  

     }  

     $VMs = $VMHosts | Get-SCVirtualMachine 

        

     foreach ($VM in $VMs) {  

         $VHDs = $VM | Get-SCVirtualDiskDrive 

         $i = "1" 

         foreach ($VHDconf in $VHDs){   

             if($i -eq "1"){  

                 $data = New-Object PSObject -property @{  

                     VMName=$VM.Name  

                     vCPUs=$VM.CPUCount  

                     MemoryGB= $VM.Memory/1024  

                     VHDName = $VHDconf.VirtualHardDisk.Name  

                     VHDSize = $VHDconf.VirtualHardDisk.MaximumSize/1GB  

                     VHDCurrentSize = [Math]::Round($VHDconf.VirtualHardDisk.Size/1GB)  

                     VHDType = $VHDconf.VirtualHardDisk.VHDType  

                     VHDBusType = $VHDconf.BusType  

                     VHDBus = $VHDconf.Bus  

                     VHDLUN = $VHDconf.Lun  

                     VHDDatastore = $VHDconf.VirtualHardDisk.HostVolume  

                 }  

                 $i= "2" 

             }else{  

                 $data = New-Object PSObject -property @{  

                     VMName="" 

                     vCPUs="" 

                     MemoryGB= "" 

                     VHDName = $VHDconf.VirtualHardDisk.Name  

                     VHDSize = $VHDconf.VirtualHardDisk.MaximumSize/1GB  

                     VHDCurrentSize = [Math]::Round($VHDconf.VirtualHardDisk.Size/1GB)  

                     VHDType = $VHDconf.VirtualHardDisk.VHDType  

                     VHDBusType = $VHDconf.BusType  

                     VHDBus = $VHDconf.Bus  

                     VHDLUN = $VHDconf.Lun  

                     VHDDatastore = $VHDconf.VirtualHardDisk.HostVolume  

                 }  

             }  

             $report +=$data  

         }  

     }  

     $report | Select-Object VMName,vCPUs,MemoryGB,VHDName,VHDSize,VHDCurrentSize,VHDType,VHDBusType,VHDBus,VHDLUN,VHDDatastore | Export-Csv -Path $CSVFile -NoTypeInformation -UseCulture 

     $report | Select-Object VMName,vCPUs,MemoryGB,VHDName,VHDSize,VHDCurrentSize,VHDType,VHDBusType,VHDBus,VHDLUN,VHDDatastore | ConvertTo-HTML | Out-File $HTMLReport 

 } 

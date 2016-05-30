$YourCluster = Get-SCVMHostCluster -Name NE-TEST-VSC2

$YourRunAs = Get-SCRunAsAccount -Name "S_SCS_PRD_SCVMM_LM"

Set-SCVmHostCluster -VMHostCluster $YourCluster -VMHostManagementCredential  $YourRunAs 

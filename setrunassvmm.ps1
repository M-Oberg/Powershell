$TCNECluster = Get-SCVMHostCluster -Name NE-TEST-VSC2
$TCNERunAs = Get-SCRunAsAccount -Name "S_SCS_PRD_SCVMM_LM"
Set-SCVmHostCluster -VMHostCluster $TCNECluster -VMHostManagementCredential $TCNERunAs
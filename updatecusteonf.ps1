$TCNERunAs = Get-SCRunAsAccount -Name "S_SCS_PRD_SCVMM_LM"
Set-SCVmHostCluster -VMHostCl NE-TST-VSC4N01 -VMHostManagementCredential $TCNERunAs
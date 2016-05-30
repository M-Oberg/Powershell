Add-AzureAccount

Get-AzureSubscription

Get-AzureSubscription -SubscriptionId "da45d03f-1986-49d0-9294-7958fc386ce0" -Default

Get-AzureSubscription -SubscriptionId "939c1da9-8f7d-470a-b0ae-40c0fd5768c5" -Default

Select-AzureSubscription -SubscriptionID "da45d03f-1986-49d0-9294-7958fc386ce0"

Select-AzureSubscription -SubscriptionId "939c1da9-8f7d-470a-b0ae-40c0fd5768c5" -Default

Switch-AzureMode -Name AzureResourceManager

Get-AzureLocation

New-AzureResourceGroup -Name "TCNE-Enterprise-TST-Network" -Location "West Europe"


Select-AzureSubscription -SubscriptionName "TCNE Enterprise PRD"

New-AzureResourceGroup -Name "TCNE-Enterprise-PRD-Network" -Location "West Europe"

New-AzureResourceGroup -Name "TCNE-Enterprise-PRD-Network" -Location "West Europe"

#Remove-AzureResourceGroup -Name "TCNE-Enterprise-PRD-Network"

Select-AzureSubscription -Name "TCNE Enterprise TST MSDN"

Set-AzureResourceGroup -Name "TCNE-Enterprise-PRD-Network" -Tag @{Name="Department";Value="350"}

New-AzureResourceGroup -Name "TCNE-Enterprise-PRD-AD" -Location "West Europe" -Tag @{Name="Department";Value="350"}

Get-AzureResourceGroup

Set-AzureResourceGroup -Name "TCNE-Enterprise-TST-Network" -Tag @{Name="Department";Value="350"}
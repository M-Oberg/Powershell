$cred = Get-Credential
Login-AzureRmAccount -Credential $cred
login-azureRmAccount
get-azureRmSubscription
Get-azureRmSubscription -Subscriptionname "TCNE BIT Infrastructure 350 TST MSDN"
Get-AzureRmContext
Get-AzureRmResourceGroup -name "mms-weu" -Verbose
Get-AzureRmResourceGroup -name "mms-weu"

Get-AzureRmResourceGroup -Name "mms-weu"

Get-AzureRmResource -ResourceName "mms-weu"

Find-AzureRmResource -TagName billTo -TagValue TCNE-BIT-350 | %{ $_.ResourceName }

Find-AzureRmResourceGroup -Tag @{ Name="billTo"; Value="TCNE-BIT-350" } | %{ $_.Name }

Set-AzureRmResourceGroup -Name PROD-GROUP -Tag @( @{ Name="Ankeborg"; Value="Kalle" }, @{ Name="Hus"; Value="Pengabingen"} )
Find-AzureRmResourceGroup -Tag @{ Name="Hus"; Value="Pengabingen" } | %{ $_.Name }
Get-AzureRMTag

$tags = (Get-AzureRmResourceGroup -Name PROD-GROUP).Tags
$tags += @{Name="status";Value="approved"}
Set-AzureRmResourceGroup -Name PROD-GROUP -Tag $tags

$policy = New-AzureRmPolicyDefinition -Name regionPolicyDefinition -Description "Policy to allow resource creation only in certain regions BLABLABLA" -Policy '{  
  "if" : {
    "not" : {
      "field" : "location",
      "in" : ["northeurope" , "westeurope"]
    }
  },
  "then" : {
    "effect" : "deny"
  }
}'  

Get-AzureRmPolicyDefinition

New-AzureRmPolicyAssignment -Name regionPolicyAssignment -PolicyDefinition $policy -Scope    /subscriptions/939c1da9-8f7d-470a-b0ae-40c0fd5768c5/resourceGroups/PROD-GROUP

Get-AzureRmPolicyDefinition
Remove-AzureRmPolicyAssignment
Get-AzureRmPolicyAssignment
Set-AzureRmPolicyAssignment


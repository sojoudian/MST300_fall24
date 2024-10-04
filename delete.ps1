# Log in to Azure account
Connect-AzAccount

# Get all resource groups in the current subscription
$resourceGroups = Get-AzResourceGroup

# Loop through each resource group and delete it
foreach ($rg in $resourceGroups) {
    Write-Host "Deleting resource group:" $rg.ResourceGroupName
    # Delete the resource group and all resources inside it
    Remove-AzResourceGroup -Name $rg.ResourceGroupName -Force -AsJob
}

Write-Host "All resource groups and their resources have been deleted."


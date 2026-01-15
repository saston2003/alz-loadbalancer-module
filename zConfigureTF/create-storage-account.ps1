param(
    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$Location = "NorthEurope"
)

# Login to Azure (if not already logged in)
Connect-AzAccount

# Create the resource group if it doesn't exist
if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}

# Create the storage account
New-AzStorageAccount `
    -ResourceGroupName $ResourceGroupName `
    -Name $StorageAccountName `
    -Location $Location `
    -SkuName Standard_LRS `
    -Kind StorageV2

Write-Host "Storage account '$StorageAccountName' created in resource group '$ResourceGroupName' at location '$Location'."
# PowerShell script to create a new Azure resource group

param(
    [string]$ResourceGroupName,
    [string]$Location = "East US"  # Default location
)

# Login to Azure account
az login

# Create the resource group
az group create --name $ResourceGroupName --location $Location

Write-Host "Resource group '$ResourceGroupName' created in location '$Location'."       
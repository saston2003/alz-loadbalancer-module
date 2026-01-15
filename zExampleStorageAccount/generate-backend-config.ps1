# Script to generate backend.config from terraform.tfvars
# Reads the storage_account_name from tfvars and creates backend.config with matching key

$tfvarsPath = "terraform.tfvars"
$backendConfigPath = "backend.config"

# Read the storage account name from terraform.tfvars
$storageAccountName = (Select-String -Path $tfvarsPath -Pattern 'storage_account_name\s*=\s*"([^"]+)"').Matches.Groups[1].Value

if ($storageAccountName) {
    # Generate the backend.config file
    $keyValue = "$storageAccountName.tfstate"
    "key = `"$keyValue`"" | Out-File -FilePath $backendConfigPath -Encoding utf8 -NoNewline
    
    Write-Host "✓ Generated backend.config with key: $keyValue" -ForegroundColor Green
} else {
    Write-Host "✗ Could not find storage_account_name in $tfvarsPath" -ForegroundColor Red
    exit 1
}

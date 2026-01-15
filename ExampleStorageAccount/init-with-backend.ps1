# All-in-one script: Generate backend config and initialize Terraform
# Usage: .\init-with-backend.ps1

$tfvarsPath = "terraform.tfvars"
$backendConfigPath = "backend.config"

Write-Host "→ Reading storage_account_name from $tfvarsPath..." -ForegroundColor Cyan

# Read the storage account name from terraform.tfvars
$storageAccountName = (Select-String -Path $tfvarsPath -Pattern 'storage_account_name\s*=\s*"([^"]+)"').Matches.Groups[1].Value

if (-not $storageAccountName) {
    Write-Host "✗ Could not find storage_account_name in $tfvarsPath" -ForegroundColor Red
    exit 1
}

# Generate the backend.config file
$keyValue = "$storageAccountName.tfstate"
"key = `"$keyValue`"" | Out-File -FilePath $backendConfigPath -Encoding utf8 -NoNewline

Write-Host "✓ Generated backend.config with key: $keyValue" -ForegroundColor Green

# Initialize Terraform with the backend config
Write-Host "→ Running terraform init with backend config..." -ForegroundColor Cyan
terraform init -reconfigure -backend-config=backend.config

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Terraform initialized successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ Terraform init failed" -ForegroundColor Red
    exit 1
}

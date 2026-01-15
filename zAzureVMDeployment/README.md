# Azure VM Deployment with Terraform

This Terraform configuration deploys 2 Windows Server 2022 virtual machines on Azure with the following specifications:

## Infrastructure Components

### Virtual Machines
- **Count**: 2 VMs (vm1, vm2)
- **OS**: Windows Server 2022 Datacenter
- **Size**: Standard_B2s (2 vCPUs, 4 GB RAM)
- **Admin Username**: manage
- **Admin Password**: Password123!!

### Storage
- **OS Disk**: StandardSSD_LRS (SSD)
- **Data Disk**: StandardSSD_LRS (SSD), 128 GB per VM

### Networking
- **VNet**: 10.0.0.0/16 address space
- **Subnets**: 6 subnets with standard Azure IP addressing
  - subnet-1: 10.0.1.0/24
  - subnet-2: 10.0.2.0/24
  - subnet-3: 10.0.3.0/24
  - subnet-4: 10.0.4.0/24
  - subnet-5: 10.0.5.0/24
  - subnet-6: 10.0.6.0/24
- **Public IPs**: Static public IP for each VM (internet accessible)
- **NSG**: Network Security Group allowing RDP (3389), HTTP (80), HTTPS (443)

### Location
- **Region**: North Europe

## Deployment Instructions

### Prerequisites
1. Azure CLI installed and authenticated (`az login`)
2. Terraform installed (version >= 1.0)
3. Azure backend storage account configured (DevBoxBackend-RG/devboxbackend)

### Steps to Deploy

1. **Initialize Terraform**:
   ```powershell
   cd c:\git\skylab1\AzureVMDeployment
   terraform init -backend-config=backend.config
   ```

2. **Review the plan**:
   ```powershell
   terraform plan
   ```

3. **Apply the configuration**:
   ```powershell
   terraform apply
   ```

4. **Get outputs** (VM IPs, RDP connection strings):
   ```powershell
   terraform output
   ```

### Connecting to VMs

After deployment, use the RDP connection strings from the output:
```
mstsc /v:<PUBLIC_IP> /admin
Username: manage
Password: Password123!!
```

## File Structure

- `main.tf` - Main infrastructure configuration
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Variable values
- `provider.tf` - Provider and backend configuration
- `outputs.tf` - Output definitions
- `backend.config` - Backend state file key

## Security Notes

⚠️ **Important**: The configuration allows RDP access from any IP address (`*`). For production use:
1. Restrict source IPs in the NSG rules
2. Use Azure Bastion for secure RDP access
3. Store passwords in Azure Key Vault
4. Enable Azure Security Center recommendations

## Cleanup

To destroy all resources:
```powershell
terraform destroy
```

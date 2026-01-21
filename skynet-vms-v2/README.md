# Skynet VMs Deployment

This Terraform configuration deploys two Windows Server 2022 VMs (Skynet01 and Skynet02) to an existing Azure Virtual Network.

## Prerequisites

- Terraform >= 1.5.0
- Azure CLI installed and authenticated
- Access to subscription `6e05c1d3-15e2-4383-a0dc-2d5a20e44289`
- Existing VNet: `SDSvNetTest-vnet` in resource group `m-spokeconfig-rg`
- Existing subnet: `subnet2` (10.241.11.0/24)

## Resources Created

- Resource Group: `Skynet-VMs-RG`
- Network Security Group with ALZ-compliant rules
- 2 x Network Interfaces
- 2 x Windows Server 2022 VMs (Standard_D2s_v3)
- 2 x Data Disks (128GB StandardSSD_LRS)

## VM Configuration

- **OS**: Windows Server 2022 Datacenter
- **Size**: Standard_D2s_v3 (2 vCPUs, 8 GB RAM)
- **OS Disk**: StandardSSD_LRS
- **Data Disk**: 128GB StandardSSD_LRS
- **Network**: Connected to existing SDSvNetTest-vnet/subnet2
- **Public IP**: None (private VMs only)
- **Admin Username**: manage (default)

## Deployment Steps

### 1. Initialize Terraform

```powershell
cd skynet-vms-v2
terraform init
```

### 2. Create terraform.tfvars

Create a `terraform.tfvars` file with your admin password:

```hcl
admin_password = "YourSecurePassword123!"
```

**Note**: Never commit this file to git - it's already in .gitignore

### 3. Review the Plan

```powershell
terraform plan
```

### 4. Deploy

```powershell
terraform apply
```

Type `yes` when prompted to confirm.

### 5. View Outputs

```powershell
terraform output
```

## Security

- No public IP addresses assigned
- NSG rules block RDP/SSH from Internet
- RDP access only from VirtualNetwork source
- Compliant with Azure Landing Zone policies

## Clean Up

To destroy all resources:

```powershell
terraform destroy
```

## Customization

You can override defaults by setting variables in `terraform.tfvars`:

```hcl
resource_group_name = "MyCustomRG"
location            = "uksouth"
vm_size             = "Standard_D4s_v3"
admin_username      = "myadmin"
admin_password      = "YourSecurePassword123!"
data_disk_size_gb   = 256
```

## Troubleshooting

### Azure Policy Errors

If you encounter policy violations:
- Ensure NSG rules deny Internet access to management ports
- Verify subnet association in existing VNet
- Check that all resources are in UK South region

### State Issues

If you need to start fresh:
```powershell
# Remove state files
Remove-Item .terraform -Recurse -Force
Remove-Item *.tfstate*
terraform init
```

## Support

For issues or questions, refer to the main repository documentation.

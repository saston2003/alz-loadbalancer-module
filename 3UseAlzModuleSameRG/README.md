# Option B: Load Balancer with VMs in Same Resource Group

This directory demonstrates **Option B** - creating an Azure Load Balancer with VMs in the **same resource group**.

## What This Creates

1. **Internal Load Balancer** - Standard SKU with private IP
2. **Two Windows VMs** (Skynet01, Skynet02) in the same RG as the LB
3. **Network Interfaces** - One for each VM
4. **Backend Pool Associations** - VMs automatically added to LB backend pool
5. **IIS Installation** - Custom script extension installs IIS on both VMs

## Prerequisites

- Existing resource group: `rg-sdstest-lb-prod`
- Existing VNet: `SDSvNetTest-vnet` in `m-spokeconfig-rg`
- Existing subnet: `subnet2`

## How to Deploy

### 1. Review Configuration

Edit `terraform.tfvars`:
- Update network details (VNet, subnet, RG names)
- Set admin password (or use environment variable)
- Review VM size and other settings

### 2. Initialize Terraform

```powershell
cd C:\repo\alz-loadbalancer-module\3UseAlzModuleSameRG
terraform init
```

### 3. Plan Deployment

```powershell
terraform plan
```

Expected resources to create:
- 1 Load balancer
- 1 Backend pool
- 2 Health probes
- 2 Load balancing rules
- 2 Network interfaces
- 2 Backend pool associations
- 2 Virtual machines
- 2 VM extensions (IIS)

**Total: ~12 resources**

### 4. Deploy

```powershell
terraform apply
```

This takes ~10-15 minutes (VMs take longest).

### 5. Test Load Balancer

```powershell
# Get the load balancer IP from outputs
terraform output frontend_ip_address

# Test from one of the VMs or a machine in the same VNet
Invoke-WebRequest -Uri "http://10.241.11.200" -UseBasicParsing
```

You should see responses from Skynet01 or Skynet02.

## Key Features

- **Single Terraform workspace** - Everything managed together
- **Same resource group** - Load balancer and VMs in same RG for simplicity
- **Automatic association** - VMs added to backend pool during creation
- **IIS pre-installed** - Ready for testing immediately
- **Module outputs** - Backend pool ID available for other resources

## Clean Up

```powershell
terraform destroy
```

This removes:
- Both VMs (including OS disks)
- Network interfaces
- Backend pool associations
- Load balancer
- All probes and rules

## Differences from Option A/C

- **Option A/C**: VMs already exist, use data sources to associate
- **Option B**: Creates NEW VMs and associates during creation
- **Same RG**: Simpler management, all resources together
- **Module reference**: Uses `module.internal_lb.backend_address_pool_id`

## Files in This Directory

- `main.tf` - Load balancer module + VM resources
- `variables.tf` - Variable declarations
- `terraform.tfvars` - Configuration values
- `outputs.tf` - Output values after deployment
- `README.md` - This file

## Notes

- Admin password in tfvars is for testing only - use Key Vault or env vars for production
- VMs use Windows Server 2022 Datacenter
- Load distribution uses "Default" (5-tuple hash) for session persistence
- Health probes use TCP on ports 80 and 443

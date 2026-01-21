# Skynet VMs - Terraform Configuration

This Terraform configuration deploys 2 Windows Server VMs connected to an existing Azure VNet with full Azure Landing Zone policy compliance.

## Features

✅ **Connects to existing VNet** (`SDSvNetTest-vnet` in `m-spokeconfig-rg`)  
✅ **No public IPs** - VMs are private only  
✅ **ALZ Policy Compliant** - Blocks RDP/SSH from Internet  
✅ **VM Names**: `Skynet01` and `Skynet02`  
✅ **Boot diagnostics enabled**  
✅ **Managed disks** with data disks attached  

## Prerequisites

1. Existing VNet `SDSvNetTest-vnet` in resource group `m-spokeconfig-rg`
2. Azure CLI logged in with appropriate permissions
3. Terraform >= 1.5.0

## Quick Start

### 1. Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set your admin_password
```

### 2. Initialize Terraform

```powershell
terraform init
```

### 3. Review the Plan

```powershell
terraform plan
```

### 4. Deploy

```powershell
terraform apply
```

### 5. Clean Up

```powershell
terraform destroy
```

## What Gets Created

- **Resource Group**: `Skynet-VMs-RG`
- **2 Windows VMs**: `Skynet01`, `Skynet02`
  - Size: `Standard_D2s_v3`
  - OS: Windows Server 2022 Datacenter
  - No public IPs (private only)
- **2 Network Interfaces**: Connected to existing VNet subnet
- **Network Security Group**: ALZ-compliant rules
- **2 Data Disks**: 128 GB Premium SSD per VM

## Configuration

All settings can be customized in `variables.tf` or `terraform.tfvars`:

| Variable | Default | Description |
|----------|---------|-------------|
| `resource_group_name` | `Skynet-VMs-RG` | Resource group name |
| `location` | `North Europe` | Azure region |
| `vm_size` | `Standard_D2s_v3` | VM size |
| `admin_username` | `azureadmin` | Admin username |
| `admin_password` | *required* | Admin password |
| `os_disk_type` | `Premium_LRS` | OS disk type |
| `data_disk_type` | `Premium_LRS` | Data disk type |
| `data_disk_size_gb` | `128` | Data disk size |

## Azure Landing Zone Compliance

This configuration follows ALZ best practices:

- ✅ Management ports (RDP/SSH) blocked from Internet
- ✅ RDP access only from VirtualNetwork
- ✅ No public IPs on VMs
- ✅ Boot diagnostics enabled
- ✅ Managed disks with appropriate SKU
- ✅ Proper tagging for governance

## Access VMs

Since VMs have no public IPs, access them via:

1. **Azure Bastion** (recommended)
2. **VPN Gateway**
3. **ExpressRoute**
4. **Jump box** within the VNet

## Outputs

After deployment, Terraform outputs:

- VM names
- Private IP addresses
- Resource group name
- NSG name
- Connected VNet information

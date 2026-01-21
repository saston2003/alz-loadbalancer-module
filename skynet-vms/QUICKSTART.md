# Quick Deploy Instructions

## Deploy VMs

```powershell
cd C:\repo\alz-loadbalancer-module\skynet-vms

# Set password as environment variable
$env:TF_VAR_admin_password = "YourSecurePassword123!"

# Deploy
terraform apply -auto-approve
```

## Check Resources

```powershell
# List all resources created
terraform state list

# Show outputs
terraform output
```

## Destroy Everything

```powershell
terraform destroy -auto-approve
```

## Access VMs

VMs have no public IPs. Access via:
- Azure Bastion
- VPN/ExpressRoute
- Jump box in the VNet

VM Names: `Skynet01`, `Skynet02`  
Admin User: `manage`  
Admin Password: The one you set

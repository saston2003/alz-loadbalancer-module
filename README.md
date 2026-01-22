# Azure Load Balancer Module for Azure Landing Zones (ALZ)

A Terraform module to deploy **Azure Standard Load Balancers** that are **compliant with common Azure Landing Zone (ALZ) guardrails**. It supports internal (private) and public LBs, enforces Standard SKUs, wires **diagnostic settings** to Log Analytics, and is **NAT Gateway–friendly** for spoke networks.

> Built for enterprise platforms: policy-aware, tag-ready, and easy to drop into CI/CD.

---

## ✨ Features

- **Standard SKU only** (LB & Public IP)
- **Internal or Public** LB with a single module switch (`type = "internal"|"public"`)
- **Frontend configuration**: private IP (static/dynamic) or public IP (existing or created)
- **Backend pools, probes, and rules** as lists/objects (stable `for_each` keys)
- **Diagnostics** to Log Analytics (optional override of categories)
- **Outbound strategy**: disable LB SNAT per rule; prefer **NAT Gateway** in spokes
- **Zone-ready**: optional PIP zones for zonal/zone-redundant designs
- **Tag propagation** to all resources

---

## 📁 Repository Layout

```
.
├─ modules/
│  └─ alz-load-balancer/
│     ├─ versions.tf
│     ├─ variables.tf
│     ├─ main.tf
│     └─ outputs.tf
└─ examples/
   ├─ internal-lb/
   │  ├─ providers.tf
   │  ├─ versions.tf
   │  ├─ main.tf
   │  ├─ variables.tf
   │  └─ terraform.tfvars
   └─ public-lb/
      ├─ providers.tf
      ├─ versions.tf
      ├─ main.tf
      ├─ variables.tf
      └─ terraform.tfvars
```

---

## ✅ Prerequisites

- Terraform **v1.5+**
- AzureRM provider **v3.116+**
- A **Resource Group** and (for internal LBs) a **VNet/Subnet**
- A **Log Analytics Workspace** (if `enable_diagnostics = true`)
- Appropriate **RBAC** (e.g., *Network Contributor*) and the `Microsoft.Network` resource provider registered at subscription scope
- Landing Zone guardrails understood (e.g., public IPs may be denied in spokes; Basic SKUs denied)

---

## 🚀 Quick Start

### Internal LB (Spoke)

```hcl
module "internal_lb" {
  source              = "./modules/alz-load-balancer"
  name                = "app-ilb-prod"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_scope    = "spoke"

  type      = "internal"
  subnet_id = azurerm_subnet.app.id

  frontend_private_ip_allocation = "Static"
  frontend_private_ip_address    = "10.20.3.10"

  probes = [
    { name = "tcp-443", protocol = "Tcp", port = 443, interval = 5, unhealthy_threshold = 2 }
  ]

  lb_rules = [
    {
      name                  = "https-443"
      protocol              = "Tcp"
      frontend_port         = 443
      backend_port          = 443
      probe_name            = "tcp-443"
      disable_outbound_snat = true # using NAT Gateway on subnet
    }
  ]

  enable_diagnostics         = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id

  tags = {
    owner      = "steve.aston"
    env        = "prod"
    costCenter = "IT-PLAT"
  }
}
```

> **Tip:** Attach a **NAT Gateway** to the app subnet for deterministic egress; keep `enable_outbound_rule = false` and set `disable_outbound_snat = true` on rules.

### Public LB (Hub)

```hcl
module "public_lb" {
  source              = "./modules/alz-load-balancer"
  name                = "ingress-plb-prod"
  location            = "uksouth"
  resource_group_name = azurerm_resource_group.hub_rg.name
  deployment_scope    = "hub"

  type             = "public"
  create_public_ip = true
  # public_ip_zones = ["1","2","3"]

  probes = [
    { name = "tcp-443", protocol = "Tcp", port = 443 }
  ]

  lb_rules = [
    {
      name         = "https-443"
      protocol     = "Tcp"
      frontend_port= 443
      backend_port = 443
      probe_name   = "tcp-443"
    }
  ]

  enable_diagnostics         = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id

  tags = {
    owner = "platform-team"
    env   = "prod"
  }
}
```

---

## 🔧 Module Inputs (Variables)

> See `modules/alz-load-balancer/variables.tf` for full type definitions and defaults.

- **Core**
  - `name` *(string, required)*: Base name for the LB and child resources
  - `location` *(string, required)*
  - `resource_group_name` *(string, required)*
  - `deployment_scope` *(string, default: `spoke`)*: `hub|spoke|sandbox`
  - `type` *(string, default: `internal`)*: `internal|public`
  - `tags` *(map(string), default: `{}`)*

- **Internal LB**
  - `subnet_id` *(string)*
  - `frontend_private_ip_allocation` *(Static|Dynamic, default: Static)*
  - `frontend_private_ip_address` *(string, optional)*

- **Public LB**
  - `create_public_ip` *(bool, default: false)*
  - `public_ip_id` *(string, optional)*
  - `public_ip_sku` *(string, default: Standard)*
  - `public_ip_allocation_method` *(string, default: Static)*
  - `public_ip_sku_tier` *(Regional|Global, default: Regional)*
  - `public_ip_zones` *(list(string), optional)*

- **Backend & Rules**
  - `backend_pool_name` *(string, default: `beap`)*
  - `probes` *(list(object), default: `[]`)*
  - `lb_rules` *(list(object), default: `[]`)*
  - `enable_outbound_rule` *(bool, default: false)*
  - `outbound_protocol` *(Tcp|Udp|All, default: Tcp)*
  - `allocated_outbound_ports` *(number, default: 1024)*

- **Diagnostics**
  - `enable_diagnostics` *(bool, default: **false**)*: Enable diagnostic settings (recommended for production)
  - `log_analytics_workspace_id` *(string, required if diagnostics enabled)*
  - `diagnostic_categories` *(list(string), optional)*: Auto-discovers all available categories if not specified

---

## 📤 Outputs

- `lb_id` – ID of the load balancer
- `lb_frontend_ip_configuration_name` – Name of the frontend config
- `backend_address_pool_id` – Backend pool ID (attach NICs/VMSS)
- `public_ip_id` – ID of created public IP (if any)
- `private_frontend_ip` – The static private IP (internal LB)

---

## 🛡️ ALZ-Compliant Deployment Guide

This section provides a complete guide for deploying an Azure Landing Zone (ALZ) compliant load balancer.

### ALZ Compliance Checklist

✅ **Standard SKU Load Balancer** (automatically enforced by module)  
✅ **Internal Load Balancer** for spoke workloads (keeps traffic private)  
✅ **Static Private IP allocation** (predictable networking)  
✅ **No outbound rules** (use NAT Gateway instead)  
✅ **Health probes configured** (application monitoring)  
✅ **Diagnostics enabled** (optional, enable for production)  
✅ **Resource tags applied** (governance and cost tracking)  
✅ **Deployed to spoke VNet** (network segmentation)  

### Complete ALZ-Compliant Example

```hcl
# Data sources to reference existing infrastructure
data "azurerm_resource_group" "lb_rg" {
  name = "rg-spoke-app-prod"
}

data "azurerm_virtual_network" "spoke_vnet" {
  name                = "vnet-spoke-prod"
  resource_group_name = "rg-network-prod"  # VNet often in different RG
}

data "azurerm_subnet" "app_subnet" {
  name                 = "snet-app"
  virtual_network_name = data.azurerm_virtual_network.spoke_vnet.name
  resource_group_name  = data.azurerm_virtual_network.spoke_vnet.resource_group_name
}

# ALZ-compliant internal load balancer
module "alz_lb" {
  source = "git::https://github.com/your-org/alz-loadbalancer-module.git//modules/alz-load-balancer?ref=v1.0.0"

  # Basic configuration
  name                = "app-ilb-prod"
  location            = "uksouth"
  resource_group_name = data.azurerm_resource_group.lb_rg.name
  deployment_scope    = "spoke"

  # Internal LB with static IP (ALZ best practice)
  type                           = "internal"
  subnet_id                      = data.azurerm_subnet.app_subnet.id
  frontend_private_ip_allocation = "Static"
  frontend_private_ip_address    = "10.20.3.10"  # Choose IP from subnet range

  # Backend pool
  backend_pool_name = "backend-pool"

  # Health probes (application-level checks recommended)
  probes = [
    {
      name                = "https-443"
      protocol            = "Tcp"              # Use Http/Https for app-level checks
      port                = 443
      interval            = 5
      unhealthy_threshold = 2
    },
    {
      name                = "http-80"
      protocol            = "Tcp"
      port                = 80
      interval            = 5
      unhealthy_threshold = 2
    }
  ]

  # Load balancing rules
  lb_rules = [
    {
      name                    = "https-443"
      protocol                = "Tcp"
      frontend_port           = 443
      backend_port            = 443
      probe_name              = "https-443"
      disable_outbound_snat   = true           # ALZ: Use NAT Gateway, not LB SNAT
      enable_floating_ip      = false
      idle_timeout_in_minutes = 4
    },
    {
      name                    = "http-80"
      protocol                = "Tcp"
      frontend_port           = 80
      backend_port            = 80
      probe_name              = "http-80"
      disable_outbound_snat   = true           # ALZ: Use NAT Gateway, not LB SNAT
      enable_floating_ip      = false
      idle_timeout_in_minutes = 4
    }
  ]

  # No outbound rules (ALZ: use NAT Gateway on subnet instead)
  enable_outbound_rule = false

  # Diagnostics (enable for production)
  enable_diagnostics         = true
  log_analytics_workspace_id = "/subscriptions/YOUR_SUB_ID/resourceGroups/rg-platform/providers/Microsoft.OperationalInsights/workspaces/law-platform"
  diagnostic_categories      = null  # Auto-discover all categories

  # ALZ governance tags (required)
  tags = {
    owner      = "your-name"
    env        = "prod"
    costCenter = "IT-DEPT"
    service    = "app-name"
    managedBy  = "terraform"
    compliance = "alz"
    dataClass  = "internal"
  }
}

# Add VMs to backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vm1" {
  network_interface_id    = azurerm_network_interface.vm1_nic.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = module.alz_lb.backend_address_pool_id
}

resource "azurerm_network_interface_backend_address_pool_association" "vm2" {
  network_interface_id    = azurerm_network_interface.vm2_nic.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = module.alz_lb.backend_address_pool_id
}
```

### Key ALZ Design Decisions

#### 1. **Internal vs Public Load Balancers**
- **Spoke workloads**: Use **internal** load balancers (private traffic only)
- **Hub workloads**: Public load balancers may be allowed, but check policies
- **Internet ingress**: Consider Azure Application Gateway or Azure Front Door instead

#### 2. **Static IP Allocation**
Choose a static IP from your subnet range for predictable networking:
```hcl
frontend_private_ip_allocation = "Static"
frontend_private_ip_address    = "10.20.3.10"  # First 5 IPs reserved by Azure
```

#### 3. **Outbound Connectivity Strategy**
ALZ best practice: **NAT Gateway** on the subnet, not load balancer outbound rules
```hcl
# In load balancer configuration
enable_outbound_rule = false

# On each load balancing rule
disable_outbound_snat = true

# In your network configuration (separate resource)
resource "azurerm_nat_gateway" "spoke" {
  name                = "nat-spoke-prod"
  location            = "uksouth"
  resource_group_name = "rg-network-prod"
}

resource "azurerm_subnet_nat_gateway_association" "app" {
  subnet_id      = data.azurerm_subnet.app_subnet.id
  nat_gateway_id = azurerm_nat_gateway.spoke.id
}
```

#### 4. **Health Probes**
Use **application-level** health checks for production:
- **TCP probes**: Simple port availability check
- **HTTP/HTTPS probes**: Application health endpoint (recommended)

```hcl
# HTTP health check example
probes = [
  {
    name         = "http-health"
    protocol     = "Http"
    port         = 80
    request_path = "/health"    # Your app's health endpoint
    interval     = 5
    unhealthy_threshold = 2
  }
]
```

#### 5. **Diagnostics & Monitoring**
Enable diagnostics for production environments:
```hcl
enable_diagnostics         = true
log_analytics_workspace_id = "/subscriptions/.../workspaces/law-platform"
diagnostic_categories      = null  # Auto-discovers: LoadBalancerProbeHealthStatus, LoadBalancerHealthEvent, AllMetrics
```

#### 6. **Cross-Resource Group VNets**
Common in hub-spoke architectures where VNet is in a different resource group:
```hcl
data "azurerm_virtual_network" "vnet" {
  name                = "vnet-spoke-prod"
  resource_group_name = "rg-network-prod"  # Different from load balancer RG
}
```

#### 7. **Required Tags**
Apply governance tags required by your organization:
```hcl
tags = {
  owner      = "team-name"         # REQUIRED: Resource owner
  env        = "prod"              # REQUIRED: Environment
  costCenter = "IT-DEPT"           # REQUIRED: Cost allocation
  service    = "app-name"          # REQUIRED: Service name
  managedBy  = "terraform"         # How managed
  compliance = "alz"               # Compliance framework
  dataClass  = "internal"          # Data classification
}
```

### Common ALZ Scenarios

#### Multi-Port Web Application (HTTP + HTTPS)
```hcl
probes = [
  { name = "http-80", protocol = "Tcp", port = 80 },
  { name = "https-443", protocol = "Tcp", port = 443 }
]

lb_rules = [
  { name = "http-80", protocol = "Tcp", frontend_port = 80, backend_port = 80, 
    probe_name = "http-80", disable_outbound_snat = true },
  { name = "https-443", protocol = "Tcp", frontend_port = 443, backend_port = 443, 
    probe_name = "https-443", disable_outbound_snat = true }
]
```

#### SQL Server AlwaysOn
```hcl
probes = [
  { name = "sql-probe", protocol = "Tcp", port = 59999 }  # AlwaysOn probe port
]

lb_rules = [
  {
    name                    = "sql-1433"
    protocol                = "Tcp"
    frontend_port           = 1433
    backend_port            = 1433
    probe_name              = "sql-probe"
    enable_floating_ip      = true              # REQUIRED for SQL AlwaysOn
    disable_outbound_snat   = true
    idle_timeout_in_minutes = 30                # Longer for database connections
  }
]
```

### Deployment Steps

1. **Before Deployment**
   - Verify VNet and subnet exist
   - Choose static IP from subnet range (avoid first 5 IPs)
   - Prepare Log Analytics Workspace ID (if enabling diagnostics)
   - Update all tags with your organization's values
   - Ensure NAT Gateway is configured on subnet (if needed)

2. **Deploy Load Balancer**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **After Deployment**
   - Add VMs/NICs to backend pool
   - Verify health probes are passing in Azure Portal
   - Test connectivity through the load balancer IP
   - Configure DNS A record (if needed)
   - Set up Azure Monitor alerts for backend health

4. **Validation**
   - Check Azure Portal → Load Balancer → Insights
   - Verify backend pool health status
   - Test application connectivity through LB IP
   - Review diagnostic logs in Log Analytics

---

## 🛡️ ALZ/Policy Compliance Notes

- **Standard SKUs only**: This module enforces Standard LB/PIP (Basic is commonly denied in ALZ).
- **Public IP governance**: Public IPs may be **denied in spokes**; place public ingress in **hub** or use **App Gateway/Front Door** patterns.
- **Diagnostics**: Diagnostics are **disabled by default** for flexibility. Enable with `enable_diagnostics = true` for production environments.
- **Tags**: Supply required tags (`owner`, `env`, `costCenter`, etc.) to satisfy tag policies.
- **NSG rules for probes**: Allow the `AzureLoadBalancer` service tag on backend NSGs for health probes.
- **Outbound**: Prefer **NAT Gateway** on spoke subnets; avoid LB outbound SNAT unless required.

---

## 🧪 Running the Examples

From an example directory (e.g., `examples/internal-lb`):

```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

Update `terraform.tfvars` with your **Resource Group names** and **Log Analytics Workspace ID**.

---

## 🔍 Troubleshooting

- **Policy Deny**: Read the error’s `policyAssignmentId`. Typical causes:
  - Public IP not allowed in the subscription/management group
  - Missing required tags
  - Diagnostics not configured when required
  - Disallowed locations or SKUs
- **Health probe failures**: Ensure backend NSG allows `AzureLoadBalancer` on the **probe port**; confirm UDRs don’t blackhole probe traffic via a firewall.
- **SNAT exhaustion/egress IP drift**: Attach a **NAT Gateway** to the subnet and set `disable_outbound_snat = true` on LB rules.

---

## 🧩 Extensibility

- Add Event Hub / Storage sinks to diagnostic settings if your org mandates them.
- Expose additional outputs (e.g., frontend config ID) as needed.
- Wrap with **Terragrunt** for multi-env promotion, or integrate into **Azure DevOps/GitHub Actions**.

---

## 🔄 Versioning & Provider Notes

- Tested with Terraform **1.5+** and AzureRM **~> 3.116**.
- For provider changes, pin versions in `versions.tf` and update accordingly.

---

## 📝 License

Add your preferred license here (e.g., MIT, Apache-2.0).

---

## 🙋 Support

If you hit a policy deny or need an EPAC exemption snippet, open an issue (or ask me here) with the **error text** and I’ll guide you to a compliant fix.

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
  - `enable_diagnostics` *(bool, default: true)*
  - `log_analytics_workspace_id` *(string, required if diagnostics enabled)*
  - `diagnostic_categories` *(list(string), optional)*

---

## 📤 Outputs

- `lb_id` – ID of the load balancer
- `lb_frontend_ip_configuration_name` – Name of the frontend config
- `backend_address_pool_id` – Backend pool ID (attach NICs/VMSS)
- `public_ip_id` – ID of created public IP (if any)
- `private_frontend_ip` – The static private IP (internal LB)

---

## 🛡️ ALZ/Policy Compliance Hints

- **Standard SKUs only**: This module enforces Standard LB/PIP (Basic is commonly denied in ALZ).
- **Public IP governance**: Public IPs may be **denied in spokes**; place public ingress in **hub** or use **App Gateway/Front Door** patterns.
- **Diagnostics**: Many policies require **diagnostic settings** on network resources; set `enable_diagnostics = true` and provide a workspace.
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

# ============================================================================
# AZURE LANDING ZONE COMPLIANT LOAD BALANCER - MAIN CONFIGURATION
# ============================================================================
# This main.tf is designed to work with terraform.tfvars.alz-compliant.example
# All ALZ best practices and policies are enforced through variable defaults
# and module configuration.
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ============================================================================
# DATA SOURCES - Lookup Existing Infrastructure
# ============================================================================

# Lookup existing resource group for the load balancer
data "azurerm_resource_group" "app_rg" {
  name = var.rg_name
}

# Lookup existing virtual network (typically in connectivity subscription)
data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.vnet_rg_name
}

# Lookup existing subnet within the VNet
data "azurerm_subnet" "app" {
  name                 = var.subnet_name
  resource_group_name  = var.vnet_rg_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

# ============================================================================
# ALZ-COMPLIANT INTERNAL LOAD BALANCER
# ============================================================================

module "internal_lb" {
  source              = "../modules/alz-load-balancer"
  name                = var.lb_name
  location            = data.azurerm_resource_group.app_rg.location
  resource_group_name = data.azurerm_resource_group.app_rg.name

  # ALZ Best Practice: Internal LB for spoke workloads (keeps traffic private)
  type      = "internal"
  subnet_id = data.azurerm_subnet.app.id

  # ALZ Best Practice: Static private IP for predictable networking
  frontend_private_ip_allocation = var.frontend_private_ip_allocation
  frontend_private_ip_address    = var.frontend_private_ip_address

  # Backend pool configuration
  backend_pool_name = var.backend_pool_name

  # Health probes - configure based on your application
  probes = var.probes

  # Load balancing rules - distribute traffic to backend pool
  lb_rules = var.lb_rules

  # ALZ Best Practice: No outbound rules (use NAT Gateway or Firewall)
  enable_outbound_rule = var.enable_outbound_rule

  # ALZ Best Practice: Enable diagnostics for production workloads
  enable_diagnostics         = var.enable_diagnostics
  log_analytics_workspace_id = var.log_analytics_workspace_id
  diagnostic_categories      = var.diagnostic_categories

  # ALZ Governance: Mandatory resource tags
  tags = var.tags
}

# ============================================================================
# OUTPUTS - Information about deployed resources
# ============================================================================

output "load_balancer_id" {
  description = "Resource ID of the load balancer"
  value       = module.internal_lb.lb_id
}

output "frontend_ip_address" {
  description = "Private IP address of the load balancer frontend"
  value       = module.internal_lb.private_frontend_ip
}

output "backend_pool_id" {
  description = "Backend address pool ID (use this to attach VMs)"
  value       = module.internal_lb.backend_address_pool_id
}

output "frontend_ip_configuration_name" {
  description = "Frontend IP configuration name"
  value       = module.internal_lb.lb_frontend_ip_configuration_name
}

output "subnet_id" {
  description = "Subnet ID where the load balancer is deployed"
  value       = data.azurerm_subnet.app.id
}

# ============================================================================
# ALZ COMPLIANCE NOTES
# ============================================================================
#
# This configuration enforces Azure Landing Zone compliance through:
#
# ✅ Standard SKU Load Balancer (enforced by module)
# ✅ Internal Load Balancer (private traffic only)
# ✅ Static Private IP (predictable networking)
# ✅ No Outbound Rules (use NAT Gateway/Firewall instead)
# ✅ Diagnostics enabled (for production workloads)
# ✅ Resource tags applied (governance and cost tracking)
# ✅ Deployed to spoke VNet (network segmentation)
# ✅ Existing infrastructure lookup (no new VNets created)
#
# NEXT STEPS AFTER DEPLOYMENT:
#
# 1. Attach backend resources:
#    - Add VM NICs to backend pool using: module.internal_lb.backend_address_pool_id
#    - Or use backend_address_pool_addresses to add by IP
#
# 2. Verify connectivity:
#    - Test health probes are passing
#    - Verify traffic flows through the LB
#    - Check NSG rules allow required traffic
#
# 3. Configure DNS (if needed):
#    - Create A record pointing to the frontend IP
#    - Update application connection strings
#
# 4. Enable monitoring:
#    - Set enable_diagnostics = true in tfvars
#    - Provide log_analytics_workspace_id
#    - Set up alerts for backend pool health
#
# ============================================================================

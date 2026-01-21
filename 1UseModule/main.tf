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


module "internal_lb" {
  source              = "../modules/alz-load-balancer"
  name                = var.lb_name
  location            = data.azurerm_resource_group.app_rg.location
  resource_group_name = data.azurerm_resource_group.app_rg.name

  type                = "internal"
  subnet_id           = data.azurerm_subnet.app.id

  frontend_private_ip_allocation = var.frontend_private_ip_allocation
  frontend_private_ip_address    = var.frontend_private_ip_address

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
      disable_outbound_snat = true
    }
  ]

  enable_diagnostics         = false
  #log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id

  tags = var.tags
}

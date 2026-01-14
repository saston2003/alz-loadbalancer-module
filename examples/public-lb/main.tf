
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

module "public_lb" {
  source = "../../modules/alz-load-balancer"

  name                = "ingress-plb-prod"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  deployment_scope    = "hub"

  type             = "public"
  create_public_ip = true
  # public_ip_zones = ["1","2","3"]

  probes = [
    { name = "tcp-443", protocol = "Tcp", port = 443 }
  ]

  lb_rules = [
    {
      name            = "https-443"
      protocol        = "Tcp"
      frontend_port   = 443
      backend_port    = 443
      probe_name      = "tcp-443"
    }
  ]

  enable_outbound_rule         = false
  enable_diagnostics           = true
  log_analytics_workspace_id   = var.log_analytics_workspace_id

  tags = var.tags
}

output "public_ip_id" {
  value = module.public_lb.public_ip_id
}


resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "app" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.3.0/24"]
}

resource "azurerm_public_ip" "nat_pip" {
  name                = "natgw-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                = "natgw-spoke"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_nat" {
  subnet_id      = azurerm_subnet.app.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

module "internal_lb" {
  source = "../../modules/alz-load-balancer"

  name                = "app-ilb-prod"
  location            = var.location
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
      disable_outbound_snat = true
    }
  ]

  enable_outbound_rule         = false
  enable_diagnostics           = true
  log_analytics_workspace_id   = var.log_analytics_workspace_id

  tags = var.tags
}

output "lb_backend_pool_id" {
  value = module.internal_lb.backend_address_pool_id
}

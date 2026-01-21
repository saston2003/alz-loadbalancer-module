
data "azurerm_resource_group" "app_rg" {
  name = var.rg_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.app_rg.name
}

data "azurerm_subnet" "app" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.app_rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}



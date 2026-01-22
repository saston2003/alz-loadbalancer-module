# Add to your 2UseAlzModule/main.tf or create backend-vms.tf
#This is optional 

data "azurerm_network_interface" "skynet01" {
  name                = "Skynet01-nic"
  resource_group_name = "Skynet-VMs-RG"
}

resource "azurerm_network_interface_backend_address_pool_association" "skynet01" {
  network_interface_id    = data.azurerm_network_interface.skynet01.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = module.internal_lb.backend_address_pool_id
}

data "azurerm_network_interface" "skynet02" {
  name                = "Skynet02-nic"
  resource_group_name = "Skynet-VMs-RG"
}

resource "azurerm_network_interface_backend_address_pool_association" "skynet02" {
  network_interface_id    = data.azurerm_network_interface.skynet02.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = module.internal_lb.backend_address_pool_id
}
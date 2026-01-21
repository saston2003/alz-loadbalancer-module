output "vm_names" {
  description = "Names of the virtual machines"
  value       = [for vm in azurerm_windows_virtual_machine.vm : vm.name]
}

output "vm_private_ips" {
  description = "Private IP addresses of the VMs"
  value       = [for nic in azurerm_network_interface.vm_nic : nic.private_ip_address]
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = azurerm_network_security_group.main.name
}

output "vnet_info" {
  description = "Information about the connected VNet"
  value = {
    name                = data.azurerm_virtual_network.existing.name
    resource_group_name = data.azurerm_virtual_network.existing.resource_group_name
    address_space       = data.azurerm_virtual_network.existing.address_space
  }
}

# Outputs for easy access to VM information

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_names" {
  description = "Names of all subnets"
  value       = [for subnet in azurerm_subnet.subnets : subnet.name]
}

output "vm_names" {
  description = "Names of the virtual machines"
  value       = [for vm in azurerm_windows_virtual_machine.vm : vm.name]
}

output "vm_private_ips" {
  description = "Private IP addresses of the VMs"
  value       = [for nic in azurerm_network_interface.vm_nic : nic.private_ip_address]
}

output "vm_public_ips" {
  description = "Public IP addresses of the VMs"
  value       = [for pip in azurerm_public_ip.vm_public_ip : pip.ip_address]
}

output "rdp_connection_strings" {
  description = "RDP connection strings for the VMs"
  value = [
    for i, pip in azurerm_public_ip.vm_public_ip : 
    "mstsc /v:${pip.ip_address} /admin (Username: ${var.admin_username})"
  ]
}

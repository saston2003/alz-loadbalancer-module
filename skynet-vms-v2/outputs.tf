output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "nsg_name" {
  description = "Name of the Network Security Group"
  value       = azurerm_network_security_group.main.name
}

output "vm_names" {
  description = "Names of the virtual machines"
  value       = [for vm in azurerm_windows_virtual_machine.vm : vm.name]
}

output "vm_private_ips" {
  description = "Private IP addresses of the VMs"
  value = {
    for idx, nic in azurerm_network_interface.vm_nic : 
    "Skynet${format("%02d", idx + 1)}" => nic.private_ip_address
  }
}

output "vnet_name" {
  description = "Name of the existing VNet"
  value       = data.azurerm_virtual_network.existing.name
}

output "subnet_name" {
  description = "Name of the existing subnet"
  value       = data.azurerm_subnet.existing.name
}

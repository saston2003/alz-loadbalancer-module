# ============================================================================
# OUTPUTS
# ============================================================================

output "load_balancer_id" {
  description = "ID of the created load balancer"
  value       = module.internal_lb.lb_id
}

output "backend_pool_id" {
  description = "ID of the backend address pool"
  value       = module.internal_lb.backend_address_pool_id
}

output "frontend_ip_address" {
  description = "Frontend IP address of the load balancer"
  value       = module.internal_lb.private_frontend_ip
}

output "frontend_ip_configuration_name" {
  description = "Name of the frontend IP configuration"
  value       = module.internal_lb.lb_frontend_ip_configuration_name
}

output "subnet_id" {
  description = "Subnet ID where the load balancer and VMs are deployed"
  value       = data.azurerm_subnet.app.id
}

output "vm_ids" {
  description = "IDs of the created VMs"
  value = {
    skynet01 = azurerm_windows_virtual_machine.skynet01.id
    skynet02 = azurerm_windows_virtual_machine.skynet02.id
  }
}

output "vm_private_ips" {
  description = "Private IP addresses of the VMs"
  value = {
    skynet01 = azurerm_network_interface.skynet01_nic.private_ip_address
    skynet02 = azurerm_network_interface.skynet02_nic.private_ip_address
  }
}

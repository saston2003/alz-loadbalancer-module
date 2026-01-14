
output "lb_id" {
  value = azurerm_lb.this.id
}

output "lb_frontend_ip_configuration_name" {
  value = local.fe_config_name
}

output "backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.this.id
}

output "public_ip_id" {
  value       = try(azurerm_public_ip.this[0].id, null)
  description = "ID of the created Public IP (if created)."
}

output "private_frontend_ip" {
  value       = try(azurerm_lb.this.frontend_ip_configuration[0].private_ip_address, null)
  description = "Private frontend IP (internal LBs with Static allocation)."
}

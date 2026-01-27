# ============================================================================
# AZURE LOAD BALANCER WITH VMs - OPTION B (SAME RESOURCE GROUP)
# ============================================================================
# This configuration:
# 1. Creates an internal load balancer
# 2. Creates VMs in the SAME resource group as the load balancer
# 3. Automatically associates VMs with the backend pool
# 4. Installs IIS on the VMs for testing
# ============================================================================

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

# ============================================================================
# DATA SOURCES - Lookup Existing Infrastructure
# ============================================================================

# Lookup existing resource group for the load balancer and VMs
data "azurerm_resource_group" "app_rg" {
  name = var.rg_name
}

# Lookup existing virtual network
data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.vnet_rg_name
}

# Lookup existing subnet within the VNet
data "azurerm_subnet" "app" {
  name                 = var.subnet_name
  resource_group_name  = var.vnet_rg_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

# ============================================================================
# INTERNAL LOAD BALANCER
# ============================================================================

module "internal_lb" {
  source              = "../modules/alz-load-balancer"
  name                = var.lb_name
  location            = data.azurerm_resource_group.app_rg.location
  resource_group_name = data.azurerm_resource_group.app_rg.name

  type      = "internal"
  subnet_id = data.azurerm_subnet.app.id

  frontend_private_ip_allocation = var.frontend_private_ip_allocation
  frontend_private_ip_address    = var.frontend_private_ip_address

  backend_pool_name = var.backend_pool_name

  probes   = var.probes
  lb_rules = var.lb_rules

  enable_outbound_rule = var.enable_outbound_rule

  enable_diagnostics         = var.enable_diagnostics
  log_analytics_workspace_id = var.log_analytics_workspace_id
  diagnostic_categories      = var.diagnostic_categories

  tags = var.tags
}

# ============================================================================
# VM 1: Skynet01
# ============================================================================

resource "azurerm_network_interface" "skynet01_nic" {
  name                = "Skynet01-nic"
  location            = data.azurerm_resource_group.app_rg.location
  resource_group_name = data.azurerm_resource_group.app_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_network_interface_backend_address_pool_association" "skynet01" {
  network_interface_id    = azurerm_network_interface.skynet01_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = module.internal_lb.backend_address_pool_id
}

resource "azurerm_windows_virtual_machine" "skynet01" {
  name                = "Skynet01"
  location            = data.azurerm_resource_group.app_rg.location
  resource_group_name = data.azurerm_resource_group.app_rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.skynet01_nic.id
  ]

  os_disk {
    name                 = "Skynet01-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = var.tags
}

# Install IIS on Skynet01
resource "azurerm_virtual_machine_extension" "iis_skynet01" {
  name                 = "install-iis"
  virtual_machine_id   = azurerm_windows_virtual_machine.skynet01.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools; New-NetFirewallRule -DisplayName 'Allow HTTP' -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow; New-NetFirewallRule -DisplayName 'Allow HTTPS' -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow; Set-Content -Path 'C:\\inetpub\\wwwroot\\index.html' -Value '<html><body><h1>Skynet01</h1><p>Load Balancer Test Server</p></body></html>'\""
    }
SETTINGS

  tags = var.tags
}

# ============================================================================
# VM 2: Skynet02
# ============================================================================

resource "azurerm_network_interface" "skynet02_nic" {
  name                = "Skynet02-nic"
  location            = data.azurerm_resource_group.app_rg.location
  resource_group_name = data.azurerm_resource_group.app_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_network_interface_backend_address_pool_association" "skynet02" {
  network_interface_id    = azurerm_network_interface.skynet02_nic.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = module.internal_lb.backend_address_pool_id
}

resource "azurerm_windows_virtual_machine" "skynet02" {
  name                = "Skynet02"
  location            = data.azurerm_resource_group.app_rg.location
  resource_group_name = data.azurerm_resource_group.app_rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.skynet02_nic.id
  ]

  os_disk {
    name                 = "Skynet02-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = var.tags
}

# Install IIS on Skynet02
resource "azurerm_virtual_machine_extension" "iis_skynet02" {
  name                 = "install-iis"
  virtual_machine_id   = azurerm_windows_virtual_machine.skynet02.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server -IncludeManagementTools; New-NetFirewallRule -DisplayName 'Allow HTTP' -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow; New-NetFirewallRule -DisplayName 'Allow HTTPS' -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow; Set-Content -Path 'C:\\inetpub\\wwwroot\\index.html' -Value '<html><body><h1>Skynet02</h1><p>Load Balancer Test Server</p></body></html>'\""
    }
SETTINGS

  tags = var.tags
}

# Data source for existing VNet
data "azurerm_virtual_network" "existing" {
  name                = "SDSvNetTest-vnet"
  resource_group_name = "m-spokeconfig-rg"
}

# Data source for existing subnet (subnet2)
data "azurerm_subnet" "existing" {
  name                 = "subnet2"
  resource_group_name  = data.azurerm_virtual_network.existing.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.existing.name
}

# Resource Group for VMs
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Network Security Group - ALZ Policy Compliant
resource "azurerm_network_security_group" "main" {
  name                = "skynet-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # Deny RDP from Internet (ALZ Policy requirement)
  security_rule {
    name                       = "DenyRDPFromInternet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Deny SSH from Internet (ALZ Policy requirement)
  security_rule {
    name                       = "DenySSHFromInternet"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Allow RDP from VirtualNetwork
  security_rule {
    name                       = "AllowRDPFromVNet"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# Network Interfaces - No Public IPs (internal only)
resource "azurerm_network_interface" "vm_nic" {
  count               = 2
  name                = "Skynet${format("%02d", count.index + 1)}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.existing.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NICs
resource "azurerm_network_interface_security_group_association" "main" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.vm_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Windows Virtual Machines
resource "azurerm_windows_virtual_machine" "vm" {
  count               = 2
  name                = "Skynet${format("%02d", count.index + 1)}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.vm_nic[count.index].id,
  ]

  os_disk {
    name                 = "Skynet${format("%02d", count.index + 1)}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {}
}

# Managed Data Disks
resource "azurerm_managed_disk" "data_disk" {
  count                = 2
  name                 = "Skynet${format("%02d", count.index + 1)}-datadisk"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = var.data_disk_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = var.tags
}

# Attach Data Disks to VMs
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attach" {
  count              = 2
  managed_disk_id    = azurerm_managed_disk.data_disk[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm[count.index].id
  lun                = 0
  caching            = "ReadWrite"
}

# Auto-shutdown schedule for VMs (6pm daily)
resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm_shutdown" {
  count              = 2
  virtual_machine_id = azurerm_windows_virtual_machine.vm[count.index].id
  location           = azurerm_resource_group.main.location
  enabled            = true

  daily_recurrence_time = "1800"
  timezone              = "GMT Standard Time"

  notification_settings {
    enabled = false
  }
}

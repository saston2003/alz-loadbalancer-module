# Resource Group
resource "azurerm_resource_group" "DevBoxRG" {
  name     = var.resource_group_name
  location = var.location
}

# Storage Account
resource "azurerm_storage_account" "example" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.DevBoxRG.name
  location                 = azurerm_resource_group.DevBoxRG.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  tags = var.tags
}

# Storage Container 1
resource "azurerm_storage_container" "example" {
  name                  = var.container1_name
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = var.container_access_type
}

# Storage Container 2
resource "azurerm_storage_container" "example2" {
  name                  = var.container2_name
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = var.container_access_type
}

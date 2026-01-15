terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = "DevBoxBackend-RG"
      storage_account_name = "devboxbackend"
      container_name       = "tfstate"
      key                  = "devbox.tfstate"
  }
#key does not mean the storage account key!! it means the name of the state file
#The key value in the config file replaces the key value in the backend block if both are present.
}

provider "azurerm" {
  features {}
}

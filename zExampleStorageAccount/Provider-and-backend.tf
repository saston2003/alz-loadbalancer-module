terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  # backend "azurerm" {
  #     resource_group_name  = "rg-alz-storage-prod-uksouth-001"
  #     storage_account_name = "sdstesttalz001"
  #     container_name       = "tfstate"
  #     key                  = "devbox.tfstate"
  #     use_azuread_auth     = true
  # }
#key does not mean the storage account key!! it means the name of the state file
#The key value in the config file replaces the key value in the backend block if both are present.
}

provider "azurerm" {
  features {}
}

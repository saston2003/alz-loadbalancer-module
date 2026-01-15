terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "DevBoxBackend-RG"
    storage_account_name = "devboxbackend"
    container_name       = "tfstate"
    key                  = "azurevm.tfstate"
  }
}

provider "azurerm" {
  features {}
}

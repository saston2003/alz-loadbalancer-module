variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "DevBoxExampleEnt-RG"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "North Europe"
}

variable "storage_account_name" {
  description = "The name of the storage account (must be globally unique)"
  type        = string
  default     = "svjaz400sacc2000ent2"
}

variable "account_tier" {
  description = "The performance tier of the storage account"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "The replication type of the storage account"
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    environment = "DevBox"
    purpose     = "Example Storage Account with Options"
  }
}

variable "container1_name" {
  description = "The name of the first storage container"
  type        = string
  default     = "container1"
}

variable "container2_name" {
  description = "The name of the second storage container"
  type        = string
  default     = "container2"
}

variable "container_access_type" {
  description = "The access type of the storage containers"
  type        = string
  default     = "private"
}
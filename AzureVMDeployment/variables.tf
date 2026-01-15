variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "AzureVM-RG"
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "northeurope"
}

variable "vnet_name" {
  description = "The name of the virtual network"
  type        = string
  default     = "vm-vnet"
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  description = "Address prefixes for the 6 subnets"
  type        = list(string)
  default     = [
    "10.0.1.0/24",  # subnet-1
    "10.0.2.0/24",  # subnet-2
    "10.0.3.0/24",  # subnet-3
    "10.0.4.0/24",  # subnet-4
    "10.0.5.0/24",  # subnet-5
    "10.0.6.0/24"   # subnet-6
  ]
}

variable "subnet_names" {
  description = "Names for the 6 subnets"
  type        = list(string)
  default     = [
    "subnet-1",
    "subnet-2",
    "subnet-3",
    "subnet-4",
    "subnet-5",
    "subnet-6"
  ]
}

variable "vm_size" {
  description = "The size of the virtual machines"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "manage"
}

variable "admin_password" {
  description = "Admin password for the VMs"
  type        = string
  sensitive   = true
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 2
}

variable "os_disk_type" {
  description = "The type of OS disk (Standard_LRS, StandardSSD_LRS, Premium_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "data_disk_size_gb" {
  description = "Size of the data disk in GB"
  type        = number
  default     = 128
}

variable "data_disk_type" {
  description = "The type of data disk (Standard_LRS, StandardSSD_LRS, Premium_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    environment = "production"
    managedby   = "terraform"
  }
}

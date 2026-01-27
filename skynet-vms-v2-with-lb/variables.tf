variable "resource_group_name" {
  description = "Name of the resource group for the VMs"
  type        = string
  default     = "Skynet-VMs-RG"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "uksouth"
}

variable "vm_size" {
  description = "Size of the virtual machines"
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

variable "os_disk_type" {
  description = "OS disk storage account type"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "data_disk_type" {
  description = "Data disk storage account type"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "data_disk_size_gb" {
  description = "Size of the data disk in GB"
  type        = number
  default     = 128
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Skynet VMs"
  }
}

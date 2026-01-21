
variable "rg_name"      { type = string }
variable "vnet_name"    { type = string }
variable "subnet_name"  { type = string }
# variable "law_name"     { type = string }
# variable "law_rg_name"  { type = string }
variable "location"     { type = string }

variable "lb_name" {
  description = "Name of the load balancer"
  type        = string
  default     = "app-ilb-prod"
}

variable "frontend_private_ip_allocation" {
  description = "Private IP allocation method for the load balancer frontend"
  type        = string
  default     = "Static"
}

variable "frontend_private_ip_address" {
  description = "Static private IP address for the load balancer frontend"
  type        = string
  default     = "10.20.3.10"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

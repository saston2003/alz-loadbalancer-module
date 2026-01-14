
variable "location" {
  type    = string
  default = "uksouth"
}

variable "rg_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

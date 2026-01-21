
variable "name" {
  description = "Base name for the Load Balancer (used across child resources)."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "deployment_scope" {
  description = "Landing zone scope hint for documentation or conditional logic (hub|spoke|sandbox)."
  type        = string
  default     = "spoke"
  validation {
    condition     = contains(["hub", "spoke", "sandbox"], var.deployment_scope)
    error_message = "deployment_scope must be 'hub', 'spoke', or 'sandbox'."
  }
}

variable "type" {
  description = "Load balancer type: internal or public."
  type        = string
  default     = "internal"
  validation {
    condition     = contains(["internal", "public"], var.type)
    error_message = "type must be 'internal' or 'public'."
  }
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# ---------- Internal LB (frontend private IP) ----------
variable "subnet_id" {
  description = "Required for internal LBs: Subnet ID for the frontend private IP."
  type        = string
  default     = null
}

variable "frontend_private_ip_allocation" {
  description = "Private IP allocation for internal LB frontend."
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.frontend_private_ip_allocation)
    error_message = "frontend_private_ip_allocation must be Static or Dynamic."
  }
}

variable "frontend_private_ip_address" {
  description = "Optional static private IP for internal LB (if Static)."
  type        = string
  default     = null
}

# ---------- Public LB (optional PIP) ----------
variable "create_public_ip" {
  description = "If true and type == public, create a Standard Public IP."
  type        = bool
  default     = false
}

variable "public_ip_id" {
  description = "Existing Public IP ID for public LB (if not creating one)."
  type        = string
  default     = null
}

variable "public_ip_sku" {
  description = "Public IP SKU (Standard only in enterprise)."
  type        = string
  default     = "Standard"
  validation {
    condition     = var.public_ip_sku == "Standard"
    error_message = "Only Standard SKU is allowed for Public IP."
  }
}

variable "public_ip_allocation_method" {
  description = "Public IP allocation method (Static for Standard)."
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static"], var.public_ip_allocation_method)
    error_message = "Public IP must be Static for Standard SKU."
  }
}

variable "public_ip_sku_tier" {
  description = "Public IP SKU Tier (Regional or Global)."
  type        = string
  default     = "Regional"
  validation {
    condition     = contains(["Regional", "Global"], var.public_ip_sku_tier)
    error_message = "public_ip_sku_tier must be Regional or Global."
  }
}

variable "public_ip_zones" {
  description = "List of zones for the Public IP (e.g., [\"1\",\"2\",\"3\"]). Null => no zones."
  type        = list(string)
  default     = null
}

# ---------- Backend & rules ----------
variable "backend_pool_name" {
  description = "Name for the backend address pool."
  type        = string
  default     = "beap"
}

variable "probes" {
  description = <<EOT
List of health probes to create.
Each object: {
  name        = string
  protocol    = string  # Tcp | Http | Https
  port        = number
  request_path= optional(string)
  interval    = optional(number)
  unhealthy_threshold = optional(number)
}
EOT
  type = list(object({
    name                = string
    protocol            = string
    port                = number
    request_path        = optional(string)
    interval            = optional(number)
    unhealthy_threshold = optional(number)
  }))
  default = []
}

variable "lb_rules" {
  description = <<EOT
List of load balancing rules.
Each object: {
  name                    = string
  protocol                = string     # Tcp | Udp | All
  frontend_port           = number
  backend_port            = number
  probe_name              = optional(string)
  idle_timeout_in_minutes = optional(number)
  enable_floating_ip      = optional(bool)
  disable_outbound_snat   = optional(bool)
}
EOT
  type = list(object({
    name                    = string
    protocol                = string
    frontend_port           = number
    backend_port            = number
    probe_name              = optional(string)
    idle_timeout_in_minutes = optional(number)
    enable_floating_ip      = optional(bool)
    disable_outbound_snat   = optional(bool)
  }))
  default = []
}

variable "enable_outbound_rule" {
  description = "Create an LB outbound rule for SNAT (avoid if using NAT Gateway)."
  type        = bool
  default     = false
}

variable "outbound_protocol" {
  description = "Outbound rule protocol if enabled."
  type        = string
  default     = "Tcp"
  validation {
    condition     = contains(["Tcp", "Udp", "All"], var.outbound_protocol)
    error_message = "outbound_protocol must be Tcp, Udp, or All."
  }
}

variable "allocated_outbound_ports" {
  description = "SNAT ports per VM (for outbound rule)."
  type        = number
  default     = 1024
}

# ---------- Diagnostics ----------
variable "enable_diagnostics" {
  description = "Enable diagnostic settings."
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID (required if diagnostics enabled)."
  type        = string
  default     = null
}

variable "diagnostic_categories" {
  description = "Override diagnostic categories; null enables all available."
  type        = list(string)
  default     = null
}

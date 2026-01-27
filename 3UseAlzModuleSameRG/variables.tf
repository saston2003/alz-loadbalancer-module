# ============================================================================
# VARIABLES - ALZ-Compliant Load Balancer Configuration
# ============================================================================
# These variables work with terraform.tfvars.alz-compliant.example
# Defaults are set to ALZ best practices where applicable
# ============================================================================

# ----------------------------------------------------------------------------
# REQUIRED VARIABLES - Must be provided in tfvars
# ----------------------------------------------------------------------------

variable "rg_name" {
  description = "Resource group name where the load balancer will be deployed"
  type        = string
}

variable "vnet_rg_name" {
  description = "Resource group name where the VNet exists (may be in connectivity subscription)"
  type        = string
}

variable "vnet_name" {
  description = "Name of the existing virtual network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the existing subnet within the VNet"
  type        = string
}

variable "location" {
  description = "Azure region for the load balancer deployment"
  type        = string
}

# ----------------------------------------------------------------------------
# LOAD BALANCER CONFIGURATION
# ----------------------------------------------------------------------------

variable "lb_name" {
  description = "Name of the load balancer"
  type        = string
}

# ----------------------------------------------------------------------------
# FRONTEND IP CONFIGURATION (Internal LB)
# ----------------------------------------------------------------------------

variable "frontend_private_ip_allocation" {
  description = "Private IP allocation method (ALZ Best Practice: Static)"
  type        = string
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.frontend_private_ip_allocation)
    error_message = "frontend_private_ip_allocation must be Static or Dynamic."
  }
}

variable "frontend_private_ip_address" {
  description = "Static private IP address for the load balancer frontend (must be within subnet range)"
  type        = string
}

# ----------------------------------------------------------------------------
# BACKEND POOL
# ----------------------------------------------------------------------------

variable "backend_pool_name" {
  description = "Name for the backend address pool"
  type        = string
  default     = "backend-pool"
}

# ----------------------------------------------------------------------------
# HEALTH PROBES
# ----------------------------------------------------------------------------

variable "probes" {
  description = <<-EOT
    List of health probes to monitor backend resource health.
    Configure based on your application requirements.
  EOT
  type = list(object({
    name                = string
    protocol            = string  # Tcp, Http, or Https
    port                = number
    request_path        = optional(string)  # Required for Http/Https
    interval            = optional(number)
    unhealthy_threshold = optional(number)
  }))
}

# ----------------------------------------------------------------------------
# LOAD BALANCING RULES
# ----------------------------------------------------------------------------

variable "lb_rules" {
  description = <<-EOT
    List of load balancing rules to distribute traffic.
    ALZ Best Practice: Set disable_outbound_snat = true (use NAT Gateway instead)
  EOT
  type = list(object({
    name                    = string
    protocol                = string  # Tcp, Udp, or All
    frontend_port           = number
    backend_port            = number
    probe_name              = optional(string)
    idle_timeout_in_minutes = optional(number)
    enable_floating_ip      = optional(bool)
    disable_outbound_snat   = optional(bool)
  }))
}

# ----------------------------------------------------------------------------
# OUTBOUND CONNECTIVITY
# ----------------------------------------------------------------------------

variable "enable_outbound_rule" {
  description = "Enable outbound rule (ALZ Best Practice: false - use NAT Gateway or Firewall)"
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------
# DIAGNOSTICS & MONITORING
# ----------------------------------------------------------------------------

variable "enable_diagnostics" {
  description = "Enable diagnostic settings (ALZ Best Practice: true for production)"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostics (required if enable_diagnostics = true)"
  type        = string
  default     = null
}

variable "diagnostic_categories" {
  description = "Diagnostic categories to enable (null = all available)"
  type        = list(string)
  default     = null
}

# ----------------------------------------------------------------------------
# RESOURCE TAGS (ALZ Governance)
# ----------------------------------------------------------------------------

variable "tags" {
  description = <<-EOT
    Tags to apply to all resources.
    ALZ Best Practice: Include owner, env, costCenter, service tags for governance.
  EOT
  type        = map(string)
  default     = {}
}

# ----------------------------------------------------------------------------
# VM VARIABLES
# ----------------------------------------------------------------------------

variable "vm_size" {
  description = "Size of the virtual machines"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VMs"
  type        = string
  sensitive   = true
}

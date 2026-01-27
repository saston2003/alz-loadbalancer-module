
locals {
  lb_name        = var.name
  beap_name      = var.backend_pool_name
  fe_config_name = "${var.name}-fe"
  pip_name       = "${var.name}-pip"
  diag_name      = "${var.name}-diag"
  pip_diag_name  = "${var.name}-pip-diag"
  is_public      = var.type == "public"
  is_internal    = var.type == "internal"
}

# Optional Public IP (Standard only); typically allowed in hub
resource "azurerm_public_ip" "this" {
  count               = local.is_public && var.create_public_ip && var.public_ip_id == null ? 1 : 0
  name                = local.pip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  sku_tier            = var.public_ip_sku_tier
  zones               = var.public_ip_zones
  tags                = var.tags
}

# Load Balancer (Standard)
resource "azurerm_lb" "this" {
  name                = local.lb_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name = local.fe_config_name

    # internal
    subnet_id                     = local.is_internal ? var.subnet_id : null
    private_ip_address_allocation = local.is_internal ? var.frontend_private_ip_allocation : null
    private_ip_address            = local.is_internal && var.frontend_private_ip_allocation == "Static" && var.frontend_private_ip_address != null ? var.frontend_private_ip_address : null

    # public
    public_ip_address_id = local.is_public ? coalesce(var.public_ip_id, try(azurerm_public_ip.this[0].id, null)) : null
  }
}

# Backend pool
resource "azurerm_lb_backend_address_pool" "this" {
  name            = local.beap_name
  loadbalancer_id = azurerm_lb.this.id
}

# Probes (optional list)
resource "azurerm_lb_probe" "this" {
  for_each        = { for p in var.probes : p.name => p }
  name            = each.value.name
  loadbalancer_id = azurerm_lb.this.id
  protocol        = each.value.protocol
  port            = each.value.port
  request_path    = try(each.value.request_path, null)
  interval_in_seconds = try(each.value.interval, 5)
  number_of_probes    = try(each.value.unhealthy_threshold, 2)
}

# LB Rules (optional list)
resource "azurerm_lb_rule" "this" {
  for_each                       = { for r in var.lb_rules : r.name => r }
  name                           = each.value.name
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = local.fe_config_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = try(azurerm_lb_probe.this[each.value.probe_name].id, null)
  idle_timeout_in_minutes        = try(each.value.idle_timeout_in_minutes, 4)
  enable_floating_ip             = try(each.value.enable_floating_ip, false)
  disable_outbound_snat          = try(each.value.disable_outbound_snat, false)
  load_distribution              = try(each.value.load_distribution, "Default")
}

# Optional outbound rule (avoid when using NAT Gateway)
resource "azurerm_lb_outbound_rule" "this" {
  count                    = var.enable_outbound_rule ? 1 : 0
  name                     = "${var.name}-outbound"
  loadbalancer_id          = azurerm_lb.this.id
  protocol                 = var.outbound_protocol
  backend_address_pool_id  = azurerm_lb_backend_address_pool.this.id
  allocated_outbound_ports = var.allocated_outbound_ports

  frontend_ip_configuration {
    name = local.fe_config_name
  }
}

# Diagnostics for LB
data "azurerm_monitor_diagnostic_categories" "lb" {
  resource_id = azurerm_lb.this.id
}

resource "azurerm_monitor_diagnostic_setting" "lb" {
  count                      = var.enable_diagnostics ? 1 : 0
  name                       = local.diag_name
  target_resource_id         = azurerm_lb.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.diagnostic_categories != null ? toset(var.diagnostic_categories) : toset(data.azurerm_monitor_diagnostic_categories.lb.log_category_types)
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(data.azurerm_monitor_diagnostic_categories.lb.metrics)
    content {
      category = metric.value
      enabled  = true
    }
  }

  lifecycle {
    precondition {
      condition     = var.enable_diagnostics == false || (var.enable_diagnostics && var.log_analytics_workspace_id != null)
      error_message = "Diagnostics are enabled but log_analytics_workspace_id was not provided."
    }
  }
}

# Diagnostics for PIP (if created in this module)
data "azurerm_monitor_diagnostic_categories" "pip" {
  count       = length(azurerm_public_ip.this) > 0 ? 1 : 0
  resource_id = azurerm_public_ip.this[0].id
}

resource "azurerm_monitor_diagnostic_setting" "pip" {
  count                      = (var.enable_diagnostics && length(azurerm_public_ip.this) > 0) ? 1 : 0
  name                       = local.pip_diag_name
  target_resource_id         = azurerm_public_ip.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.pip[0].log_category_types, []))
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = toset(try(data.azurerm_monitor_diagnostic_categories.pip[0].metrics, []))
    content {
      category = metric.value
      enabled  = true
    }
  }
}

resource "azurerm_user_assigned_identity" "ca-uai" {
  location            = var.location
  name                = "${var.stack}-ami-ca-${var.app_name}"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "ca-ra" {
  scope                = var.acr_id
  role_definition_name = "acrpull"
  principal_id         = azurerm_user_assigned_identity.ca-uai.principal_id
  depends_on = [
    azurerm_user_assigned_identity.ca-uai
  ]
}

resource "azurerm_container_app_environment" "appenv-floto" {
  name                           = "${var.stack}-appenv-floto"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.subnet_id
  internal_load_balancer_enabled = true
  tags                           = var.tags

  lifecycle {
    ignore_changes = [
      infrastructure_resource_group_name
    ]
  }
}

resource "azurerm_container_app" "ca-floto-api" {
  name                         = "${var.stack}-ca-${var.app_name}"
  container_app_environment_id = azurerm_container_app_environment.appenv-floto.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  depends_on = [
    azurerm_role_assignment.ca-ra
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.ca-uai.id]
  }

  registry {
    server   = var.acr_login_server
    identity = azurerm_user_assigned_identity.ca-uai.id
  }

  ingress {
    external_enabled = true
    target_port      = var.target_port
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  secret {
    name  = "app-config-cxn"
    value = var.app_config_cxn_string
  }
  secret {
    name  = "app-insights-cxn"
    value = var.app_insights_cxn_string
  }
  secret {
    name = "cosmosdb-cxn"
    value = var.cosmosdb_cxn_string
  }

  template {
    container {
      name   = var.app_name
      image  = "${var.acr_login_server}/${var.app_name}:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "APPLICATIONCONFIG_CONNECTION_STRING"
        secret_name = "app-config-cxn"
      }
      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "app-insights-cxn"
      }
      env {
        name        = "COSMOSDB_CONNECTION_STRING"
        secret_name = "cosmosdb-cxn"
      }
      env {
        name  = "Stack"
        value = var.stack
      }
      env {
        name  = "CosmosDb__DatabaseId"
        value = "${var.stack}-sqldb-floto"
      }
      env {
        name  = "CosmosDb__ContainerId"
        value = "sql-cont-floto"
      }

      readiness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = var.app_health_path
      }

      liveness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = var.app_health_path
      }

      startup_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = var.app_health_path
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      workload_profile_name
    ]
  }
}

resource "azurerm_private_dns_zone" "floto-private-dns-zone-ca" {
  name                = azurerm_container_app.ca-floto-api.ingress[0].fqdn
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "floto-private-dns-zone-vnet-link-ca" {
  name                  = "${var.stack}-dnsvnet-${var.app_name}-ca"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.floto-private-dns-zone-ca.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

resource "azurerm_private_dns_a_record" "floto-private-dns-a-record-ca-wildcard" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.floto-private-dns-zone-ca.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  records             = [azurerm_container_app_environment.appenv-floto.static_ip_address]
  tags                = var.tags
}

resource "azurerm_private_dns_a_record" "floto-private-dns-a-record-ca-naked" {
  name                = "@"
  zone_name           = azurerm_private_dns_zone.floto-private-dns-zone-ca.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  records             = [azurerm_container_app_environment.appenv-floto.static_ip_address]
  tags                = var.tags
}

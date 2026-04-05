terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.19.0"
    }
  }
  backend "azurerm" {}
}

locals {
  core_rg_name = "dev01-uks-rg-core"
}


provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_container_registry" "core-acr" {
  name                = "dev01ukscore"
  resource_group_name = local.core_rg_name
}

data "azurerm_app_configuration" "appconf-floto" {
  name                = "dev01-uks-ac-floto"
  resource_group_name = local.core_rg_name
}

data "azurerm_cosmosdb_account" "cosmosdb-floto" {
  name                = "dev01-uks-cosmos-free"
  resource_group_name = local.core_rg_name
}

data "azurerm_private_dns_zone" "floto-private-dns-zone-cosmos" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = local.core_rg_name
}

resource "azurerm_resource_group" "app-rg" {
  name     = "${var.stack}-rg-floto"
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "la-floto" {
  name                = "${var.stack}-la-workspace-floto"
  location            = var.location
  resource_group_name = azurerm_resource_group.app-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appi-floto" {
  name                = "${var.stack}-appi-floto"
  location            = var.location
  resource_group_name = azurerm_resource_group.app-rg.name
  workspace_id        = azurerm_log_analytics_workspace.la-floto.id
  application_type    = "web"
}

module "network" {
  source              = "./modules/network"
  app_name            = "floto"
  location            = var.location
  resource_group_name = azurerm_resource_group.app-rg.name
  stack               = var.stack
  tags                = var.tags
}

module "container_app" {
  source                     = "./modules/container_app"
  acr_id                     = data.azurerm_container_registry.core-acr.id
  acr_login_server           = data.azurerm_container_registry.core-acr.login_server
  app_config_cxn_string      = data.azurerm_app_configuration.appconf-floto.primary_read_key[0].connection_string
  app_health_path            = "api/v1/ping"
  app_insights_cxn_string    = azurerm_application_insights.appi-floto.connection_string
  app_name                   = "floto-api"
  cosmosdb_cxn_string        = data.azurerm_cosmosdb_account.cosmosdb-floto.primary_sql_connection_string
  stack                      = var.stack
  image_tag                  = var.stack
  location                   = var.location
  resource_group_name        = azurerm_resource_group.app-rg.name
  vnet_id                    = module.network.vnet_id
  subnet_id                  = module.network.subnet_id_appenv
  log_analytics_workspace_id = azurerm_log_analytics_workspace.la-floto.id
  tags                       = var.tags
}

module "apim" {
  source                           = "./modules/apim"
  app_name                         = "floto"
  backend_suffix                   = "floto-api"
  backend_url                      = "${module.container_app.app_url}/api"
  company                          = var.company
  display_name                     = "floto-api"
  location                         = var.location
  publisher_email                  = var.company_email
  resource_group_name              = azurerm_resource_group.app-rg.name
  revision                         = 1
  stack                            = var.stack
  swagger_filepath                 = "../Floto.Api/floto-openapi.json"
  subnet_id                        = module.network.subnet_id_shared
  app_insights_id                  = azurerm_application_insights.appi-floto.id
  app_insights_instrumentation_key = azurerm_application_insights.appi-floto.instrumentation_key
  tags                             = var.tags
}

module "cosmosdb" {
  source                = "./modules/cosmosdb"
  cosmosdb_account_id   = data.azurerm_cosmosdb_account.cosmosdb-floto.id
  cosmosdb_account_name = data.azurerm_cosmosdb_account.cosmosdb-floto.name
  resource_group_name   = data.azurerm_cosmosdb_account.cosmosdb-floto.resource_group_name
  stack                 = var.stack
  location              = azurerm_resource_group.app-rg.location
  vnet_id               = module.network.vnet_id
  subnet_id             = module.network.subnet_id_p_endpoint
  dnszone_id            = data.azurerm_private_dns_zone.floto-private-dns-zone-cosmos.id
  dnszone_name          = data.azurerm_private_dns_zone.floto-private-dns-zone-cosmos.name
  tags                  = var.tags
}

module "app_configuration" {
  source                 = "./modules/app_configuration"
  configuration_store_id = data.azurerm_app_configuration.appconf-floto.id
  stack                  = var.stack
}

module "features" {
  source                 = "./modules/features"
  configuration_store_id = data.azurerm_app_configuration.appconf-floto.id
  stack                  = var.stack
  tags                   = var.tags
}

output "api_url_floto" {
  value = module.apim.apim_url
}

output "api_key_floto" {
  value = module.apim.floto_api_key_primary
}

output "health_checK" {
  value = "curl -H 'floto-sub-key: ${module.apim.floto_api_key_primary}' -w '\\n' ${module.apim.apim_url}/v1/ping"
}

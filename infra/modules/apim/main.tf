resource "azurerm_api_management" "apim-floto" {
  name                 = "${var.stack}-${var.app_name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  publisher_name       = var.company
  publisher_email      = var.publisher_email
  sku_name             = "Developer_1"
  virtual_network_type = "External"

  virtual_network_configuration {
    subnet_id = var.subnet_id
  }
}

resource "azurerm_api_management_api" "api-floto-api" {
  name                  = "${var.stack}-${var.app_name}-api"
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.apim-floto.name
  revision              = var.revision
  display_name          = var.display_name
  path                  = var.backend_suffix
  protocols             = ["https"]
  service_url           = var.backend_url
  subscription_required = true
  
  subscription_key_parameter_names {
    header = "floto-sub-key"
    query =  "floto-sub-key"
  }

  import {
    content_format = "openapi"
    content_value  = file(var.openapi_filepath)
  }
}

resource "azurerm_api_management_product" "apim-prod-floto" {
  product_id            = var.app_name
  display_name          = "Floto"
  api_management_name   = azurerm_api_management.apim-floto.name
  resource_group_name   = var.resource_group_name
  published             = true
  subscription_required = true
}

resource "azurerm_api_management_product_api" "apim-prod-api-floto" {
  api_name            = azurerm_api_management_api.api-floto-api.name
  product_id          = azurerm_api_management_product.apim-prod-floto.product_id
  api_management_name = azurerm_api_management.apim-floto.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_api_management_subscription" "apim-sub-floto" {
  api_management_name = azurerm_api_management.apim-floto.name
  display_name        = "Floto Consumers"
  resource_group_name = var.resource_group_name
  product_id          = azurerm_api_management_product.apim-prod-floto.id
  allow_tracing       = false
  state               = "active"
  primary_key         = random_uuid.apim-sub-floto-key-p.result
  secondary_key       = random_uuid.apim-sub-floto-key-s.result
}

resource "random_uuid" "apim-sub-floto-key-p" {
}

resource "random_uuid" "apim-sub-floto-key-s" {
}

resource "azurerm_api_management_logger" "apim-floto-logger" {
  name                = "${var.stack}-apim-logger-${var.app_name}"
  api_management_name = azurerm_api_management.apim-floto.name
  resource_group_name = var.resource_group_name
  resource_id         = var.app_insights_id

  application_insights {
    instrumentation_key = var.app_insights_instrumentation_key
  }
}

resource "azurerm_api_management_diagnostic" "apim-floto-diagnostic" {
  identifier               = "applicationinsights"
  resource_group_name      = var.resource_group_name
  api_management_name      = azurerm_api_management.apim-floto.name
  api_management_logger_id = azurerm_api_management_logger.apim-floto-logger.id

  sampling_percentage       = 100.0
  always_log_errors         = true
  log_client_ip             = true
  verbosity                 = "verbose"
  http_correlation_protocol = "W3C"

  frontend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  frontend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }

  backend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
    ]
  }

  backend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
    ]
  }
}

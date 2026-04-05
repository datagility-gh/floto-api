resource "azurerm_app_configuration_key" "confkey-loglevel" {
  configuration_store_id = var.configuration_store_id
  key                    = "Logging:ApplicationInsights:LogLevel:Default"
  value                  = "Warning"
  label                  = var.stack
}

resource "azurerm_app_configuration_feature" "beta" {
  configuration_store_id = var.configuration_store_id
  description            = "All beta features"
  name                   = "Beta"
  enabled                = true
  label                  = var.stack
  tags                   = merge(var.tags, { delete-by = "2027/01/01" })
}

resource "azurerm_app_configuration_feature" "cached_notes" {
  configuration_store_id = var.configuration_store_id
  description            = "Notes read/writes are through a lazy-loaded cache."
  name                   = "CachedNotes"
  enabled                = true
  label                  = var.stack
  tags                   = merge(var.tags, { delete-by = "2026/07/31" })
}

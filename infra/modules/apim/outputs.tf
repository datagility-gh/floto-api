output "apim_url" {
  value       = "${azurerm_api_management.apim-floto.gateway_url}/${azurerm_api_management_api.api-floto-api.path}"
  description = "The Url and relative path of the Floto API."
}

output "floto_api_key_primary" {
  value       = random_uuid.apim-sub-floto-key-p.result
  description = "The primary Subscription Key for the Floto API."
}

output "floto_api_key_secondary" {
  value       = random_uuid.apim-sub-floto-key-s.result
  description = "The secondary Subscription Key for the Floto API."
}

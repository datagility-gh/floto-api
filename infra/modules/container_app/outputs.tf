output "app_url" {
  value       = "https://${azurerm_container_app.ca-floto-api.ingress[0].fqdn}"
  description = "The Application Url of the container app."
}

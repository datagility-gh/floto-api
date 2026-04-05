output "vnet_id" {
  value       = azurerm_virtual_network.floto-vnet.id
  description = "The id of the vnet."
}

output "subnet_id_shared" {
  value       = azurerm_virtual_network.floto-vnet.subnet.*.id[0]
  description = "The id of the shared subnet."
}

output "subnet_id_appenv" {
  value       = azurerm_virtual_network.floto-vnet.subnet.*.id[1]
  description = "The id of the subnet delegated to app environments."
}

output "subnet_id_p_endpoint" {
  value       = azurerm_virtual_network.floto-vnet.subnet.*.id[2]
  description = "The id of the subnet that hosts proviate endpoints."
}

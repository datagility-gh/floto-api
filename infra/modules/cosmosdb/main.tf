resource "azurerm_cosmosdb_sql_database" "sqldb_floto" {
  name                = "${var.stack}-sqldb-floto"
  resource_group_name = var.resource_group_name
  account_name        = var.cosmosdb_account_name
  throughput          = var.throughput
}

resource "azurerm_cosmosdb_sql_container" "sql_container_floto" {
  name                  = "sql-cont-floto"
  resource_group_name   = var.resource_group_name
  account_name          = var.cosmosdb_account_name
  database_name         = azurerm_cosmosdb_sql_database.sqldb_floto.name
  partition_key_paths   = ["/date"]
  partition_key_version = 1
  throughput            = var.throughput

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "floto-private-dns-zone-vnet-link-cosmos" {
  name                  = "${var.stack}-dnsvnet-cosmos"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = var.dnszone_name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "p_endpoint_cosmos" {
  name                = "${var.stack}-p-endpoint-cosmos"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${var.stack}-p-service-cxn-cosmos"
    private_connection_resource_id = var.cosmosdb_account_id
    is_manual_connection           = false
    subresource_names              = ["SQL"]
  }

  # create a DNS zone group that auto-manages DNS records for the private endpoint
  # don't need to explicitly create A records here
  private_dns_zone_group {
    name                 = "${var.stack}-p-endpoint-dns-group-cosmos"
    private_dns_zone_ids = [var.dnszone_id]
  }

  tags = var.tags
}

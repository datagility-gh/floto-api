resource "azurerm_virtual_network" "floto-vnet" {
  name                = "${var.stack}-vnet-${var.app_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name              = "${var.stack}-subnet-${var.app_name}-shared"
    address_prefixes  = ["10.0.0.0/24"]
    security_group    = azurerm_network_security_group.floto-subnet-nsg-shared-services.id
  }

  subnet {
    name             = "${var.stack}-subnet-${var.app_name}-appenv"
    address_prefixes = ["10.0.1.0/24"]
    security_group   = azurerm_network_security_group.floto-subnet-nsg-default.id
    delegation {
      name = "delegation"

      service_delegation {
        name    = "Microsoft.App/environments"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }

  subnet {
    name              = "${var.stack}-subnet-${var.app_name}-p-endpoint"
    address_prefixes  = ["10.0.2.0/24"]
    private_endpoint_network_policies = "Disabled"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      subnet
    ]
  }
}

resource "azurerm_network_security_group" "floto-subnet-nsg-default" {
  name                = "${var.stack}-nsg-${var.app_name}-default"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule = []

  tags = var.tags
}

resource "azurerm_network_security_group" "floto-subnet-nsg-shared-services" {
  name                = "${var.stack}-nsg-${var.app_name}-apim"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-inbound-internet"
    priority                   = 100
    access                     = "Allow"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-inbound-apim"
    priority                   = 200
    access                     = "Allow"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_ranges    = ["3443"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-internet"
    priority                   = 300
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
    source_port_range          = "*"
    destination_port_ranges    = ["80"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-storage"
    priority                   = 400
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
    source_port_range          = "*"
    destination_port_ranges    = ["443"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-aad"
    priority                   = 500
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
    source_port_range          = "*"
    destination_port_ranges    = ["443"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-azconnectors"
    priority                   = 600
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureConnectors"
    source_port_range          = "*"
    destination_port_ranges    = ["443"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-sql"
    priority                   = 700
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Sql"
    source_port_range          = "*"
    destination_port_ranges    = ["1433"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-keyvault"
    priority                   = 800
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureKeyVault"
    source_port_range          = "*"
    destination_port_ranges    = ["443"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-eventhub"
    priority                   = 900
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "EventHub"
    source_port_range          = "*"
    destination_port_ranges    = ["5671", "5672", "443"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-azmonitor"
    priority                   = 1000
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureMonitor"
    source_port_range          = "*"
    destination_port_ranges    = ["1886", "443"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-inbound-redis"
    priority                   = 1100
    access                     = "Allow"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_ranges    = ["6380", "6381", "6382", "6382"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-redis"
    priority                   = 1200
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_ranges    = ["6380", "6381", "6382", "6382"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-inbound-redis-udp"
    priority                   = 1300
    access                     = "Allow"
    direction                  = "Inbound"
    protocol                   = "Udp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_ranges    = ["4290"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-outbound-redis-udp"
    priority                   = 1400
    access                     = "Allow"
    direction                  = "Outbound"
    protocol                   = "Udp"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_ranges    = ["4290"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-inbound-alb"
    priority                   = 1400
    access                     = "Allow"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_ranges    = ["6390", "6391"]
  }

  security_rule {
    name                       = "${var.stack}-nsgsr-${var.app_name}-inbound-atm"
    priority                   = 1500
    access                     = "Allow"
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "AzureTrafficManager"
    destination_address_prefix = "VirtualNetwork"
    source_port_range          = "*"
    destination_port_ranges    = ["443"]
  }

  tags = var.tags
}

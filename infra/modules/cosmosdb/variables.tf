variable "tags" {}

variable "stack" {
  description = "The logical environment."
}

variable "cosmosdb_account_id" {
  description = "The cosmos db account id."
}

variable "cosmosdb_account_name" {
  description = "The cosmos db account name."
}

variable "resource_group_name" {
  description = "The resource group for the module."
}

variable "vnet_id" {
  description = "The id of the vnet into which the Cosmos DB Private Endpoint will be deployed."
}

variable "subnet_id" {
  description = "The id of the subnet into which the Cosmos DB Private Endpoint will be deployed."
}

variable "dnszone_id" {
  description = "The id of the DNS zone associated with the vnet into which the Cosmos DB Private Endpoint will be deployed."
}

variable "dnszone_name" {
  description = "The name of the DNS zone associated with the vnet into which the Cosmos DB Private Endpoint will be deployed."
}

variable "location" {
  description = "The location into which the Cosmos DB Private Endpoint will be deployed."
}

variable "throughput" {
  type        = number
  default     = 400
  description = "Cosmos db database throughput"
  validation {
    condition     = var.throughput >= 400 && var.throughput <= 1000000
    error_message = "Cosmos db manual throughput should be equal to or greater than 400 and less than or equal to 1000000."
  }
  validation {
    condition     = var.throughput % 100 == 0
    error_message = "Cosmos db throughput should be in increments of 100."
  }
}

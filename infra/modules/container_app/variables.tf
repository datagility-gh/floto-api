variable "tags" {}

variable "stack" {
  description = "The logical environment."
}

variable "location" {
  description = "Azure location where the module will be deployed."
}

variable "app_name" {
  description = "The name for the module."
}

variable "resource_group_name" {
  description = "The resource group for the module."
}

variable "vnet_id" {
  description = "The id of the vnet into which the App Environment will be deployed."
}

variable "subnet_id" {
  description = "The id of the subnet into which the App Environment will be deployed."
}

variable "log_analytics_workspace_id" {
  description = "The id of the associated Log Analytics Workspace."
}

variable "acr_id" {
  description = "The id of the asscoiated ACR."
}

variable "acr_login_server" {
  description = "The Login Server of the asscoiated ACR."
}

variable "image_tag" {
  description = "The tag of the application container image."
}

variable "target_port" {
  description = "The port on which the container is listening."
  default = "8080"
}

variable "app_health_path" {
  description = "The app path to be used for health checks."
}

variable "app_config_cxn_string" {
  description = "The connection string to an App Configuration instance."
}

variable "app_insights_cxn_string" {
  description = "The connection string to an App Insights instance."
}

variable "cosmosdb_cxn_string" {
    description = "The connection string to a Cosmos DD account"
}

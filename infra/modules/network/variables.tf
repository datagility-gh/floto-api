variable "tags" {}

variable "stack" {
  description = "The logical environment."
}

variable "location" {
  description = "Azure location where the module will be deployed."
}

variable "resource_group_name" {
  description = "The resource group for the module."
}

variable "app_name" {
  description = "The name of the application that this APIM instance supports."
}

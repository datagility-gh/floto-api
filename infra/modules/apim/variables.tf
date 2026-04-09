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

variable "revision" {
  description = "The version of the API."
}

variable "app_name" {
  description = "The name of the application that this APIM instance supports."
}

variable "display_name" {
  description = "The display name for this APIM instance."
}

variable "company" {
  description = "The company associated with the API Management instance."
}

variable "publisher_email" {
  description = "The email associated with the API Management instance."
}

variable "backend_url" {
  description = "The runtime url to which requests will be sent."
}

variable "backend_suffix" {
  description = "The realtive path to the API."
}

variable "protocol" {
  description = "The protocol used for backend requests."
  default     = "http"
}

variable "openapi_filepath" {
  description = "Path to an OpenAPI definition file for the API."
}

variable "app_insights_id" {
  description = "Id of the Application Insights instance associated with this APIM instance."
}

variable "app_insights_instrumentation_key" {
  description = "Instrumentation Key for the Application Insights instance associated with this APIM instance."
}

variable "subnet_id" {
  description = "The id of the subnet used by this APIM instance."  
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "location" {
  type = string
}

variable "acr_sku" {
  type = string
}

variable "acr_admin_enabled" {
  type = string
}

variable "kv_sku_name" {
  type = string
  description = "The sku name for the Azure Key vault"
  validation {
    condition     = contains(["standard", "premium"], var.kv_sku_name)
    error_message = "The kv_sku_name must be one of the following: standard, premium."
  }
}

variable "GITHUB_APP_ID" {
  description = "inject github app id from env variable"
  type = string
}

variable "GITHUB_APP_INSTALLATION_ID" {
  description = "inject github app installation id from env variable"
  type = string
}

variable "GITHUB_APP_PEM_FILE" {
  description = "inject github app private key file from env variable"
  type = string
}

variable "GITHUB_APP_CLIENTID" {
  description = "inject github app client ID from env variable"
  type = string
}
# Backend for Terraform state file

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraformbackend"{
  name                  = var.resource_group_name
  location              = var.location
}

resource "azurerm_storage_account" "terraform_backend" {
    name                            = var.storage_account_name
    resource_group_name             = azurerm_resource_group.terraformbackend.name
    location                        = azurerm_resource_group.terraformbackend.location
    account_tier                    = var.storage_account_tier
    account_replication_type        = var.storage_account_replication_type
    public_network_access_enabled   = false
    allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "terraform_backend" {
  name                  = var.storage_container_name 
  storage_account_id    = azurerm_storage_account.terraform_backend.id
  container_access_type = var.container_access_type
}
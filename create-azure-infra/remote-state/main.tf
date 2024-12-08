# Backend for Terraform state file

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraformbackend_rg"{
  name                  = var.resource_group_name
  location              = var.location
}

resource "azurerm_storage_account" "terraform_backend_sa" {
    name                            = var.storage_account_name
    resource_group_name             = azurerm_resource_group.terraformbackend.name
    location                        = azurerm_resource_group.terraformbackend.location
    account_tier                    = var.storage_account_tier
    account_replication_type        = var.storage_account_replication_type
}

resource "azurerm_storage_container" "terraform_backend_sc" {
  name                  = var.storage_container_name 
  storage_account_id    = azurerm_storage_account.terraform_backend.id
  container_access_type = var.container_access_type
}

resource "azurerm_role_assignment" "terraform_backend_ra" {
  principal_id         = "<service-principal-object-id>"
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.example.id
}
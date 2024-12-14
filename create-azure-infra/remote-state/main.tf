# Backend for Terraform state file

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "terraformbackend_rg"{
  name                  = var.resource_group_name
  location              = var.location
}

resource "azurerm_storage_account" "terraform_backend_sa" {
    name                            = var.storage_account_name
    resource_group_name             = azurerm_resource_group.terraformbackend_rg.name
    location                        = azurerm_resource_group.terraformbackend_rg.location
    account_tier                    = var.storage_account_tier
    account_replication_type        = var.storage_account_replication_type
}

resource "azurerm_storage_container" "terraform_backend_sc" {
  name                  = var.storage_container_name 
  storage_account_id    = azurerm_storage_account.terraform_backend_sa.id
  storage_account_name = azurerm_storage_account.terraform_backend_sa.name
  container_access_type = var.container_access_type
}

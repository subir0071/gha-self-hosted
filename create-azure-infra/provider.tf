terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.12.0"
    }
  }
  backend "azurerm" {
      resource_group_name  = azurerm_resource_group.gha_runner_rg.name
      storage_account_name = azurerm_storage_account.gha_runner_sa.name
      container_name       = azurerm_storage_container.tfstate_container.name
      key                  = "${var.project}-${var.env}-terraform.tfstate"
  }
}

# Provider Configuration
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "azurerm_storage_container" "tfstate_container" {
  name                  = ""${var.project}-${var.env}-tfstate-container"
  storage_account_id  = azurerm_storage_account.gha_runner_sa.id
  container_access_type = "private"
}


data "azurerm_client_config" "current" {}
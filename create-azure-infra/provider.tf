terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0.0"
    }
  }
  
  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy          = true
      recover_soft_deleted_key_vaults       = false
    }
    resource_group {
       prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_subscription" "current" {}
